// import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// import 'package:csv/csv.dart';
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async{
    if (_database != null) return _database!;

    _database = await _initDB('budget.db');
    return _database!;
  }

  Future <Database> _initDB(String filePath) async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);


    final db = await openDatabase(
      path,
      version: 3,
      
    

    onConfigure: (db) async{
      await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      );

    return db;
  }


  Future<Database> _createDB(Database db, int version) async{
    await db.execute('''

CREATE TABLE budget_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    start_date TEXT,
    end_date TEXT,    
    status TEXT
   );
    '''
);

 await db.execute('''
CREATE TABLE budget_category (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
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
    FOREIGN KEY (category_id) REFERENCES budget_category(id),
    FOREIGN KEY (plan_id) REFERENCES budget_plans(id)
);
''');

/* await _importCSV(db, 'assets/test_files/BudgetPlan.csv', 'budget_plans');
await _importCSV(db, 'assets/test_files/BudgetCategory.csv', 'budget_category');
await _importCSV(db, 'assets/test_files/transaction.csv', 'transactions'); */
return db;
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async{
    if (oldVersion < 2){
      // Version 2 additions (with fixes)
      try { await db.execute('ALTER TABLE transactions ADD COLUMN type TEXT DEFAULT "outbound"'); } catch(_) {}
      try { await db.execute('ALTER TABLE transactions ADD COLUMN vendor TEXT'); } catch(_) {}
      try { await db.execute('ALTER TABLE transactions ADD COLUMN mpesa_reference TEXT'); } catch(_) {}
      try { await db.execute('ALTER TABLE transactions ADD COLUMN balance REAL'); } catch(_) {}
      try { await db.execute('ALTER TABLE transactions ADD COLUMN raw_sms_message TEXT'); } catch(_) {}
    }
    
    if (oldVersion < 3) {
      // Ensure all columns exist in case version 2 upgrade failed or was partial
      final columns = await db.rawQuery('PRAGMA table_info(transactions)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();
      
      if (!columnNames.contains('type')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN type TEXT DEFAULT "outbound"');
      }
      if (!columnNames.contains('vendor')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN vendor TEXT');
      }
      if (!columnNames.contains('raw_sms_message')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN raw_sms_message TEXT');
      }
      if (!columnNames.contains('mpesa_reference')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN mpesa_reference TEXT');
      }
      if (!columnNames.contains('balance')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN balance REAL');
      }
    }
    print('Database upgraded from $oldVersion to $newVersion');
  }


  /* Future<void> _importCSV(Database db, String assetPath, String tableName) async{
    final rawData = await rootBundle.loadString(assetPath);
    final csvTable = const CsvToListConverter().convert(rawData, eol:'\n');

  // Imports data fromthe csv skipping the header row
  for(int i = 1; i<csvTable.length; i++){
    final row = csvTable[i];
    final values = <String, dynamic>{};

    switch(tableName){
      case 'budget_plans':
      values.addAll({
        'id': row[0],
        'name': row[1],
        'start_date': row[2],
        'end_date': row[3],
        'status': row[5]
      });
      break;
      case 'budget_category':
      values.addAll({
        'id': row[0],
        'name': row[1],
        'limit_amount': row[2],
        'spent_amount': row[3],
        'status': row[4],
        'plan_id': row[5]
      });
      break;

      case 'transactions':
      values.addAll({
        'id': row[0],
        'description': row[1],
        'amount': row[2],
        'date': row[3],
        'category_id': row[4],
        'plan_id':row[5]
      });
      break;

    }

    await db.insert(tableName, values);
  }
 */

Future <void> close() async {
  final db = await instance.database;
  db.close();
}
  }




