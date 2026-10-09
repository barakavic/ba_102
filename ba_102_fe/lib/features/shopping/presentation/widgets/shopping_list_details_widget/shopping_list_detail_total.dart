import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingListDetailTotal extends StatelessWidget {
  final double total;
  final double? budgetLimit;
  final Color accentColor;
  final VoidCallback onAddCategory;

  const ShoppingListDetailTotal({
    super.key,
    required this.total,
    this.budgetLimit,
    required this.accentColor,
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
      child: Row(
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
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
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
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          FloatingActionButton.small(
            heroTag: 'add-shopping-category',
            onPressed: onAddCategory,
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
            tooltip: 'Add Category',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

