import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detaiil_category.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShoppingListFilterResult {
  final Set<String> categoryIds; // Empty means all categories
  final RangeValues? priceRange; // Null means no price filter

  const ShoppingListFilterResult({
    required this.categoryIds,
    this.priceRange,
  });

  bool get isActive => categoryIds.isNotEmpty || priceRange != null;
}

class ShoppingListFilterSheet extends StatefulWidget {
  final List<CategoryDraft> categories;
  final Set<String> initialCategoryIds;
  final RangeValues? initialPriceRange;
  final double maxExistentPrice;
  final Color accentColor;
  final ValueChanged<ShoppingListFilterResult> onApply;

  const ShoppingListFilterSheet({
    super.key,
    required this.categories,
    required this.initialCategoryIds,
    this.initialPriceRange,
    required this.maxExistentPrice,
    required this.accentColor,
    required this.onApply,
  });

  @override
  State<ShoppingListFilterSheet> createState() =>
      _ShoppingListFilterSheetState();
}

class _ShoppingListFilterSheetState extends State<ShoppingListFilterSheet> {
  late Set<String> _selectedCategoryIds;
  late double _maxSliderLimit;
  RangeValues? _currentPriceRange;
  final NumberFormat _currencyFormatter = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = Set.from(widget.initialCategoryIds);

    // Limit slider strictly between 0 and highest existent price
    _maxSliderLimit =
        widget.maxExistentPrice > 0 ? widget.maxExistentPrice : 1000.0;

    if (widget.initialPriceRange != null) {
      final start = widget.initialPriceRange!.start.clamp(0.0, _maxSliderLimit);
      final end = widget.initialPriceRange!.end.clamp(start, _maxSliderLimit);
      _currentPriceRange = RangeValues(start, end);
    } else {
      _currentPriceRange = RangeValues(0.0, _maxSliderLimit);
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryIds.clear();
      _currentPriceRange = RangeValues(0.0, _maxSliderLimit);
    });
  }

  void _toggleCategory(String catId) {
    setState(() {
      if (_selectedCategoryIds.contains(catId)) {
        _selectedCategoryIds.remove(catId);
      } else {
        _selectedCategoryIds.add(catId);
      }
    });
  }

  void _selectAllCategories() {
    setState(() {
      _selectedCategoryIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.accentColor;
    final hasExistentPrices = widget.maxExistentPrice > 0;

    final isPriceFiltered = _currentPriceRange != null &&
        (_currentPriceRange!.start > 0 ||
            _currentPriceRange!.end < _maxSliderLimit);

    final isAllCategories = _selectedCategoryIds.isEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header: Title + Reset Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.filter_list_rounded,
                      color: accentColor, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Filter Items',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _resetFilters,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Categories Section
          Text(
            'Categories',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "All" Chip
                FilterChip(
                  label: const Text('All Categories'),
                  selected: isAllCategories,
                  onSelected: (_) => _selectAllCategories(),
                  selectedColor: accentColor.withValues(alpha: 0.2),
                  checkmarkColor: accentColor,
                  labelStyle: TextStyle(
                    fontWeight: isAllCategories ? FontWeight.bold : FontWeight.w500,
                    color: isAllCategories ? accentColor : null,
                  ),
                ),
                const SizedBox(width: 8),

                // Individual Category Chips
                ...widget.categories.map((cat) {
                  final isSelected = _selectedCategoryIds.contains(cat.id);
                  final catName =
                      cat.name.trim().isEmpty ? 'Untitled' : cat.name.trim();

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: CircleAvatar(
                        backgroundColor: cat.color,
                        radius: 5,
                      ),
                      label: Text(catName),
                      selected: isSelected,
                      onSelected: (_) => _toggleCategory(cat.id),
                      selectedColor: cat.color.withValues(alpha: 0.25),
                      checkmarkColor: cat.color,
                      labelStyle: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? cat.color : null,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Price Range Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price Range',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              if (hasExistentPrices && _currentPriceRange != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPriceFiltered
                        ? accentColor.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'KES ${_currencyFormatter.format(_currentPriceRange!.start.toInt())} — KES ${_currencyFormatter.format(_currentPriceRange!.end.toInt())}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isPriceFiltered ? accentColor : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (!hasExistentPrices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'All items are currently KES 0. Add prices to filter by range.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            RangeSlider(
              values: _currentPriceRange ?? RangeValues(0.0, _maxSliderLimit),
              min: 0.0,
              max: _maxSliderLimit,
              activeColor: accentColor,
              inactiveColor: accentColor.withValues(alpha: 0.2),
              labels: RangeLabels(
                'KES ${_currencyFormatter.format(_currentPriceRange!.start.toInt())}',
                'KES ${_currencyFormatter.format(_currentPriceRange!.end.toInt())}',
              ),
              onChanged: (values) {
                setState(() {
                  _currentPriceRange = values;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KES 0',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    'Max: KES ${_currencyFormatter.format(_maxSliderLimit.toInt())}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    // Check if price range is non-default
                    final priceFilter = (hasExistentPrices &&
                            _currentPriceRange != null &&
                            (_currentPriceRange!.start > 0 ||
                                _currentPriceRange!.end < _maxSliderLimit))
                        ? _currentPriceRange
                        : null;

                    widget.onApply(
                      ShoppingListFilterResult(
                        categoryIds: _selectedCategoryIds,
                        priceRange: priceFilter,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

