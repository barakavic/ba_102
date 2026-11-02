import 'dart:async';

import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/repos/spending_limit_repo.dart';
import 'package:ba_102_fe/data/models/spending_limit_model.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:ba_102_fe/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final spendingLimitsrepoProvider = FutureProvider<SpendingLimitRepo>((
  ref,
) async {
  try {
    final db = await DatabaseHelper.instance.database;
    return SpendingLimitRepo(db);
  } catch (e, st) {
    AppLogger.e('Failed to instanciate the Provider', error: e, stackTrace: st);
    rethrow;
  }
});

class SpendingLimitsNotifier extends AsyncNotifier<SpendingLimit?> {
  @override
  Future<SpendingLimit?> build() async {
    final service = await ref.watch(spendingLimitsrepoProvider.future);
    return await service.getSpendingLimit();
  }

  Future<void> updateLimit(SpendingLimit limit) async {
    final service = await ref.read(spendingLimitsrepoProvider.future);
    await service.updateLimit(limit);

    ref.invalidateSelf();
  }

  Future<void> createLimit(SpendingLimit limit) async {
    final service = await ref.read(spendingLimitsrepoProvider.future);
    await service.createLimit(limit);

    ref.invalidateSelf();
  }

  Future<void> deleteLimit(int id) async {
    final service = await ref.read(spendingLimitsrepoProvider.future);
    await service.deleteLimit(id);

    ref.invalidateSelf();
  }
}

final spendingLimitsProvider =
    AsyncNotifierProvider<SpendingLimitsNotifier, SpendingLimit?>(() {
      return SpendingLimitsNotifier();
    });

class LimitStatus {
  final double? limitAmount;
  final double currentSpending;
  final double alertPercentage;

  LimitStatus({
    this.limitAmount,
    required this.currentSpending,
    required this.alertPercentage,
  });

  double get ratio {
    if (limitAmount == null || limitAmount == 0) return 0.0;
    return currentSpending / limitAmount!;
  }

  bool get isWarning {
    if (limitAmount == null || limitAmount == 0) return false;
    final warningThreshold = (100 - alertPercentage) / 100;
    return ratio >= warningThreshold && ratio < 1.0;
  }

  bool get isExceeded {
    return ratio >= 1.0;
  }
}

final limitStatusProvider = FutureProvider<LimitStatus>((ref) async {
  final activeLimit = ref.watch(spendingLimitsProvider).valueOrNull;
  final dashboardPeriod = ref.watch(dashboardPeriodProvider);
  final summary = ref.watch(periodSummaryProvider).valueOrNull;
  final currentSpending = summary?['spent'] ?? 0.0;

  if (activeLimit == null) {
    return LimitStatus(
      limitAmount: null,
      currentSpending: currentSpending,
      alertPercentage: 0,
    );
  }

  return LimitStatus(
    limitAmount: limitAmountForPeriod(activeLimit, dashboardPeriod),
    currentSpending: currentSpending,
    alertPercentage: activeLimit.alertPercentage.toDouble(),
  );
});

/// Converts legacy period limits to a daily amount without changing storage.
SpendingLimit normalizeLimitToDaily(SpendingLimit limit, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final type = limit.limitType.toLowerCase();
  final dailyAmount = switch (type) {
    'weekly' => limit.amount / 7,
    'monthly' => limit.amount / DateTime(today.year, today.month + 1, 0).day,
    _ => limit.amount,
  };

  return SpendingLimit(
    id: limit.id,
    limitType: 'daily',
    amount: dailyAmount,
    alertPercentage: limit.alertPercentage,
    specificDays: type == 'daily' ? limit.specificDays : null,
    createdAt: limit.createdAt,
  );
}

/// Aggregates a daily limit across the selected dashboard period.
double? limitAmountForPeriod(
  SpendingLimit? limit,
  String period, {
  DateTime? now,
}) {
  if (limit == null) return null;

  final today = now ?? DateTime.now();
  final dailyLimit = normalizeLimitToDaily(limit, now: today);
  final activeDays =
      dailyLimit.specificDays ?? const ['1', '2', '3', '4', '5', '6', '7'];

  if (period == 'Day') {
    return activeDays.contains(today.weekday.toString())
        ? dailyLimit.amount
        : null;
  }

  final start = switch (period) {
    'Week' => DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: today.weekday - 1)),
    'Month' => DateTime(today.year, today.month, 1),
    'Year' => DateTime(today.year, 1, 1),
    _ => null,
  };
  if (start == null) return null;

  final end = switch (period) {
    'Week' => start.add(const Duration(days: 7)),
    'Month' => DateTime(today.year, today.month + 1, 1),
    'Year' => DateTime(today.year + 1, 1, 1),
    _ => start,
  };

  var activeDayCount = 0;
  for (
    var date = start;
    date.isBefore(end);
    date = date.add(const Duration(days: 1))
  ) {
    if (activeDays.contains(date.weekday.toString())) {
      activeDayCount++;
    }
  }

  return dailyLimit.amount * activeDayCount;
}
