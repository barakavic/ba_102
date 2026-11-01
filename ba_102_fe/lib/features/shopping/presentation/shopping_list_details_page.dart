import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detail_appbar.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detail_total.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detaiil_category.dart';
import 'package:ba_102_fe/providers/shopping_list_item_provider.dart';
import 'package:ba_102_fe/providers/shopping_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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

    // Dispose and clear any stale categories (e.g. from a previous load / pull-to-refresh)
    for (final cat in _categories) {
      cat.dispose();
    }
    _categories.clear();

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
        _hasUnsavedChanges = true;
      } else {
        // In View Mode: bought tracking with strikethrough
        item.isBought = !item.isBought;
      }
    });

    if (!_isEditMode) {
      _persistItemBoughtStatus(item);
    }
  }

  Future<void> _persistItemBoughtStatus(CategoryItemDraft item) async {
    final listId = widget.list.id;
    if (listId == null) return;
    try {
      final service = await ref.read(shoppingLsProvider.future);
      await service.updateListItem(
        ShoppingListItemModel(
          id: item.id,
          listId: listId,
          name: item.name,
          estimatedPrice: item.price,
          quantity: item.quantity.toInt(),
          isBought: item.isBought,
          brand: item.brand,
          expiryDate: item.expiryDate,
          volume: item.volume,
        ),
      );
    } catch (_) {}
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

  void _deleteCategory(CategoryDraft category) {
    setState(() {
      category.dispose();
      _categories.remove(category);
      _hasUnsavedChanges = true;
    });
  }

  void _setCategoryBudget(CategoryDraft category, double budget) {
    setState(() {
      category.categoryBudget = budget > 0 ? budget : null;
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    final listId = widget.list.id;
    if (listId == null) return;

    // 1. Discard empty item rows
    for (final category in _categories) {
      category.items.removeWhere((item) {
        final isBlank = item.name.isEmpty && item.price == 0;
        if (isBlank) item.dispose();
        return isBlank;
      });
    }

    // 2. Discard empty categories (no name AND no items)
    _categories.removeWhere((cat) {
      final isEmpty = cat.items.isEmpty && cat.name.isEmpty;
      if (isEmpty) cat.dispose();
      return isEmpty;
    });

    // 3. Build model list from drafts
    final allItems = <ShoppingListItemModel>[];
    for (final category in _categories) {
      for (final item in category.items) {
        allItems.add(
          ShoppingListItemModel(
            id: item.id,
            listId: listId,
            name: item.name,
            category: category.name.isNotEmpty ? category.name : null,
            estimatedPrice: item.price,
            quantity: item.quantity.toInt(),
            isBought: item.isBought,
          ),
        );
      }
    }

    // 4. Clear multi-selections optimistically
    setState(() {
      for (final cat in _categories) {
        for (final i in cat.items) {
          i.isSelected = false;
        }
      }
      _hasUnsavedChanges = false;
      _isEditMode = false;
    });

    // 5. Persist to DB
    try {
      await ref
          .read(shoppingListItemsProvider(listId).notifier)
          .saveItemsForList(listId, allItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('List saved successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Roll back UI flags so user can retry
      setState(() {
        _hasUnsavedChanges = true;
        _isEditMode = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  Future<void> _handleRefresh() async {
    final listId = widget.list.id;
    if (listId != null) {
      _hasInitializedFromDb = false;
      ref.invalidate(shoppingListItemsProvider(listId));
      await ref.read(shoppingListItemsProvider(listId).future);
    }
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
        onMore: _showListOptionsMenu,
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
              // 1. Pinned Total Header with Category (+) FAB (hidden in view mode)
              ShoppingListDetailTotal(
                total: currentTotal,
                budgetLimit: widget.list.budgetLimit,
                accentColor: _listColor,
                isEditMode: _isEditMode,
                onAddCategory: _addCategory,
              ),

              // 2. Category Containers with Pull to Refresh
              Expanded(
                child: RefreshIndicator(
                  color: _listColor,
                  onRefresh: _handleRefresh,
                  child: visibleCategories.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: Center(
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
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
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
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 88),
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
                              onDeleteCategory: () => _deleteCategory(category),
                              onEditCategory: _toggleEditMode,
                              onSetBudget: (v) => _setCategoryBudget(category, v),
                              onItemChanged: () {
                                setState(() {
                                  _hasUnsavedChanges = true;
                                });
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
        error: (err, st) => Center(child: Text('Error: $err')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: (_isEditMode && _hasUnsavedChanges)
          ? FloatingActionButton.extended(
              heroTag: 'save-shopping-list-fab',
              onPressed: _saveChanges,
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              backgroundColor: _listColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _shareTemplate() async {
    final buffer = StringBuffer();
    buffer.writeln('🛒 ${widget.list.title ?? "Shopping List"}');

    final currentTotal = _categories.fold<double>(
      0.0,
      (sum, category) => sum + category.total,
    );
    final formatter = NumberFormat('#,###');
    buffer.writeln('Total: KES ${formatter.format(currentTotal)}\n');

    for (final category in _categories) {
      final catName =
          category.name.trim().isEmpty ? 'General' : category.name.trim();
      buffer.writeln('📁 $catName');
      for (final item in category.items) {
        final itemName =
            item.name.trim().isEmpty ? 'Untitled Item' : item.name.trim();
        final qtyStr = item.quantity == item.quantity.toInt()
            ? item.quantity.toInt().toString()
            : item.quantity.toString();

        final details = <String>[];
        if (item.brand != null && item.brand!.isNotEmpty) details.add(item.brand!);
        if (item.volume != null && item.volume!.isNotEmpty) details.add(item.volume!);
        final detailStr = details.isNotEmpty ? ' (${details.join(", ")})' : '';

        final priceStr =
            item.total > 0 ? ' - KES ${formatter.format(item.total)}' : '';
        buffer.writeln('  • $itemName x$qtyStr$detailStr$priceStr');
      }
      buffer.writeln();
    }

    final text = buffer.toString().trim();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shopping list template copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDuplicateDialog() {
    final titleController = TextEditingController(
      text: 'Copy of ${widget.list.title ?? "Shopping List"}',
    );
    Color selectedColor = _listColor;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Duplicate Template',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create a fresh copy of this shopping list with all categories and items reset to unbought.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'New list title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color swatch',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoryColorPalette.map((color) {
                      final isSelected = color.value == selectedColor.value;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedColor = color),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: selectedColor),
                  onPressed: () async {
                    final newTitle = titleController.text.trim();
                    if (newTitle.isEmpty) return;
                    Navigator.pop(ctx);
                    await _executeDuplicateList(newTitle, selectedColor);
                  },
                  child: const Text('Duplicate'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeDuplicateList(String newTitle, Color color) async {
    try {
      final newListId = const Uuid().v4();
      final newList = ShoppingListModel(
        id: newListId,
        title: newTitle,
        colorSwatch: color.value,
        budgetLimit: widget.list.budgetLimit,
        isTemporary: widget.list.isTemporary,
        createdAt: DateTime.now(),
      );

      // 1. Create list in DB
      await ref.read(shoppingListsProvider.notifier).createList(newList);

      // 2. Clone all items
      final clonedItems = <ShoppingListItemModel>[];
      for (final category in _categories) {
        for (final item in category.items) {
          if (item.name.trim().isEmpty && item.price == 0) continue;
          clonedItems.add(
            ShoppingListItemModel(
              id: const Uuid().v4(),
              listId: newListId,
              name: item.name,
              category:
                  category.name.trim().isNotEmpty ? category.name.trim() : null,
              estimatedPrice: item.price,
              quantity: item.quantity.toInt(),
              isBought: false, // Reset to unbought
              brand: item.brand,
              expiryDate: item.expiryDate,
              volume: item.volume,
            ),
          );
        }
      }

      // 3. Save items to DB
      final service = await ref.read(shoppingLsProvider.future);
      await service.saveItemsForList(newListId, clonedItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created "$newTitle" with ${clonedItems.length} items'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShoppingListDetailsPage(list: newList),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate list: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showListOptionsMenu() {
    final theme = Theme.of(context);
    final listTitle = widget.list.title ?? 'Shopping List';
    final totalItems =
        _categories.fold<int>(0, (sum, c) => sum + c.items.length);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Colored banner header
              Container(
                decoration: BoxDecoration(
                  color: _listColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.list_alt_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_categories.length} categories • $totalItems items',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Action tiles
              _ListActionTile(
                icon: Icons.copy_outlined,
                label: 'Share template',
                sub: 'Copy formatted text template to clipboard',
                iconColor: _listColor,
                onTap: () {
                  Navigator.pop(ctx);
                  _shareTemplate();
                },
              ),
              _ListActionTile(
                icon: Icons.copy_all_outlined,
                label: 'Copy template to new list',
                sub: 'Create a separate copy with all items reset',
                iconColor: _listColor,
                onTap: () {
                  Navigator.pop(ctx);
                  _showDuplicateDialog();
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _ListActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Color iconColor;
  final VoidCallback onTap;

  const _ListActionTile({
    required this.icon,
    required this.label,
    this.sub,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
