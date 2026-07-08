import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/shopping_ls.dart';
import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

 final shoppingLsProvider = FutureProvider<ShoppingLs>((ref) async{
    try {
       final db =  await DatabaseHelper.instance.database;
      return ShoppingLs(db);
      
      
    } catch (e) {
      AppLogger.e('Failed to instanciate the Provider', error: e);
      rethrow;
      
    }

  });

  class ShoppingListNotifier extends AsyncNotifier<List<ShoppingListModel>>
  {
    int _offset = 0;

  @override
  Future <List<ShoppingListModel>> build() async{
    final service = await ref.watch(shoppingLsProvider.future);
    _offset = 0;
    return await service.getShoppingLists(limit: 20, offset: _offset);
  } 

  Future<void> createList(ShoppingListModel list) async{
    final service = await ref.read(shoppingLsProvider.future);

    await service.createShoppingList(list);

    ref.invalidateSelf();
  }



  Future<void> updateList(ShoppingListModel updatedList)async{
    final service = await ref.read(shoppingLsProvider.future);
    await service.updateList(updatedList);
    ref.invalidateSelf();
  }

  Future<void> deleteList(List<String> listId) async{
    final service = await ref.read(shoppingLsProvider.future);
    await service.deleteShoppingList(listId);

    ref.invalidateSelf();
    
  }
  

  Future<void> clearAllLists() async{
    final service = await ref.read(shoppingLsProvider.future);
    await service.clearAllLists();

    ref.invalidateSelf();
  }

    Future<void> loadMore() async{
    final service = await ref.read(shoppingLsProvider.future);

    _offset+=20;

    final nextBatch = await service.getShoppingLists(limit: 20, offset: _offset);

    final currentList = state.value ?? [];

    state = AsyncData([...currentList, ...nextBatch]);

  }
  }

  

  final shoppingListsProvider = AsyncNotifierProvider<ShoppingListNotifier, List<ShoppingListModel>>((){
    return ShoppingListNotifier();

  });

  

  
