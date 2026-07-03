import 'package:ba_102_fe/data/models/shopping_list_model.dart';
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
      print('Error Creating, Shopping List: $e');
      rethrow;
   }
  }
}