import 'dart:convert';

import 'package:ba_102_fe/data/models/models.dart';
import 'package:http/http.dart' as http;

class TransactionService {
  final String baseUrl = "http://10.0.2.2:8080/transactions";


  Future<List<Transaction>> fetchTx() async{
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200){
      final List<dynamic> data = jsonDecode((response.body));
      return data.map((tx) => Transaction.fromJson(tx)).toList();
    }
    else{
      throw Exception('Failed to load transactions');
    }
  }
}