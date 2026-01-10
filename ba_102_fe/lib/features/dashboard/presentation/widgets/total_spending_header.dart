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
    const Color priColor = Color(0xFF4B0082);

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
                    const Text(
                      'Total Spendings this ',
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      period.toLowerCase(),
                      style: const TextStyle(
                        fontSize: 16, 
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isPrivacyMode ? '****' : NumberFormat('#,###').format(spent),
                style: const TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: priColor,
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
