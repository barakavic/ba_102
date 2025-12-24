import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deletePlanProvider = Provider((ref) {
  return (int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('budget_plans', where: 'id = ?', whereArgs: [id]);
    ref.refresh(plansProvider);
  };
});

final planTransactionsProvider = FutureProvider.family<List<Transaction>, Plan>((ref, plan) async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'transactions',
    where: 'date >= ? AND date <= ?',
    whereArgs: [plan.startDate.toIso8601String(), plan.endDate.toIso8601String()],
    orderBy: 'amount DESC',
  );
  return maps.map((m) => Transaction.fromMap(m)).toList();
});

final planCategoriesProvider = FutureProvider<Map<int, Category>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query('budget_category');
  final Map<int, Category> categories = {
    for (var m in maps) m['id'] as int: Category.fromMap(m)
  };
  categories[-1] = Category(id: -1, name: 'Uncategorized', transactions: []);
  return categories;
});
