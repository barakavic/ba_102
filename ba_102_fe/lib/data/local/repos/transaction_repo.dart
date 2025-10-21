import 'package:ba_102_fe/data/local/database_helper.dart';

class TransactionRepo {

  final dbHelper = DatabaseHelper.instance;

  Future<int> insertTransaction(Map<String, dynamic> tx) async{
    final db = await dbHelper.database;
    return await db.insert('transactions', tx);
  }

  Future<List<Map<String, dynamic>>> getTransactions(int id) async {
    final db = await dbHelper.database;
    return await db.query('transactions');

  }

  Future<int> updateTransaction(Map<String, dynamic> tx) async{
    final db =  await dbHelper.database;
    
    return await db.update('transactions', 
    tx,
    where: 'id = ?',
    whereArgs: [tx['id']],
    );
  }
    Future<int> deleteTransaction(int id) async{
      final db = await dbHelper.database;
      return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
    
  }
}