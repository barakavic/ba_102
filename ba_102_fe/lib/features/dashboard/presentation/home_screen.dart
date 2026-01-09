import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/glass_hero_card.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/total_spending_header.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/monthly_budget_summary.dart';
import 'package:ba_102_fe/features/dashboard/presentation/widgets/top_categories_row.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';

class HomeScreen extends ConsumerWidget{
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(mpesaBalanceProvider);
        ref.invalidate(mpesaBalanceHistoryProvider);
        ref.invalidate(monthlySummaryProvider);
        ref.invalidate(topCategoriesProvider);
        ref.invalidate(recentTransactionsProvider);
        await ref.read(mpesaBalanceProvider.future);
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverToBoxAdapter(
            child: GlassHeroCard(),
          ),
  
          const SliverToBoxAdapter(
            child: TotalSpendingHeader(),
          ),
  
          const SliverToBoxAdapter(
            child: MonthlyBudgetSummary(),
          ),
  
          const SliverToBoxAdapter(
            child: TopCategoriesRow(),
          ),
  
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 100),
          ),
        ],
      ),
    );
  }
}