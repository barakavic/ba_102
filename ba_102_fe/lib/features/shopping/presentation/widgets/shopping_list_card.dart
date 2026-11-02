import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingListCard extends StatelessWidget {
  final ShoppingListModel list;
  final int totalItems;
  final int boughtItems;
  final double? totalCost;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ShoppingListCard({
    super.key,
    required this.list,
    required this.totalItems,
    required this.boughtItems,
    this.totalCost,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  Color get _listColor {
    if (list.colorSwatch != null) {
      return Color(list.colorSwatch!);
    }
    return const Color(0xFF4B0082);
  }

  double get _progress => totalItems == 0 ? 0.0 : (boughtItems / totalItems).clamp(0.0, 1.0);

  bool get _isComplete => totalItems > 0 && boughtItems >= totalItems;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? _listColor.withValues(alpha: 0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _listColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // 1. Leading progress indicator
              SizedBox(
                width: 46,
                height: 46,
                child: totalItems == 0
                    ? Container(
                        decoration: BoxDecoration(
                          color: _listColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: _listColor.withValues(alpha: 0.7),
                          size: 22,
                        ),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 4,
                            backgroundColor: _listColor.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(_listColor),
                          ),
                          if (_isComplete)
                            Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: _listColor,
                            )
                          else
                            Text(
                              '$boughtItems',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _listColor,
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(width: 14),

              // 2. Title & subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.title ?? 'Untitled List',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalItems == 0
                          ? '0 items'
                          : '$boughtItems of $totalItems bought',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Total Cost / Budget badge
              if (totalCost != null && totalCost! > 0) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'KES ${NumberFormat('#,###').format(totalCost!.toInt())}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _listColor,
                      ),
                    ),
                    if (list.budgetLimit != null && list.budgetLimit! > 0)
                      Text(
                        'limit ${NumberFormat('#,###').format(list.budgetLimit!.toInt())}',
                        style: TextStyle(
                          fontSize: 10,
                          color: totalCost! > list.budgetLimit!
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: totalCost! > list.budgetLimit!
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
              ],

              // 4. Selection Checkbox or Chevron
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isSelectionMode
                    ? Checkbox(
                        key: const ValueKey('checkbox'),
                        value: isSelected,
                        activeColor: _listColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (_) => onTap(),
                      )
                    : Icon(
                        Icons.chevron_right_rounded,
                        key: const ValueKey('arrow'),
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
