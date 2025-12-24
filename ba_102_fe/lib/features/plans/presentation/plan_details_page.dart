import 'dart:math' as math;
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_form_page.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:ba_102_fe/services/categorization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum CategoryViewType { list, chart }

final deletePlanProvider = Provider((ref) {
  return (int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('budget_plans', where: 'id = ?', whereArgs: [id]);
    ref.refresh(plansProvider);
  };
});

final planTransactionsProvider = FutureProvider.family<List<Transaction>, Plan>((ref, plan) async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query(
    'transactions',
    where: 'date >= ? AND date <= ?',
    whereArgs: [plan.startDate.toIso8601String(), plan.endDate.toIso8601String()],
    orderBy: 'amount DESC',
  );
  return maps.map((m) => Transaction.fromMap(m)).toList();
});

final planCategoriesProvider = FutureProvider<Map<int, String>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final List<Map<String, dynamic>> maps = await db.query('budget_category');
  final Map<int, String> categories = {for (var m in maps) m['id'] as int: m['name'] as String};
  categories[-1] = 'Uncategorized';
  return categories;
});

class PlanDetailsPage extends ConsumerStatefulWidget {
  final int planId;

  const PlanDetailsPage({super.key, required this.planId});

  @override
  ConsumerState<PlanDetailsPage> createState() => _PlanDetailsPageState();
}

class _PlanDetailsPageState extends ConsumerState<PlanDetailsPage> {
  bool _isTransactionsExpanded = false;
  CategoryViewType _categoryViewType = CategoryViewType.list;

  final List<Color> _chartColors = [
    const Color(0xFF4B0082), // Indigo
    const Color(0xFF8A2BE2), // BlueViolet
    const Color(0xFFFF4500), // OrangeRed
    const Color(0xFF32CD32), // LimeGreen
    const Color(0xFF1E90FF), // DodgerBlue
    const Color(0xFFFFD700), // Gold
    const Color(0xFFFF1493), // DeepPink
    const Color(0xFF00CED1), // DarkTurquoise
  ];

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
                      const SizedBox(height: 24),
                      _buildCategorySection(spendingTransactions, categoriesAsync),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Frequent Spending'),
                      _buildFrequentTransactions(spendingTransactions),
                      const SizedBox(height: 24),
                      _buildSectionTitle('Top Transactions'),
                      _buildTopTransactions(spendingTransactions, plan.limitAmount),
                      const SizedBox(height: 80),
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

  Widget _buildCategorySection(List<Transaction> transactions, AsyncValue<Map<int, String>> categoriesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Category Breakdown',
          trailing: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggle(Icons.list, CategoryViewType.list),
                _buildViewToggle(Icons.pie_chart_outline, CategoryViewType.chart),
              ],
            ),
          ),
        ),
        categoriesAsync.when(
          data: (categories) {
            if (_categoryViewType == CategoryViewType.list) {
              return _buildCategoryBreakdownList(transactions, categories);
            } else {
              return _buildCategoryChart(transactions, categories);
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading categories: $e'),
        ),
      ],
    );
  }

  Widget _buildViewToggle(IconData icon, CategoryViewType type) {
    final isSelected = _categoryViewType == type;
    return GestureDetector(
      onTap: () => setState(() => _categoryViewType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4B0082) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
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

  Widget _buildCategoryBreakdownList(List<Transaction> transactions, Map<int, String> categories) {
    final Map<int, double> categoryTotals = {};
    for (var tx in transactions) {
      final catId = tx.categoryId ?? -1;
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + (tx.amount ?? 0);
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return const Center(child: Text('No spending data yet', style: TextStyle(color: Colors.grey)));
    }

    return Column(
      children: sortedCategories.asMap().entries.map((entry) {
        final index = entry.key;
        final catEntry = entry.value;
        final catName = categories[catEntry.key] ?? 'Unknown';
        final amount = catEntry.value;
        final total = transactions.fold<double>(0, (sum, t) => sum + (t.amount ?? 0));
        final percentage = total > 0 ? amount / total : 0.0;
        final color = _chartColors[index % _chartColors.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.category_outlined, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(catName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('KES ${NumberFormat('#,###').format(amount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${(percentage * 100).toInt()}%', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryChart(List<Transaction> transactions, Map<int, String> categories) {
    final Map<int, double> categoryTotals = {};
    for (var tx in transactions) {
      final catId = tx.categoryId ?? -1;
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + (tx.amount ?? 0);
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return const Center(child: Text('No spending data yet', style: TextStyle(color: Colors.grey)));
    }

    final total = transactions.fold<double>(0, (sum, t) => sum + (t.amount ?? 0));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: DonutChartPainter(
                    data: sortedCategories.map((e) => e.value / total).toList(),
                    colors: _chartColors,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'KES ${NumberFormat('#,###').format(total)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Text('Total Spent', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: sortedCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final catEntry = entry.value;
              final catName = categories[catEntry.key] ?? 'Unknown';
              final color = _chartColors[index % _chartColors.length];
              final percentage = (catEntry.value / total * 100).toInt();

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$catName ($percentage%)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    final Map<String, List<Transaction>> grouped = {};
    for (var tx in transactions) {
      final key = tx.vendor ?? tx.description ?? 'Unknown';
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(tx);
    }

    final sortedFreq = grouped.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final topFreq = sortedFreq.take(3).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: topFreq.map((entry) {
          final name = entry.key;
          final count = entry.value.length;
          final total = entry.value.fold<double>(0, (sum, t) => sum + (t.amount ?? 0));

          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('x$count', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                    ),
                    const Icon(Icons.repeat, size: 14, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Total: KES ${NumberFormat('#,###').format(total)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopTransactions(List<Transaction> transactions, double budgetLimit) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found', style: TextStyle(color: Colors.grey)));
    }

    final displayCount = _isTransactionsExpanded ? transactions.length : (transactions.length > 2 ? 2 : transactions.length);
    final displayList = transactions.take(displayCount).toList();

    return Column(
      children: [
        ...displayList.asMap().entries.map((entry) {
          final index = entry.key;
          final tx = entry.value;
          final impact = budgetLimit > 0 ? (tx.amount! / budgetLimit * 100) : 0.0;
          final isTopTwo = index < 2;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isTopTwo ? Colors.red.withOpacity(0.02) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              leading: CircleAvatar(
                backgroundColor: Colors.red.withOpacity(0.1),
                child: const Icon(Icons.arrow_upward, color: Colors.red, size: 18),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      tx.description ?? 'No Description',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isTopTwo && impact > 5)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${impact.toStringAsFixed(1)}% of budget',
                        style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              subtitle: Text(DateFormat('MMM dd, yyyy').format(tx.date ?? DateTime.now()), style: const TextStyle(fontSize: 12)),
              trailing: Text(
                'KES ${NumberFormat('#,###').format(tx.amount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
              ),
            ),
          );
        }),
        if (transactions.length > 2)
          TextButton.icon(
            onPressed: () => setState(() => _isTransactionsExpanded = !_isTransactionsExpanded),
            icon: Icon(_isTransactionsExpanded ? Icons.expand_less : Icons.expand_more),
            label: Text(_isTransactionsExpanded ? 'Show Less' : 'Show More (${transactions.length - 2} more)'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF4B0082)),
          ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> data;
  final List<Color> colors;

  DonutChartPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = data[i] * 2 * math.pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 15),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
