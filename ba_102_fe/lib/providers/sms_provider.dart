import 'package:ba_102_fe/features/transactions/presentation/transactions_page.dart';
import 'package:ba_102_fe/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/services/Sms_Listener_Service.dart';
import 'package:ba_102_fe/services/Sms_Message_Parser.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/services/categorization_service.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:ba_102_fe/services/sync_service.dart';
import 'package:ba_102_fe/features/settings/presentation/app_settings_page.dart';

class SmsState {
  final MpesaTransaction? lastTransaction;
  final bool isListening;
  final String? error;
  final int transactionCount;


  SmsState({
    this.lastTransaction,
    this.isListening = false,
    this.error,
    this.transactionCount = 0,
    }
  );
  
  SmsState copyWith({
    MpesaTransaction? lastTransaction,
    bool? isListening,
    String? error,
    int? transactionCount,
  })
  {
    return SmsState(
      lastTransaction: lastTransaction ?? this.lastTransaction,
      isListening: isListening ?? this.isListening,
      error: error ?? this.error,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }
}

class SmsNotifier extends StateNotifier<SmsState> {
  late SmsListenerService _smsListener;
  final MpesaParserService _mpesaParser = MpesaParserService();
  final Ref ref;

  SmsNotifier(this.ref) : super(SmsState()){
    _initializeListener();
  }

  void _initializeListener() async{
    _smsListener = SmsListenerService(onMessageReceived: _handleIncomingSms);
      try{
    await _smsListener.initialize();
    state = state.copyWith(isListening: true);
    AppLogger.i("Sms Listener Started Successfully");

    // Auto-pull messages using a rolling lookback window
    syncHistoricalMessagesRollingWindow();

  }
  catch(err){
    state = state.copyWith(error: err.toString());
    AppLogger.e("Sms listener failed, $err");
  }
  }


  void _handleIncomingSms(Map<String,dynamic> smsData, {bool isSimulated = false}) async{
    AppLogger.d("Dart: _handleIncomingSms triggered with data: $smsData");
    final String body = smsData['body'];
    final int timestamp = smsData['timestamp'];

    AppLogger.d("Sms received: $body");

    // Parse M-Pesa message
    final mpesaTransaction = _mpesaParser.parseMessage(body, timestamp);

    if (mpesaTransaction != null){
      AppLogger.i("Parsed Mpesa: ${mpesaTransaction.reference} - KES ${mpesaTransaction.amount}");

      state = state.copyWith(
        lastTransaction: mpesaTransaction,
        transactionCount: state.transactionCount + 1,
      );

      
      await _saveToDatabase(mpesaTransaction, isSimulated: isSimulated);

      ref.invalidate(txProv);
      ref.invalidate(mpesaBalanceProvider);
      ref.invalidate(mpesaBalanceHistoryProvider);
      ref.invalidate(periodSummaryProvider);
      ref.invalidate(spendingBarDataProvider);
      ref.invalidate(topCategoriesProvider);
      ref.invalidate(recentTransactionsProvider);

      // Trigger Cloud Sync immediately for the new transaction
      final isSyncEnabled = ref.read(cloudSyncProvider);
      SyncService().syncAll(isSyncEnabled);
    }
    else{
      AppLogger.w('Failed to parse M-Pesa message');
      
    }
  }


  String _generateDescription(MpesaTransaction tx, {bool isSimulated = false}){
    String desc = "";
    switch(tx.type){
      case TransactionType.inbound:
      desc = 'Received from ${tx.sender ?? 'uknown'}';
      break;
      case TransactionType.outbound:
      desc = 'Sent to ${tx.recipient ?? 'uknown'}';
      break;
      case TransactionType.withdrawal:
      desc = 'M-Pesa withdrawal';
      break;
      case TransactionType.deposit:
      desc = 'M-Pesa deposit';
      break;
    }
    return isSimulated ? "[DEBUG] $desc" : desc;
  }

  String _getTransactionType(TransactionType type){
    switch(type){
      case TransactionType.inbound:
      return 'inbound';
      case TransactionType.outbound:
      return 'outbound';
      case TransactionType.deposit:
      return 'deposit';
      case TransactionType.withdrawal:
      return 'withdrawal';
    }
  }

  String _getVendorName(MpesaTransaction tx){
    if (tx.type == TransactionType.inbound && tx.sender != null){
      return tx.sender!;
    }
    else if(tx.type == TransactionType.outbound && tx.recipient != null){
      return tx.recipient!;

    }
    else if(tx.type == TransactionType.withdrawal){
      return 'M-Pesa ATM';

    }
    else if (tx.type == TransactionType.deposit){
      return 'M-pesa agent';
    }
    return 'Unknown';
  }

