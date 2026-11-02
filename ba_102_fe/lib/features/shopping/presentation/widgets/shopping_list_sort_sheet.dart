import 'package:flutter/material.dart';

enum ShoppingListSortField {
  dateCreated,
  name,
  totalCost,
}

enum SortOrder {
  ascending,
  descending,
}

class ShoppingListSortOption {
  final ShoppingListSortField field;
  final SortOrder order;

  const ShoppingListSortOption(this.field, this.order);

  String get label {
    switch (field) {
      case ShoppingListSortField.dateCreated:
        return order == SortOrder.descending
            ? 'Date Created (Newest)'
            : 'Date Created (Oldest)';
      case ShoppingListSortField.name:
        return order == SortOrder.ascending ? 'Name (A → Z)' : 'Name (Z → A)';
      case ShoppingListSortField.totalCost:
        return order == SortOrder.descending
            ? 'Total Cost (High → Low)'
            : 'Total Cost (Low → High)';
    }
  }

  IconData get icon {
    switch (field) {
      case ShoppingListSortField.dateCreated:
        return order == SortOrder.descending
            ? Icons.access_time_rounded
            : Icons.history_rounded;
      case ShoppingListSortField.name:
        return Icons.sort_by_alpha_rounded;
      case ShoppingListSortField.totalCost:
        return order == SortOrder.descending
            ? Icons.trending_down_rounded
            : Icons.trending_up_rounded;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingListSortOption &&
          runtimeType == other.runtimeType &&
          field == other.field &&
          order == other.order;

  @override
  int get hashCode => field.hashCode ^ order.hashCode;
}

class ShoppingListSortSheet extends StatelessWidget {
  final ShoppingListSortOption currentOption;
  final ValueChanged<ShoppingListSortOption> onSelected;

  const ShoppingListSortSheet({
    super.key,
    required this.currentOption,
    required this.onSelected,
  });

  static const List<ShoppingListSortOption> options = [
    ShoppingListSortOption(ShoppingListSortField.dateCreated, SortOrder.descending),
    ShoppingListSortOption(ShoppingListSortField.dateCreated, SortOrder.ascending),
    ShoppingListSortOption(ShoppingListSortField.name, SortOrder.ascending),
    ShoppingListSortOption(ShoppingListSortField.name, SortOrder.descending),
    ShoppingListSortOption(ShoppingListSortField.totalCost, SortOrder.descending),
    ShoppingListSortOption(ShoppingListSortField.totalCost, SortOrder.ascending),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.swap_vert_rounded, color: primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Sort Lists',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Sort Options List
              ...options.map((option) {
                final isSelected = option == currentOption;
                return InkWell(
                  onTap: () {
                    onSelected(option);
                    Navigator.pop(context);
                  },
                  child: Container(
                    color: isSelected
                        ? primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          option.icon,
                          size: 20,
                          color: isSelected
                              ? primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

