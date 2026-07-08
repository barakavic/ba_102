import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingTotalBar extends StatelessWidget {
  final double estimatedTotal;
  final Color listColor;

  const ShoppingTotalBar({
    super.key,
    required this.estimatedTotal,
    required this.listColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.15)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Estimated Total',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            'KES ${NumberFormat('#,###').format(estimatedTotal)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: listColor,
            ),
          ),
        ],
      ),
    );
  }
}
