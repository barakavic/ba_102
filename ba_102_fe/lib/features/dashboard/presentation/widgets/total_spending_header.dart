import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:intl/intl.dart';

class TotalSpendingHeader extends ConsumerWidget {
  const TotalSpendingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(periodSummaryProvider);
    final period = ref.watch(dashboardPeriodProvider);
    final isPrivacyMode = ref.watch(privacyModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    void cyclePeriod() {
      final current = ref.read(dashboardPeriodProvider);
      if (current == 'Week') ref.read(dashboardPeriodProvider.notifier).state = 'Month';
      else if (current == 'Month') ref.read(dashboardPeriodProvider.notifier).state = 'Year';
      else ref.read(dashboardPeriodProvider.notifier).state = 'Week';
    }

    return summaryAsync.when(
      data: (data) {
        final spent = data['spent'] ?? 0.0;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: cyclePeriod,
                child: Row(
                  children: [
                    Text(
                      'Total Spendings this ',
                      style: TextStyle(
                        fontSize: 16, 
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      period.toLowerCase(),
                      style: TextStyle(
                        fontSize: 16, 
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface.withOpacity(0.4), size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPrivacyMode ? '****' : NumberFormat('#,###').format(spent),
                style: TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
