import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/services/Sms_Listener_Service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' hide Transaction;

const _selectedMonthPreferenceKey = 'transactions.selected_month';

DateTime _monthStart(DateTime date) => DateTime(date.year, date.month);

DateTime _currentMonth() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
}

String _monthStorageValue(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-'
    '${month.month.toString().padLeft(2, '0')}-01';

Future<void> _saveSelectedMonth(Database db, DateTime month) async {
  await db.insert('app_preferences', {
    'preference_key': _selectedMonthPreferenceKey,
    'preference_value': _monthStorageValue(month),
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

final earliestSmsDateProvider = FutureProvider<DateTime?>((ref) async {
  final smsListener = SmsListenerService(onMessageReceived: (_) {});
  final date = await smsListener.getEarliestMpesaMessageDate();
  if (date == null || date.isAfter(DateTime.now())) {
    return null;
  }
  return date;
});

final earliestSmsMonthProvider = FutureProvider<DateTime?>((ref) async {
  final date = await ref.watch(earliestSmsDateProvider.future);
  return date == null ? null : _monthStart(date);
});

final selectedTransactionMonthProvider =
    AsyncNotifierProvider<SelectedTransactionMonthNotifier, DateTime>(
      SelectedTransactionMonthNotifier.new,
    );

class SelectedTransactionMonthNotifier extends AsyncNotifier<DateTime> {
  @override
  Future<DateTime> build() async {
    final db = await DatabaseHelper.instance.database;
    final currentMonth = _currentMonth();
    DateTime? earliestMonth;
    var earliestLookupFailed = false;
    try {
      earliestMonth = await ref.watch(earliestSmsMonthProvider.future);
    } catch (_) {
      earliestLookupFailed = true;
    }
    final rows = await db.query(
      'app_preferences',
      columns: ['preference_value'],
      where: 'preference_key = ?',
      whereArgs: [_selectedMonthPreferenceKey],
      limit: 1,
    );

    final savedValue = rows.isEmpty
        ? null
        : rows.first['preference_value'] as String?;
    final savedMonth = savedValue == null
        ? null
        : DateTime.tryParse(savedValue);
    final month = savedMonth == null ? currentMonth : _monthStart(savedMonth);
    final isAfterEarliest =
        earliestLookupFailed ||
        !(month.isBefore(earliestMonth ?? currentMonth));
    final isInRange = isAfterEarliest && !month.isAfter(currentMonth);
    final selectedMonth = isInRange ? month : currentMonth;

    if (savedMonth == null || !isInRange) {
      await _saveSelectedMonth(db, selectedMonth);
    }
    return selectedMonth;
  }

  Future<void> selectMonth(DateTime value) async {
    final month = _monthStart(value);
    final db = await DatabaseHelper.instance.database;
    final earliestMonth = await ref.read(earliestSmsMonthProvider.future);
    final earliestAllowed = earliestMonth ?? _currentMonth();
    final currentMonth = _currentMonth();

    if (month.isBefore(earliestAllowed) || month.isAfter(currentMonth)) {
      throw RangeError(
        'Selected month is outside the available transaction dates.',
      );
    }

    await _saveSelectedMonth(db, month);
    state = AsyncData(month);
  }
}

final transactionsForMonthProvider =
    FutureProvider.family<List<Transaction>, DateTime>((ref, month) async {
      final db = await DatabaseHelper.instance.database;
      return TransactionsLs(db).getTransactionsByMonth(month);
    });

final allTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  return TransactionsLs(db).getAllTransactions();
});
