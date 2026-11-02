import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/data/local/goals_ls.dart';
import 'package:ba_102_fe/utils/app_logger.dart';

class TransactionsLs {
  final Database db;
  TransactionsLs(this.db);

  Future<int> insertTransaction(Transaction transaction) async {
    try {
      if (transaction.mpesaReference != null) {
        final existing = await db.query(
          'transactions',
          where: 'mpesa_reference = ?',
          whereArgs: [transaction.mpesaReference],
        );

        if (existing.isNotEmpty) {
          AppLogger.w(
            'Duplicate m-pesa transaction: ${transaction.mpesaReference}',
          );
          return existing.first['id'] as int;
        }
      }

      final id = await db.insert(
        'transactions',
        transaction.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (transaction.date != null) {
        await GoalsLs(
          db,
        ).reconcileTransactionAssignments(affectedDates: [transaction.date!]);
      }

      return id;
    } catch (e) {
      AppLogger.e('insertTransaction Error: $e');
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactions({
    int limit = 50,
    int offset = 0,
  }) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  Future<List<Transaction>> getAllTransactions() async {
    final rows = await db.query('transactions', orderBy: 'date DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  Future<List<Transaction>> getTransactionsByMonth(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final rows = await db.rawQuery(
      '''
      SELECT * FROM transactions
      WHERE date(substr(date, 1, 10)) >= ?
        AND date(substr(date, 1, 10)) < ?
      ORDER BY date DESC
      ''',
      [_sqlDate(start), _sqlDate(end)],
    );

    return rows.map(Transaction.fromMap).toList();
  }

  Future<List<Transaction>> getTransactionsByCategory(int categoryId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<List<Transaction>> getTransactionsByPlan(int planId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<List<Transaction>> getTransactionByType(String type) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<List<Transaction>> getUncategorizedTransaction() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'mpesa_reference IS NOT NULL AND category_id IS NULL',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return Transaction.fromMap(maps[i]);
    });
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final oldRows = await db.query(
      'transactions',
      columns: ['date'],
      where: 'id = ?',
      whereArgs: [transaction.id],
      limit: 1,
    );
    final updated = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    final affectedDates = <DateTime>[
      if (oldRows.isNotEmpty && oldRows.first['date'] != null)
        DateTime.parse(oldRows.first['date'] as String),
      if (transaction.date != null) transaction.date!,
    ];
    if (affectedDates.isNotEmpty) {
      await GoalsLs(
        db,
      ).reconcileTransactionAssignments(affectedDates: affectedDates);
    }
    return updated;
  }

  Future<double> getTtlSpendPerPlan(int planId) async {
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total
      FROM transactions
      WHERE plan_id = ? AND TYPE = 'outbound'

  '''[planId],
    );

    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<int> deleteTransaction(int id) async {
    final rows = await db.query(
      'transactions',
      columns: ['date'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final deleted = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isNotEmpty && rows.first['date'] != null) {
      await GoalsLs(db).reconcileTransactionAssignments(
        affectedDates: [DateTime.parse(rows.first['date'] as String)],
      );
    }
    return deleted;
  }

  Future<double> getTtlIncomePerPlan(int planId) async {
    final result = await db.rawQuery(
      '''
    SELECT SUM(amount) AS total
    FROM transactions
    WHERE plan_id = ? AND type = 'inbound' 
    ''',
      [planId],
    );

    return (result.first['total'] as double?) ?? 0.0;
  }

  Future<void> deleteAllTransactions() async {
    await db.delete('transactions');
  }

  Future<double?> getLatestMpesaBalance() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      columns: ['balance'],
      where: 'balance IS NOT NULL AND balance > 0',
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['balance'] as double?;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getMpesaBalanceHistory({
    int limit = 30,
  }) async {
    return await db.query(
      'transactions',
      columns: ['date', 'balance'],
      where: 'balance IS NOT NULL AND balance > 0',
      orderBy: 'date ASC', // ASC for chart plotting
      limit: limit,
    );
  }

  Future<List<Transaction>> getUnsyncedTransactions() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'is_synced = 0',
      orderBy: 'date ASC',
    );
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  Future<DateTime?> getlastTransactionDate() async {
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        columns: ['date'],
        where: 'date IS NOT NULL',
        orderBy: 'date DESC',
        limit: 1,
      );

      if (maps.isNotEmpty) {
        final rawDate = maps.first['date'];
        if (rawDate is String) {
          return DateTime.parse(rawDate);
        }
      }
      return null;
    } catch (e, st) {
      AppLogger.e('getlastTransactionDate failed', error: e, stackTrace: st);
      return null;
    }
  }
}

String _sqlDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
