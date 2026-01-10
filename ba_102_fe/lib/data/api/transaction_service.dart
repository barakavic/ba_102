import 'dart:convert';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:http/http.dart' as http;
import 'package:ba_102_fe/config/api_config.dart';

class TransactionService {
  Future<List<Transaction>> fetchTx() async{
    final response = await http.get(Uri.parse(ApiConfig.transactionsUrl));

    if (response.statusCode == 200){
      final List<dynamic> data = jsonDecode((response.body));
      return data.map((tx) => Transaction.fromJson(tx)).toList();
    }
    else{
      throw Exception('Failed to load transactions');
    }
  }
}