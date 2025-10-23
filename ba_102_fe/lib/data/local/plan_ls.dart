import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

class PlanLs {
final Database db;
  PlanLs(this.db);
  Future<List<Plan>> getPlans() async{
    
    final List<Map<String, dynamic>> planMaps = await db.query('budget_plans');
    List<Plan> plans = [];

    for (var planMap in planMaps){
      // Fetch the related categories

      final List<Map<String, dynamic>> catMaps = await db.query(
        'budget_category',
        where: 'plan_id = ?',
        whereArgs: [planMap['id']],
      );

      List<Category> categories = [];

      for (var catMap in catMaps){
        final List<Map<String, dynamic>> txMaps = await db.query(
          'transactions',
          where: 'category_id = ?',
          whereArgs: [catMap['id']],
        );

        final txs = txMaps.map((m)=> Transaction.fromMap(m)).toList();

        Category category;
        try{
          category = Category.fromMap(catMap).copyWith(transactions: txs);


        }
        catch(_){
          final tmp = Category.fromMap(catMap);
          category = Category(id: tmp.id, 
          limitAmount: tmp.limitAmount, 
          spentAmount: tmp.spentAmount, 
          name: tmp.name, 
          status: tmp.status, 
          planId: tmp.planId, 
          transactions: txs,
          );

        }
        categories.add(category);
      }

      final tmpPlan = Plan.fromMap(planMap);
      final plan = Plan(
      id: tmpPlan.id, 
      name: tmpPlan.name, 
      startDate: tmpPlan.startDate, 
      endDate: tmpPlan.endDate, 
      status: tmpPlan.status, 
      categories: categories, 
      transactions: categories.expand((c)=> c.transactions).toList(),
      );
      plans.add(plan);

      

    

      

      }
      return plans;
    }


    // return maps.map((map) => Plan.fromMap(map)).toList();
  

  Future<void> insertPlan(Plan plan) async {
    await db.insert('budget_plans', plan.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteAllPlans() async{
    await db.delete('budget_plans');
  }
}