import 'dart:math' as math;
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:ba_102_fe/features/plans/providers/plan_providers.dart';
import 'package:ba_102_fe/services/icon_service.dart';
import 'package:ba_102_fe/services/categorization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

enum CategoryViewType { list, chart }

class PlanAnalyticsPage extends ConsumerStatefulWidget {
  final Plan plan;

  const PlanAnalyticsPage({super.key, required this.plan});

  @override
  ConsumerState<PlanAnalyticsPage> createState() => _PlanAnalyticsPageState();
}

class _PlanAnalyticsPageState extends ConsumerState<PlanAnalyticsPage> {
  CategoryViewType _categoryViewType = CategoryViewType.list;
  bool _isTransactionsExpanded = false;

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

  Color _getCategoryColor(Category category, int index) {
    if (category.id == -1) return Colors.orange;
    if (category.color != null) {
      try {
        return Color(int.parse(category.color!));
      } catch (_) {}
    }
    return _chartColors[index % _chartColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(planTransactionsProvider(widget.plan));
    final categoriesAsync = ref.watch(planCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await CategorizationService().recategorizeUncategorizedTransactions();
          ref.invalidate(plansProvider);
          ref.invalidate(planTransactionsProvider(widget.plan));
          ref.invalidate(planCategoriesProvider);
          await ref.read(planTransactionsProvider(widget.plan).future);
        },
        child: transactionsAsync.when(
          data: (allTransactions) {
            final spendingTransactions = allTransactions.where((t) => 
              t.type == 'outbound' || t.type == 'withdrawal'
            ).toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorySection(spendingTransactions, categoriesAsync),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Frequent Spending'),
                  _buildFrequentTransactions(spendingTransactions),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Top Transactions'),
                  _buildTopTransactions(spendingTransactions, widget.plan.limitAmount),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
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

  Widget _buildCategorySection(List<Transaction> transactions, AsyncValue<Map<int, Category>> categoriesAsync) {
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

  Widget _buildCategoryBreakdownList(List<Transaction> transactions, Map<int, Category> categories) {
    final Map<int, double> categoryTotals = {};
    for (var tx in transactions) {
      final catId = tx.categoryId ?? -1;
      final category = categories[catId];
      // Roll up sub-category spending to parent
      final effectiveCatId = (category?.parentId != null) ? category!.parentId! : catId;
      categoryTotals[effectiveCatId] = (categoryTotals[effectiveCatId] ?? 0) + (tx.amount ?? 0);
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
        final category = categories[catEntry.key] ?? Category(id: -1, name: 'Unknown', transactions: []);
        final amount = catEntry.value;
        final total = transactions.fold<double>(0, (sum, t) => sum + (t.amount ?? 0));
        final percentage = total > 0 ? amount / total : 0.0;
        final color = _getCategoryColor(category, index);
        final icon = IconService.getIcon(category.icon, category.name);

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
                child: Icon(category.id == -1 ? Icons.help_outline : icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

  Widget _buildCategoryChart(List<Transaction> transactions, Map<int, Category> categories) {
    final Map<int, double> categoryTotals = {};
    for (var tx in transactions) {
      final catId = tx.categoryId ?? -1;
      final category = categories[catId];
      // Roll up sub-category spending to parent
      final effectiveCatId = (category?.parentId != null) ? category!.parentId! : catId;
      categoryTotals[effectiveCatId] = (categoryTotals[effectiveCatId] ?? 0) + (tx.amount ?? 0);
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return const Center(child: Text('No spending data yet', style: TextStyle(color: Colors.grey)));
    }

    final total = transactions.fold<double>(0, (sum, t) => sum + (t.amount ?? 0));
    final List<Color> sliceColors = sortedCategories.asMap().entries.map((e) {
      final category = categories[e.value.key] ?? Category(id: -1, name: 'Unknown', transactions: []);
      return _getCategoryColor(category, e.key);
    }).toList();

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
                    colors: sliceColors,
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
              final category = categories[catEntry.key] ?? Category(id: -1, name: 'Unknown', transactions: []);
              final color = _getCategoryColor(category, index);
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
                    '${category.name} ($percentage%)',
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
