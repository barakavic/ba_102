import 'dart:convert';
import 'package:ba_102_fe/utils/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/config/api_config.dart';

class SyncService {
  Future<void> syncAll(bool isSyncEnabled) async {
    try {
      // Check if sync is enabled in settings
      if (!isSyncEnabled) {
        AppLogger.w("Sync: Cloud synchronization is disabled in settings.");
        return;
      }

      final db = await DatabaseHelper.instance.database;
      final localService = TransactionsLs(db);
      
      // 1. Get all unsynced transactions
      final unsynced = await localService.getUnsyncedTransactions();
      
      if (unsynced.isEmpty) {
        AppLogger.i("Sync: No pending transactions to sync.");
        return;
      }

      AppLogger.i("Sync: Starting sync for ${unsynced.length} transactions...");

      for (var tx in unsynced) {
        final success = await _syncSingleTransaction(tx);
        if (success) {
          // 2. Update local status to synced
          await localService.updateTransaction(tx.copyWith(isSynced: true));
          AppLogger.i("Sync: Successfully synced transaction ${tx.clientId}");
        } else {
          AppLogger.e("Sync: Failed to sync transaction ${tx.clientId}");
        }
      }
    } catch (e) {
      AppLogger.e("Sync Error: $e");
    }
  }

  Future<bool> _syncSingleTransaction(Transaction tx) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.transactionsUrl}/sync"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(tx.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        AppLogger.e("Sync Server Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      AppLogger.e("Sync Network Error: $e");
      return false;
    }
  }
}
