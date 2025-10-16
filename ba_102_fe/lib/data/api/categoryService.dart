import 'package:ba_102_fe/data/models/models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Categoryservice {
  Future<List<Category>> fetchCategories() async {

    final String url = "http://10.0.2.2:8080/categories";
    final response = await http.get(Uri.parse(url));

    if(response.statusCode == 200){
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();

    }
    else {
      throw Exception('Failed to load categories');
    }


  }
}