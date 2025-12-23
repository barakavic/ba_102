import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:ba_102_fe/data/models/models.dart';

class TransactionsLs {

  final Database db;
  TransactionsLs(this.db);

   Future<int> insertTransaction(Transaction transaction) async{
    try{
      if(transaction.mpesaReference !=null){
        final existing = await db.query(
          'transactions',
          where: 'mpesa_reference = ?',
          whereArgs: [transaction.mpesaReference],
        );

        if(existing.isNotEmpty){
          print('Duplicate m-pesa transaction: ${transaction.mpesaReference}');
          return existing.first['id'] as int;
        }
      }

    print('insertTransaction: Attempting to insert ${transaction.mpesaReference}');
    final id = await db.insert(
    'transactions', 
    transaction.toMap(), 
    conflictAlgorithm: ConflictAlgorithm.replace
    );

    print('insertTransaction: Success with id: $id');
    return id;
    }
    catch(e, stack){
      print('insertTransaction: Error: $e');
      print('insertTransaction: Stack: $stack');
      rethrow;
    }
 }


  Future<List<Transaction>> getTransactions()async{
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      );

    return List.generate(maps.length, (i){
      return Transaction.fromMap((maps[i]));
    });
  }

  Future<List<Transaction>> getTransactionsByCategory(int categoryId) async{
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i){
      return Transaction.fromMap(maps[i]);
    });
  } 

  Future<List<Transaction>> getTransactionsByPlan(int planId) async{
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'date DESC'
    );
    return List.generate(maps.length, (i){
      return Transaction.fromMap(maps[i]);
    });

  }

  Future<List<Transaction>> getTransactionByType(String type) async{
    final List<Map<String, dynamic>> maps= await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i){
      return Transaction.fromMap(maps[i]);
    });

    

  }

  Future<List<Transaction>> getUncategorizedTransaction() async{
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'mpesa_reference IS NOT NULL AND category_id IS NULL',
      orderBy: 'date DESC',

    );
    return List.generate(maps.length, (i){
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<int> updateTransaction(Transaction transaction) async{
    return await db.update(
      'transactions', 
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id]);
  }
  
  Future<double> getTtlSpendPerPlan(int planId) async{
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE plan_id = ? AND TYPE = 'outbound'

  ''' [planId]);

  return (result.first['total'] as double?) ?? 0.0;
  }
  
  Future<int> deleteTransaction(int id) async{
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<double> getTtlIncomePerPlan(int planId) async{
    final result = await db.rawQuery(
      '''
    SELECT SUM(amount) AS total
    FROM transactions
    WHERE plan_id = ? AND type = 'inbound' 
    ''',
    [planId]
    );


    return (result.first['total'] as double?) ?? 0.0;
  }


  Future<void> deleteAllTransactions() async{
    await db.delete('transactions');
  }
}