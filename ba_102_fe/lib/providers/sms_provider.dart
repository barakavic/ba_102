import 'package:ba_102_fe/features/transactions/presentation/transactions_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/services/Sms_Listener_Service.dart';
import 'package:ba_102_fe/services/Sms_Message_Parser.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/services/categorization_service.dart';

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

  void _initializeListener(){
    _smsListener = SmsListenerService(onMessageReceived: _handleIncomingSms,
    );

    _smsListener.initialize().then((_){
      state = state.copyWith(isListening: true);
      print("Sms Listener Started Successfully");


    }).catchError((error){
      state = state.copyWith(error: error.toString());
      print("Sms Listener failed: $error");

    });

  }

  void _handleIncomingSms(Map<String,dynamic> smsData, {bool isSimulated = false}) async{
    print("Dart: _handleIncomingSms triggered with data: $smsData");
    final String body = smsData['body'];
    final int timestamp = smsData['timestamp'];

    print ("Sms received: $body");

    // Parse M-Pesa message
    final mpesaTransaction = _mpesaParser.parseMessage(body, timestamp);

    if (mpesaTransaction != null){
      print("Parsed Mpesa: ${mpesaTransaction.reference} - KES ${mpesaTransaction.amount}");

      state = state.copyWith(
        lastTransaction: mpesaTransaction,
        transactionCount: state.transactionCount + 1,
      );

      
      await _saveToDatabase(mpesaTransaction, isSimulated: isSimulated);

      ref.invalidate(txProv);
    }
    else{
      print('Failed to parse M-Pesa message');
      
    }
  }

  // Public method for testing/simulation
  void simulateSms(String body, String sender) {
    _handleIncomingSms({
      'body': body,
      'sender': sender,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, isSimulated: true);
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

      print("Saving transaction to DB: ${transaction.mpesaReference}");
      final id = await localService.insertTransaction(transaction);
      print("Transaction saved to database with ID: $id");

    }
    catch(e){
      print("Error saving transaction: $e");
      state = state.copyWith(error: "Failed to save transaction : $e");

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
