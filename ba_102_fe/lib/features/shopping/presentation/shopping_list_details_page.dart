import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detail_appbar.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detail_total.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detaiil_category.dart';
import 'package:ba_102_fe/providers/shopping_list_item_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShoppingListDetailsPage extends ConsumerStatefulWidget {
  final ShoppingListModel list;
  const ShoppingListDetailsPage({super.key, required this.list});

  @override
  ConsumerState<ShoppingListDetailsPage> createState() =>
      _ShoppingListDetailsPageState();
}

class _ShoppingListDetailsPageState
    extends ConsumerState<ShoppingListDetailsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<CategoryDraft> _categories = [];
  bool _isSearching = false;
  String _searchQuery = '';
  bool _hasUnsavedChanges = false;
  bool _isEditMode = true;
  bool _hasInitializedFromDb = false;

  Color get _listColor {
    if (widget.list.colorSwatch != null) {
      return Color(widget.list.colorSwatch!);
    }
    return const Color(0xFF4B0082);
  }

  static const List<Color> _categoryColorPalette = [
    Color(0xFF1976D2), // Blue
    Color(0xFF2E7D32), // Green
    Color(0xFFE65100), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFF00796B), // Teal
    Color(0xFFC2185B), // Pink
  ];

  static const List<String> _categorySuggestions = [
    'Food',
    'Toiletries',
    'Household',
    'Snacks',
    'Beverages',
    'Produce',
    'Bakery',
    'Dairy',
    'Personal Care',
    'Cleaning',
  ];

  Color _getCategoryColor(int index) {
    return _categoryColorPalette[index % _categoryColorPalette.length];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (final category in _categories) {
      category.dispose();
    }
    super.dispose();
  }

  void _initCategoriesFromDb(List<ShoppingListItemModel> dbItems) {
    if (_hasInitializedFromDb) return;
    _hasInitializedFromDb = true;

    if (dbItems.isEmpty) return;

    final Map<String, List<ShoppingListItemModel>> grouped = {};
    for (final item in dbItems) {
      final cat = (item.category != null && item.category!.trim().isNotEmpty)
          ? item.category!.trim()
          : 'General';
      grouped.putIfAbsent(cat, () => []).add(item);
    }

    int colorIndex = 0;
    for (final entry in grouped.entries) {
      final categoryDraft = CategoryDraft(
        id: '${DateTime.now().millisecondsSinceEpoch}_${entry.key}',
        name: entry.key,
        color: _getCategoryColor(colorIndex++),
        isSuggested: false,
        items: entry.value.map((item) {
          return CategoryItemDraft(
            id: item.id ?? UniqueKey().toString(),
            name: item.name,
            quantity: item.quantity.toDouble(),
            price: item.estimatedPrice,
            isBought: item.isBought,
          );
        }).toList(),
      );
      _categories.add(categoryDraft);
    }

    // Existing loaded items start in View Mode
    _isEditMode = false;
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (_isSearching) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _searchQuery = '';
        _searchFocusNode.unfocus();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim().toLowerCase();
    });
  }

  void _addCategory() {
    setState(() {
      final existingNames = _categories.map((c) => c.name.toLowerCase()).toSet();

      // Deduplicate suggestions: pick the next non-existing category name
      final chosenName = _categorySuggestions.firstWhere(
        (suggestion) => !existingNames.contains(suggestion.toLowerCase()),
        orElse: () {
          int counter = 1;
          while (existingNames.contains('category $counter'.toLowerCase())) {
            counter++;
          }
          return 'Category $counter';
        },
      );

      final index = _categories.length;
      final newCat = CategoryDraft(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: chosenName,
        color: _getCategoryColor(index),
        isSuggested: true,
        items: [
          CategoryItemDraft(
            id: '${DateTime.now().millisecondsSinceEpoch}_0',
            name: '',
            quantity: 1,
            price: 0,
          ),
        ],
      );
      _categories.add(newCat);
      _hasUnsavedChanges = true;
      _isEditMode = true;
    });
  }

  void _addItemToCategory(CategoryDraft category) {
    setState(() {
      category.items.add(
        CategoryItemDraft(
          id: '${DateTime.now().millisecondsSinceEpoch}_${category.items.length}',
          name: '',
          quantity: 1,
          price: 0,
        ),
      );
      _hasUnsavedChanges = true;
      _isEditMode = true;
    });
  }

  void _toggleItem(CategoryItemDraft item) {
    setState(() {
      if (_isEditMode) {
        // In Edit Mode: multi-selection
        item.isSelected = !item.isSelected;
      } else {
        // In View Mode: bought tracking with strikethrough
        item.isBought = !item.isBought;
      }
      _hasUnsavedChanges = true;
    });
  }

  void _deleteSelectedItems(CategoryDraft category) {
    setState(() {
      category.items.removeWhere((item) {
        if (item.isSelected) {
          item.dispose();
          return true;
        }
        return false;
      });
      _hasUnsavedChanges = true;
    });
  }

  void _saveChanges() {
    setState(() {
      _hasUnsavedChanges = false;
      _isEditMode = false; // Closed edit mode -> enters View Mode
      // Clear any remaining multi-selections
      for (final cat in _categories) {
        for (final item in cat.items) {
          item.isSelected = false;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes Saved Successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final listId = widget.list.id;
    final itemsAsync = listId == null
        ? const AsyncValue<List<ShoppingListItemModel>>.data([])
        : ref.watch(shoppingListItemsProvider(listId));

    return Scaffold(
      appBar: ShoppingListDetailAppBar(
        title: widget.list.title ?? 'Shopping Budget',
        isSearching: _isSearching,
        searchController: _searchController,
        searchFocusNode: _searchFocusNode,
        hasUnsavedChanges: _hasUnsavedChanges,
        isEditMode: _isEditMode,
        onSearchToggle: _toggleSearch,
        onSearchChanged: _onSearchChanged,
        onSave: _saveChanges,
        onToggleEdit: _toggleEditMode,
      ),
      body: itemsAsync.when(
        data: (dbItems) {
          if (!_hasInitializedFromDb) {
            _initCategoriesFromDb(dbItems);
          }

          // Real-time total derived from all categories and items
          final currentTotal = _categories.fold<double>(
            0.0,
            (sum, category) => sum + category.total,
          );

          // Detect duplicate category names (case-insensitive)
          final categoryNameCounts = <String, int>{};
          for (final cat in _categories) {
            final k = cat.name.toLowerCase();
            if (k.isNotEmpty) {
              categoryNameCounts[k] = (categoryNameCounts[k] ?? 0) + 1;
            }
          }
          final duplicateCategoryNames = categoryNameCounts.entries
              .where((e) => e.value > 1)
              .map((e) => e.key)
              .toSet();

          // Filter categories based on search query
          final visibleCategories = _isSearching && _searchQuery.isNotEmpty
              ? _categories.where((cat) {
                  final matchesCat =
                      cat.name.toLowerCase().contains(_searchQuery);
                  final matchesItem = cat.items.any((i) =>
                      i.nameController.text.toLowerCase().contains(_searchQuery));
                  return matchesCat || matchesItem;
                }).toList()
              : _categories;

          return Column(
            children: [
              // 1. Pinned Total Header with Category (+) FAB
              ShoppingListDetailTotal(
                total: currentTotal,
                budgetLimit: widget.list.budgetLimit,
                accentColor: _listColor,
                onAddCategory: _addCategory,
              ),

              // 2. Category Containers
              Expanded(
                child: visibleCategories.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                color: _listColor.withValues(alpha: 0.6),
                                size: 56,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _categories.isEmpty
                                    ? 'No categories yet'
                                    : 'No matching categories found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _categories.isEmpty
                                    ? 'Tap the + button above to add your first category (Food, Toiletries, etc.)'
                                    : 'Try a different search term.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 32),
                        itemCount: visibleCategories.length,
                        itemBuilder: (context, index) {
                          final category = visibleCategories[index];
                          return ShoppingListDetailCategory(
                            key: ValueKey(category.id),
                            category: category,
                            isEditMode: _isEditMode,
                            hasDuplicateCategoryName: duplicateCategoryNames
                                .contains(category.name.toLowerCase()),
                            onAddItem: () => _addItemToCategory(category),
                            onToggleItem: _toggleItem,
                            onToggleCollapse: () {
                              setState(() {
                                category.isCollapsed = !category.isCollapsed;
                              });
                            },
                            onDeleteSelectedItems: () =>
                                _deleteSelectedItems(category),
                            onItemChanged: () {
                              setState(() {
                                _hasUnsavedChanges = true;
                              });
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
        error: (err, st) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}