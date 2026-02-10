import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';

class SpendingBarChart extends ConsumerWidget {
  const SpendingBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(barChartPeriodProvider);
    final dataAsync = ref.watch(spendingBarDataProvider);
    final isPrivacyMode = ref.watch(privacyModeProvider);
    const primaryColor = Color(0xFF4B0082);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Analytics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PeriodChip(
                label: 'Daily',
                isSelected: period == BarChartPeriod.daily,
                onTap: () => ref.read(barChartPeriodProvider.notifier).state =
                    BarChartPeriod.daily,
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: 'Weekly',
                isSelected: period == BarChartPeriod.weekly,
                onTap: () => ref.read(barChartPeriodProvider.notifier).state =
                    BarChartPeriod.weekly,
              ),
              const SizedBox(width: 8),
              _PeriodChip(
                label: 'Yearly',
                isSelected: period == BarChartPeriod.yearly,
                onTap: () => ref.read(barChartPeriodProvider.notifier).state =
                    BarChartPeriod.yearly,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: dataAsync.when(
              data: (data) {
                if (data.isEmpty) {
                  return const Center(
                    child: Text(
                      'No spending data yet',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                final maxValue = data
                    .map((point) => point.total)
                    .fold<double>(
                      0.0,
                      (previous, value) => value > previous ? value : previous,
                    );
                final maxY = (maxValue <= 0 ? 100 : maxValue * 1.2).toDouble();

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    minY: 0,
                    maxY: maxY,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withValues(alpha: 0.12),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: !isPrivacyMode,
                          reservedSize: 48,
                          interval: maxY / 4,
                          getTitlesWidget: (value, meta) {
                            if (value <= 0) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              NumberFormat.compact().format(value),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= data.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[index].label,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final pointIndex = group.x.toInt();
                          if (pointIndex < 0 || pointIndex >= data.length) {
                            return null;
                          }
                          final point = data[pointIndex];
                          final amountLabel = isPrivacyMode
                              ? '****'
                              : 'KES ${NumberFormat('#,###').format(point.total)}';

                          return BarTooltipItem(
                            '$amountLabel\n${_tooltipPeriodLabel(period, point.bucketStart)}',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    barGroups: List.generate(data.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data[index].total,
                            width: 16,
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(6),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: Colors.grey.withValues(alpha: 0.08),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Unable to load chart data')),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4B0082) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}

String _tooltipPeriodLabel(BarChartPeriod period, DateTime date) {
  if (period == BarChartPeriod.daily) {
    return DateFormat('EEE, MMM d').format(date);
  }

  if (period == BarChartPeriod.weekly) {
    final end = date.add(const Duration(days: 6));
    return '${DateFormat('MMM d').format(date)} - ${DateFormat('MMM d').format(end)}';
  }

  return DateFormat('yyyy').format(date);
}
