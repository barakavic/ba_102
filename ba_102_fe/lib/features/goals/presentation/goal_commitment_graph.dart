import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/goals_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

bool _isGoalGraphSavingDay(DateTime day, Goal goal) {
  return goal.scheduleType == 'daily' ||
      goal.savingDays.contains(day.weekday) ||
      (goal.savingDays.isEmpty && day.weekday <= goal.contributionsPerWeek);
}

DateTime? _goalGraphEstimatedFinishDate(Goal goal) {
  final amount = goal.contributionAmount;
  final target = goal.targetAmount;
  if (amount == null ||
      amount <= 0 ||
      target == null ||
      target <= goal.currentAmount) {
    return null;
  }
  final slotsNeeded = ((target - goal.currentAmount) / amount).ceil();
  final now = DateTime.now();
  var slots = 0;
  for (var offset = 0; offset <= 36500; offset++) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: offset));
    if (_isGoalGraphSavingDay(day, goal) && ++slots >= slotsNeeded) return day;
  }
  return null;
}

class GoalCommitmentGraph extends StatefulWidget {
  final Goal goal;
  const GoalCommitmentGraph({super.key, required this.goal});

  @override
  State<GoalCommitmentGraph> createState() => GoalCommitmentGraphState();
}

class GoalCommitmentGraphState extends State<GoalCommitmentGraph> {
  late Future<List<Map<String, dynamic>>> _timeline;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  @override
  void didUpdateWidget(covariant GoalCommitmentGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.goal.id != widget.goal.id ||
        oldWidget.goal.currentAmount != widget.goal.currentAmount) {
      _loadTimeline();
    }
  }

  void _loadTimeline() {
    _timeline = DatabaseHelper.instance.database.then(
      (db) => GoalsLs(db).getContributionTimeline(widget.goal.id!),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _timeline,
    builder: (context, snapshot) {
      final goal = widget.goal;
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const SizedBox(
          height: 116,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }
      if (snapshot.hasError) {
        return Text(
          'Could not load goal contributions.',
          style: Theme.of(context).textTheme.bodySmall,
        );
      }
      final rows = snapshot.data ?? const <Map<String, dynamic>>[];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDate = goal.createdAt ?? today;
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final endDate =
          goal.deadline ?? _goalGraphEstimatedFinishDate(goal) ?? today;
      final rawEnd = DateTime(endDate.year, endDate.month, endDate.day);
      final end = rawEnd.isBefore(start) ? start : rawEnd;
      final firstWeek = start.subtract(Duration(days: start.weekday - 1));
      final lastWeek = end.add(Duration(days: 7 - end.weekday));
      final weekCount = (lastWeek.difference(firstWeek).inDays ~/ 7) + 1;
      final amounts = <DateTime, double>{};
      for (final row in rows) {
        final date = DateTime.tryParse(row['date'] as String? ?? '');
        if (date == null) continue;
        final day = DateTime(date.year, date.month, date.day);
        if (day.isBefore(start) || day.isAfter(end)) continue;
        amounts[day] = (amounts[day] ?? 0) + (row['amount'] as num).toDouble();
      }
      final expectedByDay = _dailyQuotas(start, end, goal, amounts);
      final total = amounts.values.fold<double>(
        0,
        (sum, amount) => sum + amount,
      );
      final colors = Theme.of(context).colorScheme;
      final currency = NumberFormat.currency(
        name: 'KES',
        symbol: 'KES ',
        decimalDigits: 0,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat.yMMMd().format(start)} – ${DateFormat.yMMMd().format(end)} · ${currency.format(total)} saved',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 116,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 18),
                    ...List.generate(
                      7,
                      (i) => SizedBox(
                        height: 14,
                        child: Text(
                          i.isEven
                              ? const ['M', '', 'W', '', 'F', '', 'S'][i]
                              : '',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: weekCount,
                    itemBuilder: (context, week) {
                      final monday = firstWeek.add(Duration(days: week * 7));
                      final visibleDays =
                          List.generate(
                            7,
                            (i) => monday.add(Duration(days: i)),
                          ).where(
                            (day) => !day.isBefore(start) && !day.isAfter(end),
                          );
                      final monthStarts = visibleDays.where(
                        (day) => day.day == 1,
                      );
                      final monthStart = monthStarts.isEmpty
                          ? null
                          : monthStarts.first;
                      final firstVisible = visibleDays.isEmpty
                          ? monday
                          : visibleDays.first;
                      final monthLabel = monthStart ?? firstVisible;
                      return SizedBox(
                        width: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 18,
                              child: week == 0 || monthStart != null
                                  ? OverflowBox(
                                      alignment: Alignment.centerLeft,
                                      maxWidth: 48,
                                      child: Text(
                                        DateFormat.MMM().format(monthLabel),
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall,
                                      ),
                                    )
                                  : null,
                            ),
                            ...List.generate(7, (row) {
                              final day = monday.add(Duration(days: row));
                              final inRange =
                                  !day.isBefore(start) && !day.isAfter(end);
                              final scheduled = _isGoalGraphSavingDay(
                                day,
                                goal,
                              );
                              final amount = amounts[day] ?? 0;
                              final quota = expectedByDay[day] ?? 0;
                              final future = day.isAfter(today);
                              final met = amount >= quota && quota > 0;
                              final color = !inRange || !scheduled || future
                                  ? colors.surfaceContainerHighest
                                  : met || (quota <= 0 && amount > 0)
                                  ? Colors.green
                                  : amount > 0
                                  ? Colors.amber
                                  : Colors.red;
                              final status = !inRange
                                  ? 'Outside goal duration'
                                  : !scheduled
                                  ? 'Unscheduled day'
                                  : future
                                  ? 'Scheduled · future'
                                  : met
                                  ? 'Quota met'
                                  : amount > 0
                                  ? 'Below quota'
                                  : 'No contribution';
                              return SizedBox(
                                width: 11,
                                height: 14,
                                child: Padding(
                                  padding: const EdgeInsets.all(1),
                                  child: Tooltip(
                                    message:
                                        '${DateFormat.yMMMd().format(day)}\n$status\nSaved: ${currency.format(amount)}${scheduled ? '\nExpected: ${currency.format(quota)}' : ''}',
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Green: met · Yellow: partial · Red: none · Gray: unscheduled/future',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      );
    },
  );

  Map<DateTime, double> _dailyQuotas(
    DateTime start,
    DateTime end,
    Goal goal,
    Map<DateTime, double> contributions,
  ) {
    final quotas = <DateTime, double>{};
    final fixedAmount = goal.contributionAmount ?? 0;
    var remaining = (goal.targetAmount ?? 0);
    final days = <DateTime>[];
    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      if (_isGoalGraphSavingDay(day, goal)) days.add(day);
    }
    for (var i = 0; i < days.length; i++) {
      final day = days[i];
      if (goal.planningMode == 'amount' ||
          goal.deadline == null ||
          goal.targetAmount == null) {
        quotas[day] = fixedAmount;
        continue;
      }
      final scheduledDaysLeft = days.length - i;
      final quota = remaining <= 0 ? 0.0 : remaining / scheduledDaysLeft;
      quotas[day] = quota;
      if (!day.isAfter(DateTime.now())) {
        remaining -= contributions[day] ?? 0;
      }
    }
    return quotas;
  }
}
