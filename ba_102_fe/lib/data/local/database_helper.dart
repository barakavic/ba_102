import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
      onCreate: _createDB,
    );

    await db.execute('PRAGMA foreign_keys = ON;');

    return db;
  }

  Future<Database> _createDB(Database db, int version) async{
    await db.execute('''

CREATE TABLE budget_plans (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    start_date TEXT,
    end_date TEXT,
    total_amount REAL,
    status TEXT
    )
    '''
);

 await db.execute('''
CREATE TABLE budget_category (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    limit_amount REAL,
    spent_amount REAL,
    status TEXT,
    plan_id INTEGER,
    FOREIGN KEY (plan_id) REFERENCES budget_plans(id)
)

''');

await db.execute('''
CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    description TEXT,
    amount REAL,
    date TEXT,
    category_id INTEGER,
    plan_id INTEGER,
    FOREIGN KEY (category_id) REFERENCES budget_category(id),
    FOREIGN KEY (plan_id) REFERENCES budget_plans(id)
)
''');
return db;
  }
}



