import 'dart:math' as math;
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_form_page.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:ba_102_fe/services/icon_service.dart';
import 'package:ba_102_fe/services/categorization_service.dart';
import 'package:ba_102_fe/features/plans/presentation/plan_analytics_page.dart';
import 'package:ba_102_fe/features/plans/providers/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';



class PlanDetailsPage extends ConsumerStatefulWidget {
  final int planId;

  const PlanDetailsPage({super.key, required this.planId});

  @override
  ConsumerState<PlanDetailsPage> createState() => _PlanDetailsPageState();
}

class _PlanDetailsPageState extends ConsumerState<PlanDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);

    return plansAsync.when(
      data: (plans) {
        final plan = plans.firstWhere((p) => p.id == widget.planId, orElse: () => plans.first);
        final transactionsAsync = ref.watch(planTransactionsProvider(plan));
        final categoriesAsync = ref.watch(planCategoriesProvider);

        return Scaffold(
          appBar: AppBar(
            title: Text(plan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black,
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics_outlined, color: Color(0xFF4B0082)),
                tooltip: 'View Analytics',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanAnalyticsPage(plan: plan),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlansFormPage(plan: plan),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Plan'),
                      content: const Text('Are you sure you want to delete this plan?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(deletePlanProvider)(plan.id);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await CategorizationService().recategorizeUncategorizedTransactions();
              ref.invalidate(plansProvider);
              ref.invalidate(planTransactionsProvider(plan));
              ref.invalidate(planCategoriesProvider);
              await ref.read(planTransactionsProvider(plan).future);
            },
            child: transactionsAsync.when(
              skipLoadingOnRefresh: false,
              data: (allTransactions) {
                final spendingTransactions = allTransactions.where((t) => 
                  t.type == 'outbound' || t.type == 'withdrawal'
                ).toList();

                final totalSpent = spendingTransactions.fold<double>(0, (sum, t) => sum + (t.amount ?? 0));
                final remaining = plan.limitAmount - totalSpent;
                final progress = plan.limitAmount > 0 ? (totalSpent / plan.limitAmount).clamp(0.0, 1.0) : 0.0;

                final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
                final planStart = DateTime(plan.startDate.year, plan.startDate.month, plan.startDate.day);
                final planEnd = DateTime(plan.endDate.year, plan.endDate.month, plan.endDate.day);

                final totalDays = planEnd.difference(planStart).inDays + 1;

                int daysPassed;
                int daysRemaining;

                if (now.isBefore(planStart)) {
                  daysPassed = 0;
                  daysRemaining = totalDays;
                } else if (now.isAfter(planEnd)) {
                  daysPassed = totalDays;
                  daysRemaining = 0;
                } else {
                  daysPassed = now.difference(planStart).inDays + 1;
                  daysRemaining = totalDays - daysPassed + 1;
                }

                final avgDailySpend = daysPassed > 0 ? totalSpent / daysPassed : 0.0;
                final safeToSpendDaily = daysRemaining > 0 
                  ? (remaining > 0 ? remaining / daysRemaining : 0.0) 
                  : (remaining > 0 ? remaining : 0.0);

                final timeProgress = (daysPassed / totalDays).clamp(0.0, 1.0);

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(totalSpent, plan.limitAmount, progress, remaining),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Daily Insights'),
                      _buildInsightsGrid(avgDailySpend, safeToSpendDaily, daysRemaining),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Time vs Budget'),
                      _buildTimeVsBudgetCard(timeProgress, progress, daysPassed, totalDays),
                      const SizedBox(height: 40),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlanAnalyticsPage(plan: plan),
                              ),
                            );
                          },
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text('View Detailed Analytics'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4B0082),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(child: Text('Error: $err')),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildSectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }



  Widget _buildHeaderCard(double spent, double limit, double progress, double remaining) {
    final statusColor = progress > 0.9 ? Colors.red : progress > 0.7 ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.8), statusColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Budget', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text(
                'KES ${NumberFormat('#,###').format(limit)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text('Spent', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat('Spent', 'KES ${NumberFormat('#,###').format(spent)}'),
              Container(width: 1, height: 30, color: Colors.white24),
              _buildHeaderStat('Remaining', 'KES ${NumberFormat('#,###').format(remaining)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildInsightsGrid(double avg, double safeDaily, int daysLeft) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildInsightCard('Avg. Daily', 'KES ${NumberFormat('#,###').format(avg)}', Icons.analytics_outlined, Colors.blue),
        _buildInsightCard('Safe Daily', 'KES ${NumberFormat('#,###').format(safeDaily)}', Icons.security_outlined, Colors.green),
        _buildInsightCard('Days Left', '$daysLeft Days', Icons.calendar_today_outlined, Colors.orange),
        _buildInsightCard('Status', avg > safeDaily ? 'Over-pacing' : 'On Track', Icons.speed_outlined, avg > safeDaily ? Colors.red : Colors.green),
      ],
    );
  }

  Widget _buildInsightCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeVsBudgetCard(double timeProgress, double budgetProgress, int daysPassed, int totalDays) {
    final isOverpacing = budgetProgress > timeProgress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Day $daysPassed of $totalDays', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              Text(
                isOverpacing ? '⚠️ Spending too fast' : '✅ Spending at good pace',
                style: TextStyle(fontSize: 12, color: isOverpacing ? Colors.orange.shade800 : Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressRow('Time Elapsed', timeProgress, Colors.blue),
          const SizedBox(height: 12),
          _buildProgressRow('Budget Used', budgetProgress, isOverpacing ? Colors.orange : Colors.green),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
