import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';

final privacyModeProvider = StateProvider<bool>((ref) => false);

final mpesaBalanceProvider = FutureProvider<double>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  final balance = await transactionsLs.getLatestMpesaBalance();
  return balance ?? 0.0;
});

final mpesaBalanceHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  final transactionsLs = TransactionsLs(db);
  return await transactionsLs.getMpesaBalanceHistory();
});
