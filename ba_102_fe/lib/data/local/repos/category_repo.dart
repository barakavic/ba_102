import 'package:ba_102_fe/data/local/database_helper.dart';

class CategoryRepo {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertCategory(Map<String, dynamic> category) async{
    final db = await dbHelper.database;
    return await db.insert('budget_category', category);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await dbHelper.database;
    return await db.query('budget_category');
    
  }

  Future <int> updateCategory(Map<String, dynamic> category) async{
    final db = await dbHelper.database;
    return await db.update(
      'budget_category',
      category,
      where: 'id = ?',
      whereArgs: category['id'],
      );
  }

  Future<int> deleteCategory(int id) async{
    final db = await dbHelper.database;
    return await db.delete('budget_category',
    where: 'id = ?',
    whereArgs: [id]
    );
  }


  
}