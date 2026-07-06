import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';

class ShoppingLs{
  final Database db;
  ShoppingLs(this.db);

  Future<int> createShoppingList(ShoppingListModel shopping) async{
    try{
    
    final id = await db.insert(
    'shopping_lists', 
    shopping.toMap(), 
    conflictAlgorithm: ConflictAlgorithm.replace
    );

  return id;

    }
    catch(e){
      AppLogger.e('Error Creating, Shopping List: $e');
      rethrow;
   }
  }

  Future<List<ShoppingListModel>> getShoppingLists({int limit = 20, int offset = 0}) async{
    final List<Map<String, dynamic>> maps = await db.query(
      'shopping_lists',
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset
     
    );

    return maps.map((map) => ShoppingListModel.fromMap(map)).toList();


    
  }

  Future<List<ShoppingListItemModel>> getItemsForShoppingList(String listId) async
  {
    try{
      final maps = await db.query(
      'shopping_items',
      where: 'list_id = ?',
      whereArgs: [listId],
    );

    return maps.map((map) => ShoppingListItemModel.fromMap(map)).toList();
}
catch(e, st){
  AppLogger.e('Failed to fetch shopping list items', error: e, stackTrace: st);
  rethrow;
}
  }

  Future<int> updateList(ShoppingListModel list) async{
    try {
      final updateState = await db.update('shopping_lists',
      list.toMap(),
      where: 'id = ?',
      whereArgs: [list.id]
      );

    return updateState;  
    } 

    catch (e, st) {
    AppLogger.e('Failed to update list', error: e, stackTrace: st);
    rethrow;
    }

  }

  Future<int> deleteShoppingList(List<String> listId) async{
   
    try {
      final shoppingListDelStatus = await db.delete('shopping_lists',
      where: 'id IN (${List.filled(listId.length, '?').join(',')})',
      whereArgs: listId
      );

      return shoppingListDelStatus;
      
      
    } 
    catch (e, st) {
      AppLogger.e('Failed to delete list(s)', error: e, stackTrace: st);
      rethrow;
    }
  }
  Future<int> clearAllLists()async{
    try {
      final deleteState = await db.delete('shopping_lists');
      return deleteState;

    } catch (e, st) {
      AppLogger.e('Failed to clear all databases', error: e, stackTrace: st);
      rethrow;
    }
  }

  // List Item Section
  Future<int> updateListItem(ShoppingListItemModel item) async{
    try {
      final updateState = await db.update(
        'shopping_items', 
        item.toMap(),
        where: 'id = ?',
        whereArgs: [item.id]
        );
        return updateState;
    } catch (e, st)
     {
    AppLogger.e('Failed to update List Items', error: e, stackTrace: st); 
    rethrow;
    }
  }

  Future<int> deleteShoppingListItem(List<String> itemIds) async{

    try {
      final deleteStatus = await db.delete('shopping_items', 
      where: 'id IN (${List.filled(itemIds.length, '?').join(',')})',
      whereArgs: itemIds
      );
      return deleteStatus;
      
    } catch (e, st) {
      AppLogger.e('Failed to Delete Shopping List Item', error: e, stackTrace: st);
      rethrow;
      
    }

  }
}

