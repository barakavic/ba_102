import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/providers/shopping_list_provider.dart';
import 'package:ba_102_fe/providers/shopping_list_item_provider.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_card.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/create_list_dialog.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_sort_sheet.dart';
import 'package:ba_102_fe/features/shopping/presentation/shopping_list_details_page.dart';

class ShoppingListsPage extends ConsumerStatefulWidget {
  const ShoppingListsPage({super.key});

  @override
  ConsumerState<ShoppingListsPage> createState() => _ShoppingListsPageState();
}

class _ShoppingListsPageState extends ConsumerState<ShoppingListsPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  String _searchQuery = '';

  ShoppingListSortOption _sortOption = const ShoppingListSortOption(
    ShoppingListSortField.dateCreated,
    SortOrder.descending,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(shoppingListsProvider.notifier).loadMore();
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelectedLists() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lists'),
        content: Text(
          'Are you sure you want to delete ${_selectedIds.length} list(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(shoppingListsProvider.notifier)
          .deleteList(_selectedIds.toList());
      _exitSelectionMode();
    }
  }

  Future<void> _showCreateDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateListDialog(),
    );

    if (result != null) {
      final newList = ShoppingListModel(
        id: const Uuid().v4(),
        title: result['title'],
        colorSwatch: result['color'],
        isTemporary: false,
        createdAt: DateTime.now(),
      );
      await ref.read(shoppingListsProvider.notifier).createList(newList);
    }
  }

  void _openSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShoppingListSortSheet(
        currentOption: _sortOption,
        onSelected: (option) {
          setState(() {
            _sortOption = option;
          });
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(shoppingListsProvider);
    ref.invalidate(shoppingListSummariesProvider);
    await ref.read(shoppingListsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listsAsync = ref.watch(shoppingListsProvider);
    final summariesAsync = ref.watch(shoppingListSummariesProvider);
    final summaries = summariesAsync.value ?? const {};

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(
          _isSelectionMode
              ? '${_selectedIds.length} Selected'
              : 'Shopping Lists',
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteSelectedLists,
            ),
        ],
      ),
      body: listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No shopping lists yet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button below to create your first shopping list.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 1. Filter by search query
          final filteredLists = lists.where((list) {
            if (_searchQuery.trim().isEmpty) return true;
            final query = _searchQuery.trim().toLowerCase();
            final title = (list.title ?? '').toLowerCase();
            return title.contains(query);
          }).toList();

          // 2. Sort lists based on selected option
          filteredLists.sort((a, b) {
            switch (_sortOption.field) {
              case ShoppingListSortField.dateCreated:
                final dateA =
                    a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                final dateB =
                    b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                return _sortOption.order == SortOrder.descending
                    ? dateB.compareTo(dateA)
                    : dateA.compareTo(dateB);
              case ShoppingListSortField.name:
                final nameA = (a.title ?? '').toLowerCase();
                final nameB = (b.title ?? '').toLowerCase();
                return _sortOption.order == SortOrder.ascending
                    ? nameA.compareTo(nameB)
                    : nameB.compareTo(nameA);
              case ShoppingListSortField.totalCost:
                final costA = summaries[a.id]?.totalCost ?? 0.0;
                final costB = summaries[b.id]?.totalCost ?? 0.0;
                return _sortOption.order == SortOrder.descending
                    ? costB.compareTo(costA)
                    : costA.compareTo(costB);
            }
          });

          return Column(
            children: [
              // Dedicated Header ABOVE the list: Search Bar & Sort Button
              if (!_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: theme.colorScheme.outline
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search lists...',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Sort Button
                      Material(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(24),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _openSortSheet,
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.colorScheme.outline
                                    .withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _sortOption.icon,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sort',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Active Sort / Results Indicator (when filtering or not default sort)
              if (!_isSelectionMode &&
                  (_searchQuery.isNotEmpty ||
                      _sortOption.field != ShoppingListSortField.dateCreated ||
                      _sortOption.order != SortOrder.descending))
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: Row(
                    children: [
                      Text(
                        '${filteredLists.length} list${filteredLists.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _sortOption.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Main List View with Pull to Refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: filteredLists.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 48,
                                        color: theme.colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No shopping lists found',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'No lists match "$_searchQuery".',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchQuery = '';
                                          });
                                        },
                                        child: const Text('Clear search'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredLists.length,
                          itemBuilder: (context, index) {
                            final list = filteredLists[index];
                            final listId = list.id ?? '';
                            final isSelected = _selectedIds.contains(listId);
                            final summary = summaries[listId];

                            // If summary is available from SQL aggregation, use it directly.
                            // Otherwise fallback to watching the individual list items provider.
                            if (summary != null) {
                              return ShoppingListCard(
                                list: list,
                                totalItems: summary.totalItems,
                                boughtItems: summary.boughtItems,
                                totalCost: summary.totalCost,
                                isSelected: isSelected,
                                isSelectionMode: _isSelectionMode,
                                onTap: () => _handleCardTap(list, listId),
                                onLongPress: () =>
                                    _handleCardLongPress(listId),
                              );
                            }

                            return Consumer(
                              builder: (context, ref, child) {
                                final itemsAsync = ref
                                    .watch(shoppingListItemsProvider(listId));
                                return itemsAsync.maybeWhen(
                                  data: (items) {
                                    final total = items.length;
                                    final bought = items
                                        .where((i) => i.isBought)
                                        .length;
                                    final cost = items.fold<double>(
                                      0.0,
                                      (sum, i) =>
                                          sum +
                                          (i.estimatedPrice *
                                              (i.quantity > 0
                                                  ? i.quantity
                                                  : 1)),
                                    );
                                    return ShoppingListCard(
                                      list: list,
                                      totalItems: total,
                                      boughtItems: bought,
                                      totalCost: cost,
                                      isSelected: isSelected,
                                      isSelectionMode: _isSelectionMode,
                                      onTap: () =>
                                          _handleCardTap(list, listId),
                                      onLongPress: () =>
                                          _handleCardLongPress(listId),
                                    );
                                  },
                                  orElse: () => const SizedBox(height: 80),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _showCreateDialog,
              child: const Icon(Icons.add),
            ),
    );
  }

  void _handleCardTap(ShoppingListModel list, String listId) {
    if (_isSelectionMode) {
      _toggleSelection(listId);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShoppingListDetailsPage(list: list),
        ),
      ).then((_) {
        // Refresh summaries and lists when returning from details page
        ref.invalidate(shoppingListSummariesProvider);
      });
    }
  }

  void _handleCardLongPress(String listId) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedIds.add(listId);
      });
    }
  }
}
