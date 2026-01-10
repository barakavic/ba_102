import 'package:ba_102_fe/data/models/models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ba_102_fe/config/api_config.dart';

class Categoryservice {
  Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse(ApiConfig.categoriesUrl));

    if(response.statusCode == 200){
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    }
    else {
      throw Exception('Failed to load categories');
    }
  }
}