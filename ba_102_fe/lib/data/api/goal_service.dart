import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/config/api_config.dart';

class GoalService {
  Future<List<Goal>> fetchGoals() async {
    final response = await http
        .get(Uri.parse(ApiConfig.goalsUrl))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((goal) => Goal.fromJson(goal)).toList();
    } else {
      throw Exception('Failed to load goals');
    }
  }
}
