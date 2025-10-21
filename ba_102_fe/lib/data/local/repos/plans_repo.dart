import 'package:ba_102_fe/data/local/database_helper.dart';

class PlansRepo {
  final dbHelper = DatabaseHelper.instance;

  Future<int> createPlan(Map<String, dynamic> plan) async{
    final db = await dbHelper.database;
    
    return await db.insert('budget_plans', 
    plan
    );


  }

  Future<List<Map<String, dynamic>>> getPlans() async{
    final db = await dbHelper.database;

    return await db.query('budget_plans');
  }

  Future<int> updatePlans(Map<String, dynamic> plan) async{
    final db = await dbHelper.database;

    return await db.update('budget_plans', 
    plan, 
    where: 'id = ?', 
    whereArgs: [plan['id']],);
  }

  Future<int> deletePlan(int id) async{
    final db = await dbHelper.database;

    return await db.delete('budget_plans',  where: 'id = ?', whereArgs: [id]);
  }
}