import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:intl/intl.dart';

class SpendingPulseChart extends ConsumerWidget {
  const SpendingPulseChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(mpesaBalanceHistoryProvider);

    return historyAsync.when(
      data: (history) {
        if (history.isEmpty || history.length < 2) {
          return const SizedBox.shrink(); // Need at least 2 points for a line
        }

        // Map data to FlSpot
        final spots = history.asMap().entries.map((e) {
          final index = e.key.toDouble();
          final balance = e.value['balance'] as double;
          return FlSpot(index, balance);
        }).toList();

        final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
        final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
        final padding = (maxY - minY) * 0.2; // Add some breathing room

        return SizedBox(
          height: 60,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: spots.length.toDouble() - 1,
              minY: minY - padding,
              maxY: maxY + padding,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.black87,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      if (index >= 0 && index < history.length) {
                        final dateStr = history[index]['date'] as String;
                        final date = DateTime.tryParse(dateStr);
                        final formattedDate = date != null ? DateFormat('MMM d').format(date) : '';
                        return LineTooltipItem(
                          '${NumberFormat.compact().format(spot.y)}\n$formattedDate',
                          const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.white.withOpacity(0.5),
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
