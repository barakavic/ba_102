import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:intl/intl.dart';

class TotalSpendingHeader extends ConsumerWidget {
  const TotalSpendingHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(monthlySummaryProvider);
    final isPrivacyMode = ref.watch(privacyModeProvider);
    const Color priColor = Color(0xFF4B0082);

    return summaryAsync.when(
      data: (data) {
        final spent = data['spent'] ?? 0.0;
        
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Spendings this month',
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
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