  Future<void> _saveToDatabase(MpesaTransaction mpesaTransaction, {bool isSimulated = false}) async{
    try{
      final db = await DatabaseHelper.instance.database;
      final localService = TransactionsLs(db);

      final vendor = _getVendorName(mpesaTransaction);
      final categoryId = await CategorizationService().getCategoryIdForVendor(vendor);

      final transaction = Transaction(
        amount: mpesaTransaction.amount, 
        description: _generateDescription(mpesaTransaction, isSimulated: isSimulated), 
        date: mpesaTransaction.timestamp,
        type: _getTransactionType(mpesaTransaction.type),
        vendor: vendor,
        categoryId: categoryId,
        mpesaReference: mpesaTransaction.reference,
        balance: mpesaTransaction.balance,
        rawSmsMessage: mpesaTransaction.rawMessage,
      );

      AppLogger.d("Saving transaction to DB: ${transaction.mpesaReference}");
      final id = await localService.insertTransaction(transaction);
      AppLogger.i("Transaction saved to database with ID: $id");

    }
    catch(e){
      AppLogger.e("Error saving transaction: $e");
      state = state.copyWith(error: "Failed to save transaction : $e");

    }
  }
  
Future<int> syncHistoricalMessagesRollingWindow() async {
  try {
    final now = DateTime.now();
    final lookbackStart = now.subtract(const Duration(days: 30));

    final List<Map<String, dynamic>> oldMessages =
        await _smsListener.fetchHistoricalMessages(since: lookbackStart);

    if (oldMessages.isEmpty) return 0;

    final parsedMessages = <MpesaTransaction>[];

    for (final sms in oldMessages) {
      final body = sms['body'] as String?;
      final timestamp = sms['timestamp'] as int?;

      if (body == null || timestamp == null) {
        continue;
      }

      final mpesaTx = _mpesaParser.parseMessage(body, timestamp);
      if (mpesaTx != null) {
        parsedMessages.add(mpesaTx);
      }
    }

    if (parsedMessages.isEmpty) return 0;

    final oneDayRefs = parsedMessages
        .where((tx) => now.difference(tx.timestamp).inDays <= 1)
        .map((tx) => tx.reference)
        .toSet();

    final sevenDayRefs = parsedMessages
        .where((tx) => now.difference(tx.timestamp).inDays <= 7)
        .map((tx) => tx.reference)
        .toSet();

    final thirtyDayRefs = parsedMessages
        .map((tx) => tx.reference)
        .toSet();

    final isConsistent =
        oneDayRefs.every((ref) => sevenDayRefs.contains(ref)) &&
        sevenDayRefs.every((ref) => thirtyDayRefs.contains(ref));

    if (!isConsistent) {
      AppLogger.w(
        'Rolling lookback window failed consistency check. Falling back to broader recovery.',
      );
      return await syncHistoricalMessages(
        since: now.subtract(const Duration(days: 90)),
      );
    }

    final db = await DatabaseHelper.instance.database;
    final existingRows = await db.query(
      'transactions',
      columns: ['mpesa_reference'],
      where: 'mpesa_reference IS NOT NULL',
    );

    final existingRefs = existingRows
        .map((row) => row['mpesa_reference'] as String?)
        .whereType<String>()
        .toSet();

    int newCount = 0;

    for (final tx in parsedMessages) {
      if (existingRefs.contains(tx.reference)) {
        continue;
      }

      await _saveToDatabase(tx);
      newCount++;
      existingRefs.add(tx.reference);
    }

    if (newCount > 0) {
      ref.invalidate(txProv);
      ref.invalidate(mpesaBalanceProvider);
      ref.invalidate(mpesaBalanceHistoryProvider);
      ref.invalidate(periodSummaryProvider);
      ref.invalidate(spendingBarDataProvider);
      ref.invalidate(topCategoriesProvider);
      ref.invalidate(recentTransactionsProvider);
    }

    return newCount;
  } catch (e) {
    AppLogger.e('Rolling historical sync error: $e');
    return 0;
  }
}

Future<int> syncHistoricalMessages({DateTime? since}) async {
  try {
    final syncSince = since ?? DateTime(DateTime.now().year, 1, 1);
    final List<Map<String, dynamic>> oldMessages =
        await _smsListener.fetchHistoricalMessages(since: syncSince);

    if (oldMessages.isEmpty) return 0;

    final db = await DatabaseHelper.instance.database;
    int newCount = 0;

    const chunksize = 20;
    for (int i = 0; i < oldMessages.length; i += chunksize) {
      final end = (i + chunksize < oldMessages.length)
          ? i + chunksize
          : oldMessages.length;

      final chunk = oldMessages.sublist(i, end);

      for (final sms in chunk) {
        final body = sms['body'] as String?;
        final timestamp = sms['timestamp'] as int?;

        if (body == null || timestamp == null) {
          continue;
        }

        final mpesaTx = _mpesaParser.parseMessage(body, timestamp);

        if (mpesaTx != null) {
          final existing = await db.query(
            'transactions',
            where: 'mpesa_reference = ?',
            whereArgs: [mpesaTx.reference],
          );

          if (existing.isEmpty) {
            await _saveToDatabase(mpesaTx);
            newCount++;
          }
        }
      }

      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (newCount > 0) {
      ref.invalidate(txProv);
      ref.invalidate(mpesaBalanceProvider);
      ref.invalidate(mpesaBalanceHistoryProvider);
      ref.invalidate(periodSummaryProvider);
      ref.invalidate(spendingBarDataProvider);
      ref.invalidate(topCategoriesProvider);
      ref.invalidate(recentTransactionsProvider);
    }

    return newCount;
  } catch (e) {
    AppLogger.e('Sync Historical Messages error: $e');
    return 0;
  }
}

  @override
  void dispose(){
    _smsListener.dispose();
    super.dispose();
  }



}
  final smsProvider = StateNotifierProvider<SmsNotifier, SmsState>((ref){
    return SmsNotifier(ref);
  });
