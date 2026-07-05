import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/shopping_ls.dart';
import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqlite_api.dart';

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

  @override
  Future <List<ShoppingListModel>> build() async{
    final service = await ref.read(shoppingLsProvider.future);
    return await service.getShoppingLists();
  } 
  
  }

  final ShoppingListProvider = AsyncNotifierProvider<ShoppingListNotifier, List<ShoppingListModel>>((){
    return ShoppingListNotifier();

  });

  

  
