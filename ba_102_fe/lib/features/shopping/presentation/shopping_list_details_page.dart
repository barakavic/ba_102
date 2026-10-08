import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/providers/shopping_list_item_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ShoppingListDetailsPage extends ConsumerWidget {
  final ShoppingListModel list;

  const ShoppingListDetailsPage({super.key, required this.list});

  Color get _listColor {
    if (list.colorSwatch != null) {
      return Color(list.colorSwatch!);
    }
    return const Color(0xFF4B0082);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listId = list.id;
    final itemsAsync = listId == null
        ? const AsyncValue<List<ShoppingListItemModel>>.data([])
        : ref.watch(shoppingListItemsProvider(listId));

    return Scaffold(
      appBar: AppBar(
        title: Text(list.title ?? 'Shopping List'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: itemsAsync.when(
        data: (items) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: _listColor,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ready for rebuild',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${items.length} existing item(s) are still in local storage.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
