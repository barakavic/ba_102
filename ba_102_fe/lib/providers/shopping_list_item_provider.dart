
import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/providers/shopping_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ShoppingListItemProvider extends FamilyAsyncNotifier<List<ShoppingListItemModel>, String>{
  @override
  Future<List<ShoppingListItemModel>> build(String listId) async{
    final service = await ref.watch(shoppingLsProvider.future);
    return await service.getItemsForShoppingList(listId);

  }

  Future<void> createShoppingListItem(ShoppingListItemModel shoppingItem) async{
    final service = await ref.read(shoppingLsProvider.future);

    await service.createShoppingListItem(shoppingItem);

    ref.invalidate(shoppingListSummariesProvider);
    ref.invalidateSelf();
  }

  Future<void> deleteShoppingItem(List<String> id) async{
    final service = await ref.read(shoppingLsProvider.future);
    await service.deleteShoppingListItem(id);

    ref.invalidate(shoppingListSummariesProvider);
    ref.invalidateSelf();
    
  }

  Future<void> updateShoppingListItem(ShoppingListItemModel item) async{
    final service = await ref.read(shoppingLsProvider.future);
    await service.updateListItem(item);

    ref.invalidate(shoppingListSummariesProvider);
    ref.invalidateSelf();
  }

  Future<void> saveItemsForList(
    String listId,
    List<ShoppingListItemModel> items,
  ) async {
    final service = await ref.read(shoppingLsProvider.future);
    await service.saveItemsForList(listId, items);
    ref.invalidate(shoppingListSummariesProvider);
    ref.invalidateSelf();
  }
} 

final shoppingListItemsProvider = AsyncNotifierProvider.family<ShoppingListItemProvider, List<ShoppingListItemModel>, String>(
(){
  return ShoppingListItemProvider();
}
);