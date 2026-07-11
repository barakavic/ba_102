import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/glass_hero_card.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/spending_bar_chart.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/spending_speedometer.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/top_categories_row.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';

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
        await ref.read(mpesaBalanceProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(child: GlassHeroCard()),

          const SliverToBoxAdapter(child: SpendingSpeedometer()),

          const SliverToBoxAdapter(child: SpendingBarChart()),

          const SliverToBoxAdapter(child: TopCategoriesRow()),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}
