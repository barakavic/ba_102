import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;

import '../models/models.dart';

class GoalsLs {
  final Database db;
  GoalsLs(this.db);

  Future<List<Goal>> getGoals() async {
    await reconcileTransactionAssignments();
    final rows = await db.query('goals', orderBy: 'created_at DESC, id DESC');
    final goals = <Goal>[];
    for (final row in rows) {
      final goal = Goal.fromMap(row);
      goals.add(goal.copyWith(currentAmount: await getSavedAmount(goal.id!)));
    }
    return goals;
  }

  Future<int> saveGoal(Goal goal) async {
    final values = goal.toMap()..remove('current_amount');
    int id;
    if (goal.id == null) {
      values.remove('id');
      values['created_at'] = DateTime.now().toIso8601String();
      id = await db.insert('goals', values);
    } else {
      id = goal.id!;
      values.remove('id');
      values.remove('created_at');
      await db.update('goals', values, where: 'id = ?', whereArgs: [id]);
    }
    await reconcileTransactionAssignments();
    return id;
  }

  Future<void> deleteGoal(int id) async {
    await db.transaction((txn) async {
      await txn.update(
        'transactions',
        {'goal_id': null, 'goal_assignment_source': null},
        where: 'goal_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'goal_contributions',
        where: 'goal_id = ?',
        whereArgs: [id],
      );
      await txn.delete('goals', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> saveManualContribution({
    int? id,
    required int goalId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final row = {
      'goal_id': goalId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (id == null) return db.insert('goal_contributions', row);
    await db.update(
      'goal_contributions',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  Future<void> deleteManualContribution(int id) async =>
      db.delete('goal_contributions', where: 'id = ?', whereArgs: [id]);

  Future<List<Map<String, dynamic>>> getManualContributions(int goalId) =>
      db.query(
        'goal_contributions',
        where: 'goal_id = ?',
        whereArgs: [goalId],
        orderBy: 'date DESC, id DESC',
      );

  Future<List<Map<String, dynamic>>> getContributionTimeline(int goalId) async {
    final manual = await db.query(
      'goal_contributions',
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );
    final automatic = await db.rawQuery(
      '''
      SELECT t.* FROM transactions t JOIN goals g ON g.id = t.goal_id
      WHERE t.goal_id = ? AND t.type IN ('outbound', 'inbound')
        AND instr(lower(COALESCE(t.vendor, '')), lower(COALESCE(g.account_name, ''))) > 0
        AND julianday(t.date) >= julianday(g.created_at)
    ''',
      [goalId],
    );
    return [
      ...manual.map((row) => {...row, 'source': 'manual'}),
      ...automatic.map(
        (row) => {
          'id': row['id'],
          'date': row['date'],
          'amount': row['type'] == 'inbound'
              ? -(row['amount'] as num).toDouble()
              : row['amount'],
          'note': row['vendor'],
          'source': 'sms',
        },
      ),
    ];
  }

  Future<List<Transaction>> getMatchingTransactionsSinceInception(
    int goalId,
  ) async {
    final goalRows = await db.query(
      'goals',
      where: 'id = ?',
      whereArgs: [goalId],
      limit: 1,
    );
    if (goalRows.isEmpty) return [];
    final goal = Goal.fromMap(goalRows.first);
    final accountName = goal.accountName?.trim();
    if (accountName == null || accountName.isEmpty) return [];
    final rows = await db.rawQuery(
      '''
      SELECT t.* FROM transactions t JOIN goals g ON g.id = ?
      WHERE t.type IN ('outbound', 'inbound')
        AND instr(lower(COALESCE(t.vendor, '')), lower(?)) > 0
        AND julianday(t.date) >= julianday(g.created_at)
      ORDER BY t.date DESC
    ''',
      [goalId, accountName],
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<void> assignTransaction(int transactionId, int goalId) async {
    final rows = await db.query(
      'transactions',
      columns: ['date'],
      where: 'id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    await db.update(
      'transactions',
      {'goal_id': goalId, 'goal_assignment_source': 'manual'},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
    if (rows.isNotEmpty && rows.first['date'] != null) {
      await reconcileTransactionAssignments(
        affectedDates: [DateTime.parse(rows.first['date'] as String)],
      );
    }
  }

  Future<double> getSavedAmount(int goalId) async {
    final manual = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM goal_contributions WHERE goal_id = ?',
      [goalId],
    );
    final automatic = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(CASE WHEN t.type = 'outbound' THEN t.amount WHEN t.type = 'inbound' THEN -t.amount ELSE 0 END), 0) AS total
      FROM transactions t JOIN goals g ON g.id = t.goal_id
      WHERE t.goal_id = ? AND t.type IN ('outbound', 'inbound')
        AND instr(lower(COALESCE(t.vendor, '')), lower(COALESCE(g.account_name, ''))) > 0
        AND julianday(t.date) >= julianday(g.created_at)
    ''',
      [goalId],
    );
    return (manual.first['total'] as num).toDouble() +
        (automatic.first['total'] as num).toDouble();
  }

  Future<void> reconcileTransactionAssignments({
    List<DateTime>? affectedDates,
  }) async {
    final dayKeys = affectedDates?.map(_dateKey).toSet().toList();
    final dateFilter = dayKeys == null || dayKeys.isEmpty
        ? ''
        : ' AND date(substr(date, 1, 10)) IN (${List.filled(dayKeys.length, '?').join(',')})';
    final dateArgs = dayKeys ?? const <String>[];
    final accounts = await db.query(
      'goals',
      columns: [
        'id',
        'account_name',
        'created_at',
        'schedule_type',
        'saving_days',
        'contributions_per_week',
      ],
      where: "account_name IS NOT NULL AND trim(account_name) != ''",
    );
    final autoAssigned = await db.query(
      'transactions',
      columns: ['id'],
      where: 'goal_assignment_source = ?$dateFilter',
      whereArgs: ['automatic', ...dateArgs],
    );
    for (final row in autoAssigned) {
      await db.update(
        'transactions',
        {'goal_id': null, 'goal_assignment_source': null},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    if (accounts.isEmpty) return;

    final transactions = (await db.query(
      'transactions',
      where:
          "type IN ('outbound', 'inbound') AND vendor IS NOT NULL$dateFilter",
      whereArgs: dateArgs,
      orderBy: 'date ASC',
    )).map(Transaction.fromMap).toList();
    final manuallyOccupiedOutboundDays = <String>{};

    for (final tx in transactions.where(
      (tx) => tx.goalId != null && tx.goalAssignmentSource != 'automatic',
    )) {
      if (tx.type != 'outbound' || tx.date == null) continue;
      final goal = accounts.where((account) => account['id'] == tx.goalId);
      if (goal.length != 1) continue;
      final account = goal.single;
      if (!_matchesAccount(tx, account) || !_isAfterInception(tx, account)) {
        continue;
      }
      if (_isScheduled(tx, account)) {
        manuallyOccupiedOutboundDays.add(
          _goalDayKey(account['id'] as int, tx.date!),
        );
      }
    }

    final outboundCandidates =
        <String, List<({Transaction tx, Map<String, Object?> goal})>>{};
    for (final tx in transactions.where((tx) => tx.goalId == null)) {
      if (tx.date == null) continue;
      final matchingGoals = accounts
          .where(
            (account) =>
                _matchesAccount(tx, account) && _isAfterInception(tx, account),
          )
          .toList();
      if (matchingGoals.length != 1) continue;
      final goal = matchingGoals.single;
      if (tx.type == 'inbound') {
        await db.update(
          'transactions',
          {'goal_id': goal['id'], 'goal_assignment_source': 'automatic'},
          where: 'id = ? AND goal_id IS NULL',
          whereArgs: [tx.id],
        );
      } else if (tx.type == 'outbound' && _isScheduled(tx, goal)) {
        final key = _goalDayKey(goal['id'] as int, tx.date!);
        outboundCandidates.putIfAbsent(key, () => []).add((tx: tx, goal: goal));
      }
    }

    for (final entry in outboundCandidates.entries) {
      if (entry.value.length != 1 ||
          manuallyOccupiedOutboundDays.contains(entry.key)) {
        continue;
      }
      final candidate = entry.value.single;
      await db.update(
        'transactions',
        {
          'goal_id': candidate.goal['id'],
          'goal_assignment_source': 'automatic',
        },
        where: 'id = ? AND goal_id IS NULL',
        whereArgs: [candidate.tx.id],
      );
    }
  }

  bool _matchesAccount(Transaction tx, Map<String, Object?> goal) {
    final name = (goal['account_name'] as String? ?? '').trim().toLowerCase();
    final vendor = (tx.vendor ?? '').toLowerCase();
    return name.isNotEmpty && vendor.contains(name);
  }

  bool _isAfterInception(Transaction tx, Map<String, Object?> goal) {
    final date = tx.date;
    final createdAt = goal['created_at'] as String?;
    if (date == null || createdAt == null) return false;
    return !date.isBefore(DateTime.parse(createdAt));
  }

  bool _isScheduled(Transaction tx, Map<String, Object?> goal) {
    final date = tx.date;
    if (date == null) return false;
    final schedule = goal['schedule_type'] as String? ?? 'weekly';
    if (schedule == 'daily') return true;
    final days = (goal['saving_days'] as String? ?? '')
        .split(',')
        .where((value) => value.isNotEmpty)
        .map(int.parse)
        .toSet();
    final count = (goal['contributions_per_week'] as num?)?.toInt() ?? 3;
    return days.isEmpty ? date.weekday <= count : days.contains(date.weekday);
  }

  String _goalDayKey(int goalId, DateTime date) =>
      '$goalId:${date.year}-${date.month}-${date.day}';

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<int> unassignTransaction(int transactionId) async {
    return db.update(
      'transactions',
      {'goal_id': null, 'goal_assignment_source': null},
      where: 'id = ? AND goal_assignment_source = ?',
      whereArgs: [transactionId, 'manual'],
    );
  }
}
