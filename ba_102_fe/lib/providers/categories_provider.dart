import 'package:ba_102_fe/data/local/category_ls.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    final db = await DatabaseHelper.instance.database;
    final localService = CategoryLs(db);
    return await localService.getCategories();
  } catch (e) {
    print('Error fetching categories: $e');
    return [];
  }
});
