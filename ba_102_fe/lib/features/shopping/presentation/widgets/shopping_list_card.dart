import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:flutter/material.dart';

class ShoppingListCard extends StatelessWidget {
  final ShoppingListModel list;
  final int totalItems;
  final int boughtItems;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ShoppingListCard({
    super.key,
    required this.list,
    required this.totalItems,
    required this.boughtItems,
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

  double get _progress => totalItems == 0 ? 0.0 : boughtItems / totalItems;

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
              ? _listColor.withOpacity(0.12)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _listColor : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 4,
                      backgroundColor: _listColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(_listColor),
                    ),
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
              const SizedBox(width: 16),
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
                      '$boughtItems of $totalItems items',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
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
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
