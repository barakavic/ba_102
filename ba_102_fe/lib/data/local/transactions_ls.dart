import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:ba_102_fe/data/models/models.dart';

class TransactionsLs {

  final Database db;
  TransactionsLs(this.db);

  Future<List<Transaction>> getTransactions()async{
    final List<Map<String, dynamic>> maps = await db.query('transactions');

    return maps.map((map) => Transaction.fromMap(map)).toList();

  }

  Future<void> insertTransaction(Transaction transaction) async{
    await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

  }

  Future<void> deleteAllTransactions() async{
    await db.delete('transactions');
  }
}