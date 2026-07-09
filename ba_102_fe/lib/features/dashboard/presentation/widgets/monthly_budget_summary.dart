import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:intl/intl.dart';

class MonthlyBudgetSummary extends ConsumerWidget {
  const MonthlyBudgetSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(periodSummaryProvider);
    final isPrivacyMode = ref.watch(privacyModeProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return summaryAsync.when(
      data: (data) {
        final spent = data['spent'] ?? 0.0;
        final income = data['income'] ?? 0.0;
        
        final progress = income > 0 ? (spent / income).clamp(0.0, 1.0) : 0.0;
        final percentage = (progress * 100).toInt();

        // Determine status color
        Color statusColor = Colors.green;
        String statusText = "Excellent! You're saving well.";
        
        if (percentage >= 100) {
          statusColor = Colors.red;
          statusText = "Attention: You've exceeded your income.";
        } else if (percentage >= 80) {
          statusColor = Colors.orange;
          statusText = "Careful, you're nearing your limit.";
        } else if (percentage >= 50) {
          statusColor = Colors.blue;
          statusText = "On track, keep it up.";
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: onSurface.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${ref.watch(dashboardPeriodProvider)} Reality Check',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$percentage%',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: onSurface.withValues(alpha: 0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spent',
                        style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPrivacyMode ? '****' : 'KES ${NumberFormat.compact().format(spent)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: onSurface.withValues(alpha: 0.1),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Income',
                        style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.6)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPrivacyMode ? '****' : 'KES ${NumberFormat.compact().format(income)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
