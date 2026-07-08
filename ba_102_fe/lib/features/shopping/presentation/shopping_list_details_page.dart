import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/providers/shopping_list_item_provider.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_item_tile.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_total_bar.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/add_item_row.dart';

class ShoppingListDetailsPage extends ConsumerStatefulWidget {
  final ShoppingListModel list;

  const ShoppingListDetailsPage({super.key, required this.list});

  @override
  ConsumerState<ShoppingListDetailsPage> createState() => _ShoppingListDetailsPageState();
}

class _ShoppingListDetailsPageState extends ConsumerState<ShoppingListDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _showFAB = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_checkScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _checkScroll() {
    if (!_scrollController.hasClients) return;
    final hasOverflow = _scrollController.position.maxScrollExtent > 0;
    if (hasOverflow != _showFAB) {
      setState(() {
        _showFAB = hasOverflow;
      });
    }
  }

  Color get _listColor {
    if (widget.list.colorSwatch != null) {
      return Color(widget.list.colorSwatch!);
    }
    return const Color(0xFF4B0082);
  }

  Future<void> _addItem(String name, double? price) async {
    final newItem = ShoppingListItemModel(
      id: const Uuid().v4(),
      listId: widget.list.id ?? '',
      name: name,
      estimatedPrice: price ?? 0.0,
      quantity: 1,
      isBought: false,
    );
    await ref.read(shoppingListItemsProvider(widget.list.id!).notifier).createShoppingListItem(newItem);
    
    // Post frame check to update FAB visibility if layout changes
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());
  }

  Future<void> _toggleItem(ShoppingListItemModel item) async {
    final updated = item.copyWith(isBought: !item.isBought);
    await ref.read(shoppingListItemsProvider(widget.list.id!).notifier).updateShoppingListItem(updated);
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => _FABAddItemDialog(
        listColor: _listColor,
        onAdd: (name, price) {
          _addItem(name, price);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(shoppingListItemsProvider(widget.list.id!));

    // Perform check after frame is rendered to see if screen overflows
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScroll());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.title ?? 'List Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: itemsAsync.when(
        data: (items) {
          final estimatedTotal = items.fold<double>(0.0, (sum, item) => sum + (item.estimatedPrice * item.quantity));

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: items.length + (_showFAB ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index < items.length) {
                      final item = items[index];
                      return ShoppingItemTile(
                        item: item,
                        listColor: _listColor,
                        onToggle: () => _toggleItem(item),
                      );
                    } else {
                      return AddItemRow(
                        listColor: _listColor,
                        onAdd: _addItem,
                      );
                    }
                  },
                ),
              ),
              ShoppingTotalBar(
                estimatedTotal: estimatedTotal,
                listColor: _listColor,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: _showFAB
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: _listColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _FABAddItemDialog extends StatefulWidget {
  final Color listColor;
  final void Function(String name, double? price) onAdd;

  const _FABAddItemDialog({required this.listColor, required this.onAdd});

  @override
  State<_FABAddItemDialog> createState() => _FABAddItemDialogState();
}

class _FABAddItemDialogState extends State<_FABAddItemDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Item name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: 'Estimated price (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              final price = double.tryParse(_priceController.text.trim());
              widget.onAdd(name, price);
            }
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(backgroundColor: widget.listColor),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
