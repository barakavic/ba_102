import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/glass_hero_card.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/spending_bar_chart.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/spending_speedometer.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/top_categories_row.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:ba_102_fe/features/goals/presentation/goal_commitment_graph.dart';
import 'package:ba_102_fe/features/goals/providers/goal_providers.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mpesaBalanceProvider);
        ref.invalidate(mpesaBalanceHistoryProvider);
        ref.invalidate(periodSummaryProvider);
        ref.invalidate(spendingBarDataProvider);
        ref.invalidate(topCategoriesProvider);
        ref.invalidate(recentTransactionsProvider);
        ref.invalidate(latestSavingsGoalProvider);
        await ref.read(mpesaBalanceProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: GlassHeroCard()),

          const SliverToBoxAdapter(child: SpendingSpeedometer()),

          const SliverToBoxAdapter(child: SpendingBarChart()),

          const SliverToBoxAdapter(child: TopCategoriesRow()),

          const SliverToBoxAdapter(child: _LatestGoalCard()),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

class _LatestGoalCard extends ConsumerWidget {
  const _LatestGoalCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(latestSavingsGoalProvider);
    return goalAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (goal) {
        if (goal == null || goal.id == null) return const SizedBox.shrink();
        final currency = NumberFormat.currency(
          name: 'KES',
          symbol: 'KES ',
          decimalDigits: 0,
        );
        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.track_changes_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Latest goal',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  goal.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${currency.format(goal.currentAmount)} saved${goal.targetAmount == null ? '' : ' of ${currency.format(goal.targetAmount)}'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                GoalCommitmentGraph(goal: goal),
              ],
            ),
          ),
        );
      },
    );
  }
}
