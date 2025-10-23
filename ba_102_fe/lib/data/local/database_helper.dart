import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:csv/csv.dart';
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
    status TEXT,
    is_synced INTEGER DEFAULT 1,
    last_modified TEXT
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

await _importCSV(db, 'assets/test_files/BudgetPlan.csv', 'budget_plans');
await _importCSV(db, 'assets/test_files/BudgetCategory.csv', 'budget_category');
await _importCSV(db, 'assets/test_files/transaction.csv', 'transactions');
return db;
  }


  Future<void> _importCSV(Database db, String assetPath, String tableName) async{
    final rawData = await rootBundle.loadString(assetPath);
    final csvTable = const CsvToListConverter().convert(rawData, eol:'\n');

  // Imports data fromthe csv skipping the header row
  for(int i = 1; i<csvTable.length; i++){
    final row = csvTable[i];
    final values = <String, dynamic>{};

    switch(tableName){
      case 'budget_plans':
      values.addAll({
        'name': row[1],
        'start_date': row[2],
        'end_date': row[3],
        'total_amount': row[4],
        'status': row[5]
      });
      break;
      case 'budget_category':
      values.addAll({
        'name': row[1],
        'limit_amount': row[2],
        'spent_amount': row[3],
        'status': row[4],
        'plan_id': row[5]
      });
      break;

      case 'transactions':
      values.addAll({
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

  }
}



