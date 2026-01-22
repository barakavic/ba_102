import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/config/api_config.dart';

class GoalService {
  Future<List<Goal>> fetchGoals() async {
    final response = await http.get(Uri.parse(ApiConfig.goalsUrl));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((goal) => Goal.fromJson(goal)).toList();
    } else {
      throw Exception('Failed to load goals');
    }
  }

  Future<Goal> createGoal(Goal goal) async {
    final response = await http.post(
      Uri.parse(ApiConfig.goalsUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(goal.toJson()),
    );

    if (response.statusCode == 200) {
      return Goal.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create goal');
    }
  }

  Future<Goal> analyzeGoal(int id) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.goalsUrl}/$id/analyze"),
    );

    if (response.statusCode == 200) {
      return Goal.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to analyze goal');
    }
  }
}
