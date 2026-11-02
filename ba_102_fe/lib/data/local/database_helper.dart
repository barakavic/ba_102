import 'dart:io';

import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;
import 'package:ba_102_fe/utils/app_logger.dart';
import 'package:ba_102_fe/data/local/database_encryption_service.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static cipher.Database? _database;
  static Future<cipher.Database>? _openingDatabase;
  final DatabaseEncryptionService _encryptionService =
      DatabaseEncryptionService();

  static const int _schemaVersion = 16;
  static const String _confirmationCode = 'BA102-DB-ENC-OK';
  static const List<int> _sqliteHeader = <int>[
    83,
    81,
    76,
    105,
    116,
    101,
    32,
    102,
    111,
    114,
    109,
    97,
    116,
    32,
    51,
    0,
  ];

  DatabaseHelper._init();

  Future<cipher.Database> get database async {
    if (_database != null) return _database!;
    final opening = _openingDatabase;
    if (opening != null) return opening;

    final future = _initDB('budget.db');
    _openingDatabase = future;
    try {
      final db = await future;
      _database = db;
      return db;
    } catch (_) {
      _openingDatabase = null;
      rethrow;
    }
  }

  Future<cipher.Database> _initDB(String filePath) async {
    final dbPath = await cipher.getDatabasesPath();
    final path = join(dbPath, filePath);
    final databaseFile = File(path);
    final tempPath = '$path.encrypted.tmp';
    final plaintextBackupPath = '$path.plaintext.bak';
    String? key;
    try {
      key = await _encryptionService.readKey();
    } catch (_) {
      throw const DatabaseEncryptionException(
        'The secure database key could not be read. Existing data was preserved.',
      );
    }
    await _recoverInterruptedConversion(
      path: path,
      tempPath: tempPath,
      plaintextBackupPath: plaintextBackupPath,
      key: key,
    );
    final databaseExists = await databaseFile.exists();
    final isPlaintext = databaseExists && await _isPlainSqlite(path);

    if (databaseExists && !isPlaintext && key == null) {
      // A non-SQLite header indicates an encrypted (or otherwise non-plaintext)
      // database. Never create a new key and risk replacing the user's data.
      if (await File(plaintextBackupPath).exists()) {
        await File(plaintextBackupPath).delete();
      }
      throw const DatabaseEncryptionException(
        'The encrypted database key is unavailable. The database was preserved.',
      );
    }

    key ??= await _encryptionService.createAndStoreKey();
    final databaseKey = key;

    if (isPlaintext) {
      await _convertPlainDatabase(
        sourcePath: path,
        targetPath: tempPath,
        key: databaseKey,
      );
      // Keep the original until the encrypted copy has passed verification.
      if (await File(plaintextBackupPath).exists()) {
        await File(plaintextBackupPath).delete();
      }
      await databaseFile.copy(plaintextBackupPath);
      await File(tempPath).rename(path);
    }

    cipher.Database? openedDb;
    try {
      openedDb = await _openEncryptedDatabase(path, databaseKey);
      await _verifyEncryptedDatabase(openedDb);
      if (await File(plaintextBackupPath).exists()) {
        await File(plaintextBackupPath).delete();
      }
      if (await File(tempPath).exists()) await File(tempPath).delete();
    } catch (_) {
      await openedDb?.close();
      if (await File(plaintextBackupPath).exists()) {
        await File(plaintextBackupPath).rename(path);
      }
      throw const DatabaseEncryptionException(
        'Could not open or verify the encrypted database. Existing data was preserved.',
      );
    }

    final db = openedDb;
    await _seedData(db);
    return db;
  }

  Future<void> _recoverInterruptedConversion({
    required String path,
    required String tempPath,
    required String plaintextBackupPath,
    required String? key,
  }) async {
    if (await File(path).exists()) return;

    final backup = File(plaintextBackupPath);
    final temp = File(tempPath);
    if (await temp.exists() && key == null && !await backup.exists()) {
      throw const DatabaseEncryptionException(
        'A pending encrypted database was found without its key. The file was preserved.',
      );
    }
    if (await temp.exists() && key != null) {
      cipher.Database? candidate;
      try {
        candidate = await cipher.openDatabase(
          tempPath,
          password: key,
          singleInstance: false,
        );
        await _verifyEncryptedDatabase(candidate);
        await candidate.close();
        candidate = null;
        await _removeDatabaseSidecars(tempPath);
        await temp.rename(path);
        return;
      } catch (_) {
        await candidate?.close();
      }
    }

    if (await backup.exists()) await backup.rename(path);
    if (await temp.exists() && !await File(path).exists()) {
      throw const DatabaseEncryptionException(
        'Database conversion could not be recovered. The encrypted file was preserved.',
      );
    }
  }

  Future<cipher.Database> _openEncryptedDatabase(
    String path,
    String key,
  ) async {
    return cipher.openDatabase(
      path,
      password: key,
      version: _schemaVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<bool> _isPlainSqlite(String path) async {
    final file = File(path);
    if (await file.length() == 0) return true;
    final handle = await file.open();
    try {
      final header = await handle.read(_sqliteHeader.length);
      if (header.length < _sqliteHeader.length) return false;
      for (var i = 0; i < _sqliteHeader.length; i++) {
        if (header[i] != _sqliteHeader[i]) return false;
      }
      return true;
    } finally {
      await handle.close();
    }
  }

  Future<void> _convertPlainDatabase({
    required String sourcePath,
    required String targetPath,
    required String key,
  }) async {
    final targetFile = File(targetPath);
    if (await targetFile.exists()) await targetFile.delete();

    cipher.Database? target;
    try {
      target = await cipher.openDatabase(
        targetPath,
        password: key,
        singleInstance: false,
      );
      final escapedSourcePath = sourcePath.replaceAll("'", "''");
      await target.execute(
        "ATTACH DATABASE '$escapedSourcePath' AS legacy KEY ''",
      );
      await target.rawQuery('PRAGMA legacy.wal_checkpoint(TRUNCATE)');
      await target.rawQuery('PRAGMA legacy.journal_mode = DELETE');
      final legacyVersionResult = await target.rawQuery(
        'PRAGMA legacy.user_version',
      );
      final legacyVersion = legacyVersionResult.isEmpty
          ? 0
          : (legacyVersionResult.first.values.first as num).toInt();
      final legacyTables = await target.rawQuery(
        "SELECT name FROM legacy.sqlite_master "
        "WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      );
      final legacyRowCounts = <String, int>{};
      for (final row in legacyTables) {
        final table = row['name'] as String;
        final quotedTable = table.replaceAll('"', '""');
        final count = await target.rawQuery(
          'SELECT COUNT(*) AS row_count FROM legacy."$quotedTable"',
        );
        legacyRowCounts[table] = (count.first['row_count'] as num).toInt();
      }
      await target.rawQuery("SELECT sqlcipher_export('main', 'legacy')");
      await target.execute('DETACH DATABASE legacy');
      await target.execute('PRAGMA user_version = $legacyVersion');
      for (final entry in legacyRowCounts.entries) {
        final quotedTable = entry.key.replaceAll('"', '""');
        final count = await target.rawQuery(
          'SELECT COUNT(*) AS row_count FROM main."$quotedTable"',
        );
        if ((count.first['row_count'] as num).toInt() != entry.value) {
          throw DatabaseEncryptionException(
            'Database conversion verification failed for ${entry.key}.',
          );
        }
      }
      await _verifyEncryptedDatabase(target);
      await target.close();
      target = null;
      await _removeDatabaseSidecars(sourcePath);
      await _removeDatabaseSidecars(targetPath);
    } catch (error) {
      if (target != null) await target.close();
      if (await targetFile.exists()) await targetFile.delete();
      throw DatabaseEncryptionException(
        'Could not encrypt the existing database. The original was preserved: $error',
      );
    }
  }

  Future<void> _removeDatabaseSidecars(String path) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _verifyEncryptedDatabase(cipher.Database db) async {
    final cipherVersion = await db.rawQuery('PRAGMA cipher_version');
    if (cipherVersion.isEmpty || cipherVersion.first.values.first == null) {
      throw const DatabaseEncryptionException(
        'SQLCipher is unavailable for the local database.',
      );
    }

    final cipherStatus = await db.rawQuery('PRAGMA cipher_status');
    final status = cipherStatus.isEmpty
        ? null
        : cipherStatus.first.values.first;
    if (status != null && (status is! int || status != 1)) {
      throw const DatabaseEncryptionException(
        'The database connection is not confirmed as encrypted.',
      );
    }

    // cipher_status was introduced in SQLCipher 4.12. If an earlier SQLCipher
    // build is bundled, the engine version, keyed schema read, and encrypted
    // file header provide the compatible verification path.
    final schemaCheck = await db.rawQuery(
      'SELECT COUNT(*) AS schema_count FROM sqlite_master',
    );
    if (schemaCheck.isEmpty || await _isPlainSqlite(db.path)) {
      throw const DatabaseEncryptionException(
        'The database connection is not confirmed as encrypted.',
      );
    }

    final integrityErrors = await db.rawQuery('PRAGMA cipher_integrity_check');
    if (integrityErrors.isNotEmpty) {
      throw const DatabaseEncryptionException(
        'The encrypted database integrity check failed.',
      );
    }
  }

  Future<String> getEncryptionConfirmationCode() async {
    final db = await database;
    await _verifyEncryptedDatabase(db);
    return _confirmationCode;
  }

  Future<cipher.Database> _createDB(cipher.Database db, int version) async {
    await db.execute('''

CREATE TABLE budget_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    start_date TEXT,
    end_date TEXT,    
    status TEXT,
    limit_amount REAL DEFAULT 0.0,
    plan_type TEXT DEFAULT 'monthly'
   );
    ''');

    await db.execute('''
CREATE TABLE budget_category (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    limit_amount REAL DEFAULT 0.0,
    icon TEXT,
    color TEXT,
    parent_id INTEGER
    );

''');

    await db.execute('''
CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    category_id INTEGER,
    plan_id INTEGER,
    type TEXT DEFAULT 'outbound',
    vendor TEXT,
    mpesa_reference TEXT UNIQUE,
    balance REAL,
    raw_sms_message TEXT,
    client_id TEXT UNIQUE,
    is_synced INTEGER DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES budget_category(id),
    FOREIGN KEY (plan_id) REFERENCES budget_plans(id)
);
''');

    await db.execute('''
CREATE TABLE vendor_mappings (
    vendor_name TEXT PRIMARY KEY,
    category_id INTEGER,
    FOREIGN KEY (category_id) REFERENCES budget_category(id)
);
''');

    await db.execute('''
CREATE TABLE shopping_lists (
id TEXT PRIMARY KEY,
title TEXT,
color_swatch INTEGER,
budget_limit REAL DEFAULT 0.0,
is_temporary INTEGER DEFAULT 0,
createdAt INTEGER
);

''');

    await db.execute('''
CREATE TABLE shopping_items (
id TEXT PRIMARY KEY,
list_id TEXT NOT NULL,
name TEXT NOT NULL,
category TEXT,
estimated_price REAL DEFAULT 0.0,
quantity INTEGER DEFAULT 1,
is_required INTEGER DEFAULT 0,
is_bought INTEGER DEFAULT 0,
is_permanent INTEGER DEFAULT 1,
brand TEXT,
expiry_date INTEGER,
volume TEXT,
FOREIGN KEY(list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE

);
''');

    await db.execute('''
CREATE TABLE spending_limits (
id INTEGER PRIMARY KEY AUTOINCREMENT,
limit_type TEXT NOT NULL,
amount REAL NOT NULL,
alert_percentage REAL NOT NULL,
specific_days TEXT,
created_at TEXT NOT NULL
);
''');

    await db.execute('''
CREATE TABLE app_preferences (
  preference_key TEXT PRIMARY KEY,
  preference_value TEXT NOT NULL
);
''');

    await _seedData(db);
    return db;
  }

  Future<void> _seedData(cipher.Database db) async {
    final List<String> defaultCategories = [
      'Food',
      'Utilities',
      'Transport',
      'Shopping',
      'Entertainment',
    ];

    for (var name in defaultCategories) {
      final List<Map<String, dynamic>> existing = await db.query(
        'budget_category',
        where: 'name = ?',
        whereArgs: [name],
      );

      if (existing.isEmpty) {
        await db.insert('budget_category', {'name': name, 'limit_amount': 0.0});
      }
    }
  }

  Future<void> _upgradeDB(
    cipher.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 16) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_preferences (
          preference_key TEXT PRIMARY KEY,
          preference_value TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 2) {
      // Version 2 additions (with fixes)
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN type TEXT DEFAULT "outbound"',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN vendor TEXT');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN mpesa_reference TEXT',
        );
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN balance REAL');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN raw_sms_message TEXT',
        );
      } catch (_) {}
    }

    if (oldVersion < 3) {
      // Ensure all columns exist in case version 2 upgrade failed or was partial
      final columns = await db.rawQuery('PRAGMA table_info(transactions)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      if (!columnNames.contains('type')) {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN type TEXT DEFAULT "outbound"',
        );
      }
      if (!columnNames.contains('vendor')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN vendor TEXT');
      }
      if (!columnNames.contains('raw_sms_message')) {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN raw_sms_message TEXT',
        );
      }
      if (!columnNames.contains('mpesa_reference')) {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN mpesa_reference TEXT',
        );
      }
      if (!columnNames.contains('balance')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN balance REAL');
      }
      if (!columnNames.contains('category_id')) {
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN category_id INTEGER',
        );
      }
      if (!columnNames.contains('plan_id')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN plan_id INTEGER');
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS vendor_mappings (
          vendor_name TEXT PRIMARY KEY,
          category_id INTEGER,
          FOREIGN KEY (category_id) REFERENCES budget_category(id)
        )
      ''');
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
          'ALTER TABLE budget_category ADD COLUMN limit_amount REAL DEFAULT 0.0',
        );
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute(
          'ALTER TABLE budget_plans ADD COLUMN limit_amount REAL DEFAULT 0.0',
        );
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute(
          'ALTER TABLE budget_plans ADD COLUMN plan_type TEXT DEFAULT "monthly"',
        );
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE budget_category ADD COLUMN icon TEXT');
        await db.execute('ALTER TABLE budget_category ADD COLUMN color TEXT');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute(
          'ALTER TABLE budget_category ADD COLUMN parent_id INTEGER',
        );
      } catch (_) {}
    }
    if (oldVersion < 10) {
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN client_id TEXT');
        await db.execute(
          'ALTER TABLE transactions ADD COLUMN is_synced INTEGER DEFAULT 0',
        );
        // Generate UUIDs for existing transactions
        final List<Map<String, dynamic>> txs = await db.query('transactions');
        for (var tx in txs) {
          if (tx['client_id'] == null) {
            await db.update(
              'transactions',
              {'client_id': const Uuid().v4()},
              where: 'id = ?',
              whereArgs: [tx['id']],
            );
          }
        }
      } catch (_) {}
    }
    if (oldVersion < 11) {
      try {
        await db.execute('''
CREATE TABLE shopping_lists (
id TEXT PRIMARY KEY,
title TEXT,
color_swatch INTEGER,
is_temporary INTEGER DEFAULT 0,
createdAt INTEGER
);

''');

        await db.execute('''
CREATE TABLE shopping_items (
id TEXT PRIMARY KEY,
list_id TEXT NOT NULL,
name TEXT NOT NULL,
category TEXT,
estimated_price REAL DEFAULT 0.0,
quantity INTEGER DEFAULT 1,
is_required INTEGER DEFAULT 0,
is_bought INTEGER DEFAULT 0,
is_permanent INTEGER DEFAULT 1,
FOREIGN KEY(list_id) REFERENCES shopping_lists(id) ON DELETE CASCADE

);
''');
      } catch (_) {}
    }

    if (oldVersion < 12) {
      try {
        await db.execute('''
CREATE TABLE spending_limits (
id INTEGER PRIMARY KEY AUTOINCREMENT,
limit_type TEXT NOT NULL,
amount REAL NOT NULL,
alert_percentage INTEGER NOT NULL,
specific_days TEXT,
created_at TEXT NOT NULL
);
''');
      } catch (_) {}
    }
    if (oldVersion < 13) {
      await _repairShoppingItemsRequiredColumn(db);
    }
    if (oldVersion < 14) {
      try {
        await db.execute(
          'ALTER TABLE shopping_lists ADD COLUMN budget_limit REAL DEFAULT 0.0',
        );
      } catch (_) {}
    }
    if (oldVersion < 15) {
      try {
        await db.execute('ALTER TABLE shopping_items ADD COLUMN brand TEXT');
        await db.execute(
          'ALTER TABLE shopping_items ADD COLUMN expiry_date INTEGER',
        );
        await db.execute('ALTER TABLE shopping_items ADD COLUMN volume TEXT');
      } catch (_) {}
    }
    AppLogger.i('Database upgraded from $oldVersion to $newVersion');
  }

  Future<void> _repairShoppingItemsRequiredColumn(cipher.Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = ? AND name = ?",
      ['table', 'shopping_items'],
    );
    if (tables.isEmpty) return;

    final columns = await db.rawQuery('PRAGMA table_info(shopping_items)');
    final columnNames = columns
        .map((column) => column['name'] as String)
        .toSet();

    if (!columnNames.contains('is_required')) {
      await db.execute(
        'ALTER TABLE shopping_items ADD COLUMN is_required INTEGER DEFAULT 0',
      );
    }

    if (columnNames.contains('is_requried')) {
      await db.execute(
        'UPDATE shopping_items SET is_required = is_requried '
        'WHERE is_requried IS NOT NULL',
      );
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) return;
    await db.close();
    _database = null;
    _openingDatabase = null;
  }
}
