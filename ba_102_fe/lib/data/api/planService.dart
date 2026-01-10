import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/config/api_config.dart';

class Planservice {
  Future<List<Plan>> fetchPlans() async{
    final response = await http.get(Uri.parse(ApiConfig.plansUrl));

    if (response.statusCode == 200){
      final List<dynamic> data = jsonDecode((response.body));
      return data.map((plan) => Plan.fromJson(plan)).toList();
    }
    else {
      throw Exception('Failed To Load Plans');
    }
  }
}