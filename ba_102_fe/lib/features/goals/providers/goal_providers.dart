import 'package:ba_102_fe/data/api/goal_service.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/goals_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;

final goalServiceProvider = Provider((ref) => GoalService());
final goalsProvider = AsyncNotifierProvider<GoalsNotifier, List<Goal>>(
  GoalsNotifier.new,
);

final latestSavingsGoalProvider = FutureProvider.autoDispose<Goal?>((
  ref,
) async {
  final db = await DatabaseHelper.instance.database;
  final rows = await db.query(
    'goals',
    where: 'kind != ?',
    whereArgs: ['spending_budget'],
    orderBy: 'created_at DESC, id DESC',
    limit: 1,
  );
  if (rows.isEmpty) return null;
  final goal = Goal.fromMap(rows.first);
  if (goal.id == null) return goal;
  final currentAmount = await GoalsLs(db).getSavedAmount(goal.id!);
  return goal.copyWith(currentAmount: currentAmount);
});

class GoalsNotifier extends AsyncNotifier<List<Goal>> {
  @override
  Future<List<Goal>> build() async {
    final db = await DatabaseHelper.instance.database;
    await _importRemoteGoalsOnce(db);
    final service = GoalsLs(db);
    return service.getGoals();
  }

  Future<void> _importRemoteGoalsOnce(dynamic db) async {
    const key = 'legacy_remote_goals_imported_v1';
    final marker = await db.query(
      'app_preferences',
      where: 'preference_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (marker.isNotEmpty) return;
    try {
      final remoteGoals = await ref.read(goalServiceProvider).fetchGoals();
      await db.transaction((txn) async {
        for (final remote in remoteGoals) {
          if (remote.legacyGoalId == null) continue;
          final values = remote.toMap()
            ..remove('id')
            ..remove('current_amount');
          values['legacy_goal_id'] = remote.legacyGoalId;
          values['created_at'] = DateTime.now().toIso8601String();
          final id = await txn.insert(
            'goals',
            values,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          if (id > 0 && remote.currentAmount > 0) {
            await txn.insert('goal_contributions', {
              'goal_id': id,
              'amount': remote.currentAmount,
              'date': DateTime.now().toIso8601String(),
              'note': 'Imported saved progress',
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
        await txn.insert('app_preferences', {
          'preference_key': key,
          'preference_value': '1',
        });
      });
    } catch (_) {
      // Local goals remain available offline. The import is retried next time.
    }
  }

  Future<void> saveGoal(Goal goal) async {
    final db = await DatabaseHelper.instance.database;
    await GoalsLs(db).saveGoal(goal);
    await refresh();
  }

  Future<void> deleteGoal(int id) async {
    final db = await DatabaseHelper.instance.database;
    await GoalsLs(db).deleteGoal(id);
    await refresh();
  }

  Future<void> saveContribution({
    int? id,
    required int goalId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await GoalsLs(db).saveManualContribution(
      id: id,
      goalId: goalId,
      amount: amount,
      date: date,
      note: note,
    );
    await refresh();
  }

  Future<void> deleteContribution(int id) async {
    final db = await DatabaseHelper.instance.database;
    await GoalsLs(db).deleteManualContribution(id);
    await refresh();
  }

  Future<void> assignTransaction(int transactionId, int goalId) async {
    final db = await DatabaseHelper.instance.database;
    await GoalsLs(db).assignTransaction(transactionId, goalId);
    await refresh();
  }

  Future<void> refresh() async {
    final db = await DatabaseHelper.instance.database;
    await _importRemoteGoalsOnce(db);
    final service = GoalsLs(db);
    state = AsyncData(await service.getGoals());
    ref.invalidate(latestSavingsGoalProvider);
  }
}
