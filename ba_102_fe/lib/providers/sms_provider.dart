import 'package:ba_102_fe/features/transactions/presentation/transactions_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/services/Sms_Listener_Service.dart';
import 'package:ba_102_fe/services/Sms_Message_Parser.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';


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

  void _handleIncomingSms(Map<String,dynamic> smsData ) async{
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

      
      await _saveToDatabase(mpesaTransaction);

      ref.invalidate(txProv);
    }
    else{
      print('Failed to parse M-Pesa message');
      
    }
  }

  String _generateDescription(MpesaTransaction tx){
    switch(tx.type){
      case TransactionType.inbound:
      return 'Received from ${tx.sender ?? 'uknown'}';
      case TransactionType.outbound:
      return 'Sent to ${tx.recipient ?? 'uknown'}';
      case TransactionType.withdrawal:
      return 'M-Pesa withdrawal';
      case TransactionType.deposit:
      return 'M-pesa Withdrawal';
    }
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

  Future<void> _saveToDatabase(MpesaTransaction mpesaTransaction) async{
    try{
      final db = await DatabaseHelper.instance.database;
      final localService = TransactionsLs(db);

      final transaction = Transaction(amount: mpesaTransaction.amount, 
      description: _generateDescription(mpesaTransaction), 
      date: mpesaTransaction.timestamp,
      type: _getTransactionType(mpesaTransaction.type),
      vendor: _getVendorName(mpesaTransaction),
      mpesaReference: mpesaTransaction.reference,
      balance: mpesaTransaction.balance,
      rawSmsMessage: mpesaTransaction.rawMessage,

      );

      await localService.insertTransaction(transaction);
      print("Transaction saved to database");

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
