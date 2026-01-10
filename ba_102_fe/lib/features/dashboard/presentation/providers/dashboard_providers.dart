import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';

final privacyModeProvider = StateProvider<bool>((ref) => false);

final mpesaBalanceProvider = FutureProvider<double>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  final balance = await transactionsLs.getLatestMpesaBalance();
  return balance ?? 0.0;
});

final mpesaBalanceHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  return await transactionsLs.getMpesaBalanceHistory();
});

final recentTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  final allTransactions = await transactionsLs.getTransactions();
  return allTransactions.take(20).toList();
});

final dashboardPeriodProvider = StateProvider<String>((ref) => 'Month'); // Week, Month, Year

final periodSummaryProvider = FutureProvider<Map<String, double>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  final allTransactions = await transactionsLs.getTransactions();
  final period = ref.watch(dashboardPeriodProvider);
  
  final now = DateTime.now();
  final filteredTransactions = allTransactions.where((t) {
    if (t.date == null) return false;
    final date = t.date!;
    
    if (period == 'Week') {
      // Find the start of the week (Monday)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfNextWeek = startOfWeek.add(const Duration(days: 7));
      // Reset times to midnight for accurate comparison
      final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
      final end = DateTime(startOfNextWeek.year, startOfNextWeek.month, startOfNextWeek.day);
      return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end);
    } else if (period == 'Year') {
      return date.year == now.year;
    } else {
      // Default to Month
      return date.year == now.year && date.month == now.month;
    }
  });

  double totalSpent = 0;
  double totalIncome = 0;

  for (var t in filteredTransactions) {
    if (t.type == 'outbound' || t.type == 'withdrawal') {
      totalSpent += t.amount ?? 0;
    } else if (t.type == 'inbound' || t.type == 'deposit') {
      totalIncome += t.amount ?? 0;
    }
  }

  return {
    'spent': totalSpent,
    'income': totalIncome,
  };
});

final topCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  final allTransactions = await transactionsLs.getTransactions();
  
  final now = DateTime.now();
  final currentMonthTransactions = allTransactions.where((t) {
    if (t.date == null) return false;
    return t.date!.year == now.year && t.date!.month == now.month && 
           (t.type == 'outbound' || t.type == 'withdrawal');
  });

  final Map<int, double> categoryTotals = {};
  for (var t in currentMonthTransactions) {
    final catId = t.categoryId ?? -1; // -1 for Uncategorized
    categoryTotals[catId] = (categoryTotals[catId] ?? 0) + (t.amount ?? 0);
  }

  // We need category names. This is a bit tricky without a Category Repo handy in this file.
  // We can fetch all categories or just rely on IDs if we had a way to look them up.
  // For now, let's do a raw query to get category names joined, or fetch categories separately.
  // Simplest: Fetch all categories.
  final List<Map<String, dynamic>> catMaps = await db.query('budget_category');
  final Map<int, String> categoryNames = {
    for (var m in catMaps) m['id'] as int: m['name'] as String
  };
  categoryNames[-1] = 'Uncategorized';
  final Map<int, String> categoryIcons = {
    for (var m in catMaps) m['id'] as int: m['icon'] as String? ?? ''
  };

  final List<Map<String, dynamic>> result = [];
  categoryTotals.forEach((id, amount) {
    result.add({
      'name': categoryNames[id] ?? 'Unknown',
      'amount': amount,
      'icon': categoryIcons[id],
    });
  });

  result.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
  return result.take(5).toList();
});
