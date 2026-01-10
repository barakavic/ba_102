import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/features/settings/presentation/app_settings_page.dart';
import 'package:ba_102_fe/config/api_config.dart';

class SyncService {
  Future<void> syncAll(bool isSyncEnabled) async {
    try {
      // Check if sync is enabled in settings
      if (!isSyncEnabled) {
        print("Sync: Cloud synchronization is disabled in settings.");
        return;
      }

      final db = await DatabaseHelper.instance.database;
      final localService = TransactionsLs(db);
      
      // 1. Get all unsynced transactions
      final unsynced = await localService.getUnsyncedTransactions();
      
      if (unsynced.isEmpty) {
        print("Sync: No pending transactions to sync.");
        return;
      }

      print("Sync: Starting sync for ${unsynced.length} transactions...");

      for (var tx in unsynced) {
        final success = await _syncSingleTransaction(tx);
        if (success) {
          // 2. Update local status to synced
          await localService.updateTransaction(tx.copyWith(isSynced: true));
          print("Sync: Successfully synced transaction ${tx.clientId}");
        } else {
          print("Sync: Failed to sync transaction ${tx.clientId}");
        }
      }
    } catch (e) {
      print("Sync Error: $e");
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
        print("Sync Server Error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Sync Network Error: $e");
      return false;
    }
  }
}
