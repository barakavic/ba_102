import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ba_102_fe/data/models/models.dart';

class Planservice {
  final String baseUrl = "http://10.0.2.2:8080/plans";

  Future<List<Plan>> fetchPlans() async{
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200){
      final List<dynamic> data = jsonDecode((response.body));
      return data.map((plan) => Plan.fromJson(plan)).toList();

    }
    else {
      throw Exception('Failed To Load Plans');
    }
  }

  
}