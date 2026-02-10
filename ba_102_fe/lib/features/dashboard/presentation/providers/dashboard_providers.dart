import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';

enum BarChartPeriod { daily, weekly, yearly }

class SpendingBarBucket {
  final DateTime bucketStart;
  final String label;
  final double total;

  const SpendingBarBucket({
    required this.bucketStart,
    required this.label,
    required this.total,
  });
}

final privacyModeProvider = StateProvider<bool>((ref) => false);

final mpesaBalanceProvider = FutureProvider<double>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  final balance = await transactionsLs.getLatestMpesaBalance();
  return balance ?? 0.0;
});

final mpesaBalanceHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  return await transactionsLs.getMpesaBalanceHistory();
});

final recentTransactionsProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  final allTransactions = await transactionsLs.getTransactions();
  return allTransactions.take(20).toList();
});

final dashboardPeriodProvider = StateProvider<String>(
  (ref) => 'Month',
); // Week, Month, Year
final barChartPeriodProvider = StateProvider<BarChartPeriod>(
  (ref) => BarChartPeriod.daily,
);

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
      final start = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final end = DateTime(
        startOfNextWeek.year,
        startOfNextWeek.month,
        startOfNextWeek.day,
      );
      return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          date.isBefore(end);
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

  return {'spent': totalSpent, 'income': totalIncome};
});

final spendingBarDataProvider = FutureProvider<List<SpendingBarBucket>>((
  ref,
) async {
  final db = await DatabaseHelper.instance.database;
  final period = ref.watch(barChartPeriodProvider);
  final now = DateTime.now();

  if (period == BarChartPeriod.daily) {
    final rows = await db.rawQuery('''
      SELECT 
        date(substr(date, 1, 10)) AS bucket,
        SUM(amount) AS total
      FROM transactions
      WHERE type IN ('outbound', 'withdrawal')
        AND date(substr(date, 1, 10)) >= date('now', '-6 days')
      GROUP BY bucket
      ORDER BY bucket ASC
    ''');

    final totalsByDay = <String, double>{};
    for (final row in rows) {
      final bucket = row['bucket'] as String?;
      if (bucket == null) continue;
      totalsByDay[bucket] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }

    return List.generate(7, (index) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - index));
      final key = _toSqlDate(day);
      return SpendingBarBucket(
        bucketStart: day,
        label: _weekdayShort(day.weekday),
        total: totalsByDay[key] ?? 0.0,
      );
    });
  }

  if (period == BarChartPeriod.weekly) {
    final rows = await db.rawQuery('''
      SELECT 
        date(
          substr(date, 1, 10),
          '-' || ((CAST(strftime('%w', substr(date, 1, 10)) AS INTEGER) + 6) % 7) || ' days'
        ) AS bucket,
        SUM(amount) AS total
      FROM transactions
      WHERE type IN ('outbound', 'withdrawal')
        AND date(substr(date, 1, 10)) >= date('now', '-55 days')
      GROUP BY bucket
      ORDER BY bucket ASC
    ''');

    final totalsByWeek = <String, double>{};
    for (final row in rows) {
      final bucket = row['bucket'] as String?;
      if (bucket == null) continue;
      totalsByWeek[bucket] = (row['total'] as num?)?.toDouble() ?? 0.0;
    }

    final thisWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return List.generate(8, (index) {
      final weekStart = thisWeekStart.subtract(Duration(days: 7 * (7 - index)));
      final key = _toSqlDate(weekStart);
      return SpendingBarBucket(
        bucketStart: weekStart,
        label: '${weekStart.month}/${weekStart.day}',
        total: totalsByWeek[key] ?? 0.0,
      );
    });
  }

  final rows = await db.rawQuery('''
    SELECT 
      strftime('%Y', substr(date, 1, 10)) AS bucket,
      SUM(amount) AS total
    FROM transactions
    WHERE type IN ('outbound', 'withdrawal')
      AND date(substr(date, 1, 10)) >= date('now', 'start of year', '-5 years')
    GROUP BY bucket
    ORDER BY bucket ASC
  ''');

  final totalsByYear = <int, double>{};
  for (final row in rows) {
    final yearString = row['bucket'] as String?;
    final year = int.tryParse(yearString ?? '');
    if (year == null) continue;
    totalsByYear[year] = (row['total'] as num?)?.toDouble() ?? 0.0;
  }

  final currentYear = now.year;
  return List.generate(6, (index) {
    final year = currentYear - 5 + index;
    final date = DateTime(year, 1, 1);
    return SpendingBarBucket(
      bucketStart: date,
      label: year.toString(),
      total: totalsByYear[year] ?? 0.0,
    );
  });
});

final topCategoriesProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  final allTransactions = await transactionsLs.getTransactions();

  final now = DateTime.now();
  final currentMonthTransactions = allTransactions.where((t) {
    if (t.date == null) return false;
    return t.date!.year == now.year &&
        t.date!.month == now.month &&
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
    for (var m in catMaps) m['id'] as int: m['name'] as String,
  };
  categoryNames[-1] = 'Uncategorized';
  final Map<int, String> categoryIcons = {
    for (var m in catMaps) m['id'] as int: m['icon'] as String? ?? '',
  };

  final List<Map<String, dynamic>> result = [];
  categoryTotals.forEach((id, amount) {
    result.add({
      'name': categoryNames[id] ?? 'Unknown',
      'amount': amount,
      'icon': categoryIcons[id],
    });
  });

  result.sort(
    (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
  );
  return result.take(5).toList();
});

String _toSqlDate(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _weekdayShort(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Mon';
    case DateTime.tuesday:
      return 'Tue';
    case DateTime.wednesday:
      return 'Wed';
    case DateTime.thursday:
      return 'Thu';
    case DateTime.friday:
      return 'Fri';
    case DateTime.saturday:
      return 'Sat';
    default:
      return 'Sun';
  }
}
