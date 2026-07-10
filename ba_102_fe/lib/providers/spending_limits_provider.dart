import 'dart:async';

import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/repos/spending_limit_repo.dart';
import 'package:ba_102_fe/data/models/spending_limit_model.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:ba_102_fe/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final spendingLimitsrepoProvider = FutureProvider<SpendingLimitRepo>((ref) async{
  try {
    final db = await DatabaseHelper.instance.database;
    return SpendingLimitRepo(db);
    
  } catch (e, st) {
    AppLogger.e('Failed to instanciate the Provider', error: e, stackTrace: st);
    rethrow;
  }
});


class SpendingLimitsNotifier extends AsyncNotifier<SpendingLimit?>{
  @override
  Future<SpendingLimit?> build() async{
    final service = await ref.watch(spendingLimitsrepoProvider.future);
    return await service.getSpendingLimit();

    
    
  }

  Future<void> updateLimit(SpendingLimit limit) async{
    final service = await ref.read(spendingLimitsrepoProvider.future);
    await service.updateLimit(limit);

    ref.invalidateSelf();
  }

  Future<void> createLimit(SpendingLimit limit) async{
    final service = await ref.read(spendingLimitsrepoProvider.future);
    await service.createLimit(limit);

    ref.invalidateSelf();
  }

  Future<void> deleteLimit(int id)async{
    final service = await ref.read(spendingLimitsrepoProvider.future);
    await service.deleteLimit(id);

    ref.invalidateSelf();

  }
  

}

final spendingLimitsProvider = AsyncNotifierProvider<SpendingLimitsNotifier, SpendingLimit?>((){
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
    if(limitAmount == null || limitAmount == 0) return 0.0;
    return currentSpending/ limitAmount!;
  }

  bool get isWarning{
    if(limitAmount == null || limitAmount == 0) return false;
    final warningThreshold = (100 - alertPercentage) / 100;
    return ratio >= warningThreshold && ratio < 1.0;
  }

  bool get isExceeded{
    return ratio >= 1.0;
    
  }
}

final limitStatusProvider = FutureProvider<LimitStatus>((ref) async{
  final activeLimit = ref.watch(spendingLimitsProvider).valueOrNull;
  final dashboardPeriod = ref.watch(dashboardPeriodProvider);
  final summary = ref.watch(periodSummaryProvider).valueOrNull;
  final currentSpending = summary?['spent'] ?? 0.0;
  

  if (activeLimit == null){
    return LimitStatus(
      limitAmount: null,
      currentSpending: currentSpending, 
      alertPercentage: 0
      );
  }


  double? calculatedLimit;
  final type = activeLimit.limitType.toLowerCase();

  if (type == 'daily'){
    calculatedLimit = _calculateDailyLimitForPeriod(activeLimit, dashboardPeriod);

  }

  else if (type == 'weekly') {
    calculatedLimit = _calculateWeeklyLimitForPeriod(activeLimit, dashboardPeriod);
  } else if (type == 'monthly') {
    calculatedLimit = _calculateMonthlyLimitForPeriod(activeLimit, dashboardPeriod);
  }
  return LimitStatus(
    limitAmount: calculatedLimit,
    currentSpending: currentSpending,
    alertPercentage: activeLimit.alertPercentage.toDouble(),
  );
});

double _calculateDailyLimitForPeriod(SpendingLimit limit, String dashboardPeriod) {
  final now = DateTime.now();
  final activeDays = limit.specificDays ?? ['1', '2', '3', '4', '5', '6', '7']; // '1'=Mon, '7'=Sun
  if (dashboardPeriod == 'Week') {
    int count = 0;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    for (int i = 0; i < 7; i++) {
      final day = monday.add(Duration(days: i));
      if (activeDays.contains(day.weekday.toString())) {
        count++;
      }
    }
    return limit.amount * count;
  }
  if (dashboardPeriod == 'Month') {
    int count = 0;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    for (int d = 1; d <= totalDays; d++) {
      final day = DateTime(now.year, now.month, d);
      if (activeDays.contains(day.weekday.toString())) {
        count++;
      }
    }
    return limit.amount * count;
  }

  int count = 0;
  final totalDays = DateTime(now.year + 1, 1, 1).difference(DateTime(now.year, 1, 1)).inDays;
  final startOfYear = DateTime(now.year, 1, 1);
  for (int d = 0; d < totalDays; d++) {
    final day = startOfYear.add(Duration(days: d));
    if (activeDays.contains(day.weekday.toString())) {
      count++;
    }
  }
  return limit.amount * count;
}
double? _calculateWeeklyLimitForPeriod(SpendingLimit limit, String dashboardPeriod) {
  if (dashboardPeriod == 'Week') {
    return limit.amount;
  }
  if (dashboardPeriod == 'Month') {
    return limit.amount * 4.33;
  }
  return limit.amount * 52;
}
double? _calculateMonthlyLimitForPeriod(SpendingLimit limit, String dashboardPeriod) {
  if (dashboardPeriod == 'Week') {
    return null;
  }
  if (dashboardPeriod == 'Month') {
    return limit.amount;
  }
  return limit.amount * 12;
}

