import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/spending_limit_model.dart';
import 'package:ba_102_fe/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';

class SpendingLimitRepo {
  final Database db;
  SpendingLimitRepo(this.db);

  Future<int> createLimit(SpendingLimit limit) async{
    try{
      final id = await db.insert(
      'spending_limits',
      limit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace 
    );
    return id;
    }
    catch(e,st){
      AppLogger.e('Failed to create spending limit', error: e, stackTrace: st);
      rethrow;
    }

  }

  Future<int> updateLimit(SpendingLimit limit) async{

    try {
      final updateStat = await db.update('spending_limits', 
      limit.toMap(),
      where: 'id = ?',
      whereArgs: [limit.id]
      );
      return updateStat;
      
    } catch (e, st) {
      AppLogger.e('Failed to update the limit', error: e, stackTrace: st);
      rethrow;

      
    }
  }


  Future<int> deleteLimit(int id) async{
    try
    {
      final delStat = await db.delete(
      'spending_limits',
      where: 'id = ?',
      whereArgs: [id]
    );
    return delStat;
  }
  catch(e,st){
    AppLogger.e('Failed to delete limit', error: e, stackTrace: st);
    rethrow;
  }
  }

  Future<SpendingLimit?> getSpendingLimit() async{
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'spending_limits',
        limit: 1
      );
      if (maps.isNotEmpty){
        return SpendingLimit.fromMap(maps.first);
      }
      return null;

    } catch (e, st) {
      AppLogger.e('Failed to fetch Spending List', error: e, stackTrace: st);
      rethrow;
      
    }

  }
}