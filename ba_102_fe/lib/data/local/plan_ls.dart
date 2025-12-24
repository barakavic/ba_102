import 'package:ba_102_fe/data/models/models.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

class PlanLs {
final Database db;
  PlanLs(this.db);
  Future<List<Plan>> getPlans() async{
    
    final List<Map<String, dynamic>> planMaps = await db.query('budget_plans');

    return planMaps.map((map) => Plan.fromMap(map)).toList();
  }
  

  Future<void> insertPlan(Plan plan) async {
    await db.insert(
      'budget_plans', 
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteAllPlans() async{
    await db.delete('budget_plans');
  }
}