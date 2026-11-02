import 'package:ba_102_fe/features/shopping/presentation/utils/budget_culprit_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingListDetailTotal extends StatelessWidget {
  final double total;
  final double? budgetLimit;
  final Color accentColor;
  final bool isEditMode;
  final bool isAddDisabled;
  final BudgetCulprit? overallCulprit;
  final VoidCallback onAddCategory;

  const ShoppingListDetailTotal({
    super.key,
    required this.total,
    this.budgetLimit,
    required this.accentColor,
    this.isEditMode = true,
    this.isAddDisabled = false,
    this.overallCulprit,
    required this.onAddCategory,
  });

  bool get _hasLimit => budgetLimit != null && budgetLimit! > 0;
  bool get _isUnderBudget => _hasLimit && total <= budgetLimit!;
  bool get _isOverBudget => _hasLimit && total > budgetLimit!;

  Color _totalColor(BuildContext context) {
    if (!_hasLimit) return accentColor;
    return _isUnderBudget ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat('#,###');
    final color = _totalColor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'KES ${currencyFormatter.format(total)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    if (_hasLimit) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _isUnderBudget
                                  ? 'Under by KES ${currencyFormatter.format(budgetLimit! - total)}'
                                  : 'Over by KES ${currencyFormatter.format(total - budgetLimit!)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Limit: KES ${currencyFormatter.format(budgetLimit!)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isEditMode)
                FloatingActionButton.small(
                  heroTag: 'add-shopping-category',
                  onPressed: isAddDisabled ? null : onAddCategory,
                  backgroundColor:
                      isAddDisabled ? Colors.grey.shade400 : accentColor,
                  foregroundColor: Colors.white,
                  tooltip: isAddDisabled
                      ? 'Total budget limit reached'
                      : 'Add Category',
                  child: const Icon(Icons.add),
                ),
            ],
          ),
          if (_isOverBudget && overallCulprit != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.balance,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Likeliest culprit: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text:
                                    '${overallCulprit!.item.name.isEmpty ? "Unnamed Item" : overallCulprit!.item.name} (${overallCulprit!.categoryName})',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          overallCulprit!.recommendation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
