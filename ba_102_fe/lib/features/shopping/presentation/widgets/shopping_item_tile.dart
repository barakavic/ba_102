import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingListItemModel item;
  final Color listColor;
  final VoidCallback onToggle;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.listColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBought = item.isBought;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isBought ? listColor : Colors.transparent,
            border: Border.all(
              color: isBought ? listColor : listColor.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: isBought
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
      ),
      title: Text(
        item.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: isBought ? TextDecoration.lineThrough : null,
          color: isBought
              ? theme.colorScheme.onSurface.withOpacity(0.4)
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: item.estimatedPrice > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isBought
                      ? listColor.withOpacity(0.5)
                      : theme.colorScheme.outline.withOpacity(0.4),
                  style: isBought ? BorderStyle.solid : BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'KES ${NumberFormat('#,###').format(item.estimatedPrice)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isBought
                      ? listColor
                      : theme.colorScheme.onSurface.withOpacity(0.55),
                  decoration: isBought ? TextDecoration.lineThrough : null,
                ),
              ),
            )
          : null,
    );
  }
}
