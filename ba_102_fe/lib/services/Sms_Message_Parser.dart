import 'package:intl/intl.dart';

enum TransactionType { inbound, outbound, withdrawal, deposit}

class MpesaTransaction {
  final String reference;
  final double amount;
  final TransactionType type;
  final String? recipient;
  final String? sender;
  final double balance;
  final DateTime timestamp;
  final String rawMessage;
  

  MpesaTransaction({
    required this.reference,
    required this.amount,
    required this.type,
    this.recipient,
    this.sender,
    required this.balance,
    required this.timestamp,
    required this.rawMessage,
  });
}

class MpesaParserService {
  MpesaTransaction? parseMessage(String message, int timestampMillis){
    try{
      if (message.contains(RegExp(r'yo have received|received', caseSensitive: false))){
        return _parseReceivedMoney(message, timestampMillis);


      }

      if( message.contains(RegExp(r'sent to|you have sent', caseSensitive: false))){
        return _parseSentMoney(message, timestampMillis);
      }

      if (message.contains(RegExp(r'withdrawn|withraw', caseSensitive: false))){
        return _parseWithdrawal(message, timestampMillis);
      }

      if (message.contains(RegExp(r'deposited|deposit', caseSensitive: false))){
        return _parseDeposit(message, timestampMillis);
      }

      return null;
    }
    catch (e){
      print("Error Parsing M-Pesa Message: $e");
      return null;
    }
  }

  MpesaTransaction? _parseReceivedMoney(String message, int timestampMillis) {
    // Example: "RKL2X3Y4Z5 Confirmed. You have received Ksh500.00 from JOHN DOE 254712345678 on 18/12/24 at 2:30 PM New M-PESA balance is Ksh2,500.00"
    
    final referenceMatch = RegExp(r'^([A-Z0-9]+)\s+Confirmed', caseSensitive: false)
        .firstMatch(message);
    
    final amountMatch = RegExp(r'Ksh([\d,]+\.?\d*)', caseSensitive: false)
        .allMatches(message).toList();
    
    final senderMatch = RegExp(r'from\s+([A-Za-z\s]+?)(?:\s+\d{9,12})', caseSensitive: false)
        .firstMatch(message);
    
    final balanceMatch = RegExp(r'balance.*?Ksh([\d,]+\.?\d*)', caseSensitive: false)
        .firstMatch(message);
    
    if (referenceMatch != null && amountMatch.isNotEmpty) {
      return MpesaTransaction(
        reference: referenceMatch.group(1)!,
        amount: _parseAmount(amountMatch.first.group(1)!),
        type: TransactionType.inbound,
        sender: senderMatch?.group(1)?.trim(),
        balance: balanceMatch != null ? _parseAmount(balanceMatch.group(1)!) : 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
        rawMessage: message,
      );
    }
    
    return null;
  }

   MpesaTransaction? _parseSentMoney(String message, int timestampMillis) {
    // Example: "RKL2X3Y4Z5 Confirmed. You have sent Ksh300.00 to JANE SMITH 254723456789 on 18/12/24 at 3:45 PM. New M-PESA balance is Ksh2,200.00. Transaction cost, Ksh0.00"
    
    final referenceMatch = RegExp(r'^([A-Z0-9]+)\s+Confirmed', caseSensitive: false)
        .firstMatch(message);
    
    final amountMatch = RegExp(r'Ksh([\d,]+\.?\d*)|s+sent\s+to', caseSensitive: false)
        .firstMatch(message);
    
    final recipientMatch = RegExp(r'sent\s+to\s+([A-Za-z\s]+?)\s+for\s+account', caseSensitive: false)
        .firstMatch(message);
    
    final balanceMatch = RegExp(r'balance\s+is\s+Ksh([\d,]+\.?\d*)', caseSensitive: false)
        .firstMatch(message);
    
    if (referenceMatch != null && amountMatch != null) {
      return MpesaTransaction(
        reference: referenceMatch.group(1)!,
        amount: _parseAmount(amountMatch.group(1)!),
        type: TransactionType.outbound,
        recipient: recipientMatch?.group(1)?.trim(),
        balance: balanceMatch != null ? _parseAmount(balanceMatch.group(1)!) : 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
        rawMessage: message,
      );
    }
    
    return null;
  }

  MpesaTransaction? _parseWithdrawal(String message, int timestampMillis) {
    // Example: "RKL2X3Y4Z5 Confirmed. Ksh1,000.00 withdrawn from M-PESA Account. New balance is Ksh1,200.00"
    
    final referenceMatch = RegExp(r'^([A-Z0-9]+)\s+Confirmed', caseSensitive: false)
        .firstMatch(message);
    
    var amountMatch = RegExp(r'Ksh([\d,]+\.?\d*)\s+sent', caseSensitive: false)
        .firstMatch(message);
    amountMatch ??= RegExp(r'sent.*?Ksh[\d,]+\.?\d*', caseSensitive: false)
      .firstMatch(message);
    
    final balanceMatch = RegExp(r'balance.*?Ksh([\d,]+\.?\d*)', caseSensitive: false)
        .firstMatch(message);
    
    if (referenceMatch != null && amountMatch != null) {
      return MpesaTransaction(
        reference: referenceMatch.group(1)!,
        amount: _parseAmount(amountMatch.group(1)!),
        type: TransactionType.withdrawal,
        balance: balanceMatch != null ? _parseAmount(balanceMatch.group(1)!) : 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
        rawMessage: message,
      );
    }
    
    return null;
  }

  MpesaTransaction? _parseDeposit(String message, int timestampMillis) {
    final referenceMatch = RegExp(r'^([A-Z0-9]+)', caseSensitive: false)
        .firstMatch(message);
    
    final amountMatch = RegExp(r'Ksh([\d,]+\.?\d*)\s+deposited', caseSensitive: false)
        .firstMatch(message);
    
    final balanceMatch = RegExp(r'balance.*?Ksh([\d,]+\.?\d*)', caseSensitive: false)
        .firstMatch(message);
    
    if (referenceMatch != null && amountMatch != null) {
      return MpesaTransaction(
        reference: referenceMatch.group(1)!,
        amount: _parseAmount(amountMatch.group(1)!),
        type: TransactionType.deposit,
        balance: balanceMatch != null ? _parseAmount(balanceMatch.group(1)!) : 0,
        timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMillis),
        rawMessage: message,
      );
    }
    
    return null;  
  }

  double _parseAmount(String amountStr) {
    return double.parse(amountStr.replaceAll(',', ''));
  }

}