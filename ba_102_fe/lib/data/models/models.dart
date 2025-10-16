import 'dart:math';

class Transaction{
  final int id;
  final double amount;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'], 
  amount: json['amount'], 
  description: json['description'] ?? '',
  date: DateTime.parse(json['date']),
   );
}

class Category{
  final int id;
  final String name;
  final double limitAmount;
  final double spentAmount;
  final String status;
  final List<Transaction> transactions;

  Category({
    required this.id,
    required this.limitAmount,
    required this.spentAmount,
    required this.name,
    required this.status,
    required this.transactions,
    
  });
  
  factory Category.fromJson(
    Map<String, dynamic> json
  ) => Category(id: json['id'],
   limitAmount: (json['limitAmount'] as num?)?.toDouble() ?? 0, 
  spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0, 
  name: json['name']?? '', status: json['status']?? 'NORMAL', 
  transactions: (json['transaction'] as List<dynamic>?)?.
  map((e)=>Transaction.
  fromJson(e)).toList()??[],
  );
 
}


class Plan {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final List<Category> categories;
  final List<Transaction> transactions;


Plan({
  required this.id,
  required this.name,
  required this.startDate,
  required this.endDate,
  required this.status,
  required this.categories,
  required this.transactions,
});

factory Plan.fromJson(Map<String, dynamic> json) {
  return Plan(id: json['id'], 
  name: json['name'], 
  startDate: (DateTime.parse(json['startDate'])), 
  endDate: (DateTime.parse(json['endDate'])), 
  status: json['status'] ?? 'ACTIVE', 
  categories: (json['categories'] as List<dynamic> ?)
  ?.map((e) => Category.fromJson(e)).
  toList() ?? [],
  transactions: (json['transactions'] as List<dynamic>?)
  ?.map((e) => Transaction
  .fromJson(e))
  .toList() ?? [],
  );}
}