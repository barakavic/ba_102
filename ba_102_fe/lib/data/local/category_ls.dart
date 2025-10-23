import 'package:ba_102_fe/data/models/models.dart';
import 'package:sqflite/sqlite_api.dart';

class CategoryLs {
 final Database db;
 CategoryLs(this.db);
 Future<List<Category>> getCategories() async{
  final List<Map<String, dynamic>> maps = await db.query('budget_category');

  return maps.map((map) => Category.fromMap(map)).toList();
 }

 Future<void> insertCategory(Category category) async{
  await db.insert('budget_category', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
 }

 Future<void> deleteAllCategories() async{
  await db.delete('budget_category');
 }
}