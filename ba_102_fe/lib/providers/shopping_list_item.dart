import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/providers/shopping_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class ShoppingListItemProvider extends FamilyAsyncNotifier<List<ShoppingListItemModel>, String>{
  @override
  Future<List<ShoppingListItemModel>> build(String listId) async{
    final service = await ref.watch(shoppingLsProvider.future);
    return await service.getItemsForShoppingList(listId);

  }

  Future<void> deleteShoppingItem(List<String> id) async{
    final service = await ref.read(shoppingLsProvider.future);
    await service.deleteShoppingListItem(id);

    ref.invalidateSelf();
    
  }

  Future<void> updateShoppingListItem(ShoppingListItemModel item) async{
    final service = await ref.read(shoppingLsProvider.future);
    await service.updateListItem(item);

    ref.invalidateSelf();
  }
} 

final shoppingListItemsProvider = AsyncNotifierProvider.family<ShoppingListItemProvider, List<ShoppingListItemModel>, String>(
(){
  return ShoppingListItemProvider();
}
);