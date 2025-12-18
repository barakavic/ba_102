import 'package:ba_102_fe/data/models/models.dart';
import 'package:sqflite/sqlite_api.dart' hide Transaction;

class CategoryLs {
 final Database db;
 CategoryLs(this.db);
 Future<List<Category>> getCategories() async{
    final List<Map<String, dynamic>> catMaps = await db.query('budget_category');
    List<Category> categories = [];

    for (final catMap in catMaps){
      final List<Map<String, dynamic>> txMaps = await db.query(
        'transactions',
        where: 'category_id = ?',
        whereArgs: [catMap['id']],
      );
      
      final transactions = txMaps.map((m) => Transaction.fromMap(m)).toList();

      final category = Category.fromMap(catMap).copyWith(
        transactions: transactions,
      );

      categories.add(category);
    }

    return categories;


  // return maps.map((map) => Category.fromMap(map)).toList();
 }

 Future<void> insertCategory(Category category) async{
  await db.insert(
    'budget_category', 
    category.toMap(), 
    conflictAlgorithm: ConflictAlgorithm.replace);
 }

 Future<void> deleteAllCategories() async{
  await db.delete('budget_category');
 }
}