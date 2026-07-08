import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/providers/shopping_list_provider.dart';
import 'package:ba_102_fe/providers/shopping_list_item_provider.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_card.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/create_list_dialog.dart';
import 'package:ba_102_fe/features/shopping/presentation/shopping_list_details_page.dart';

class ShoppingListsPage extends ConsumerStatefulWidget {
  const ShoppingListsPage({super.key});

  @override
  ConsumerState<ShoppingListsPage> createState() => _ShoppingListsPageState();
}

class _ShoppingListsPageState extends ConsumerState<ShoppingListsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
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
        content: Text('Are you sure you want to delete ${_selectedIds.length} list(s)?'),
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
      await ref.read(shoppingListsProvider.notifier).deleteList(_selectedIds.toList());
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

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(_isSelectionMode ? '${_selectedIds.length} Selected' : 'Shopping Lists'),
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
            return const Center(child: Text('No shopping lists yet. Add one below!'));
          }

          return ListView.builder(
            controller: _scrollController,
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              final listId = list.id ?? '';
              final isSelected = _selectedIds.contains(listId);

              return Consumer(
                builder: (context, ref, child) {
                  final itemsAsync = ref.watch(shoppingListItemsProvider(listId));
                  return itemsAsync.maybeWhen(
                    data: (items) {
                      final total = items.length;
                      final bought = items.where((i) => i.isBought).length;
                      return ShoppingListCard(
                        list: list,
                        totalItems: total,
                        boughtItems: bought,
                        isSelected: isSelected,
                        isSelectionMode: _isSelectionMode,
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(listId);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShoppingListDetailsPage(list: list),
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _selectedIds.add(listId);
                            });
                          }
                        },
                      );
                    },
                    orElse: () => const SizedBox(height: 80),
                  );
                },
              );
            },
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
}
