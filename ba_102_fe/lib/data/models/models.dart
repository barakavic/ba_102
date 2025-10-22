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

// API deserialization
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
  id: json['id'], 
  amount: (json['amount']as num?)?.toDouble() ?? 0.0, 
  description: json['description'] ?? '',
  date: DateTime.parse(json['date']),
   );

  //  Local DB mapping
  Map<String, dynamic> toMap()=>{
    'id': id,
    'amount': amount,
    'description': description,
    'date': date.toIso8601String(),
  };

  factory Transaction.fromMap(Map<String, dynamic> map)=>Transaction(
  id: map['id'], 
  amount: (map['amount']as num ?)?.toDouble() ?? 0.0, 
  description: map['description'] ?? '', 
  date: DateTime.parse(map['date']));
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
  // API deserializaton
  factory Category.fromJson(
    Map<String, dynamic> json
  ) => Category(id: json['id'],
   limitAmount: (json['limitAmount'] as num?)?.toDouble() ?? 0, 
  spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0, 
  name: json['name']?? '', status: json['status']?? 'NORMAL', 
  transactions: (json['transactions'] as List<dynamic>?)?.
  map((e)=>Transaction.
  fromJson(e)).toList()??[],
  );

  // Local DB Mapping
  Map<String, dynamic> toMap()=>{
    'id':id,
    'name':name,
    'limit_amount':limitAmount,
    'spent_amount': spentAmount,
    'status': status,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'], 
    limitAmount: (map['limitAmount'] as num?)?.toDouble() ?? 0.0, 
    spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0.0, 
    name: map['name'] ?? '', 
    status: map['status'] ?? 'NORMAL', transactions: const[],
    );
 
}


class Plan {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final bool isSynced;
  final DateTime? lastModified;
  final List<Category> categories;
  final List<Transaction> transactions;


Plan({
  required this.id,
  required this.name,
  required this.startDate,
  required this.endDate,
  required this.status,
  this.isSynced = true,
  this.lastModified,
  required this.categories,
  required this.transactions,
});
// API Deserialization
factory Plan.fromJson(Map<String, dynamic> json) =>Plan(
  id: json['id'], 
  name: json['name'], 
  startDate: (DateTime.parse(json['start_date'])), 
  endDate: (DateTime.parse(json['end_date'])), 
  status: json['status'] ?? 'ACTIVE', 
  lastModified: json['last_modified'] != null 
  ? DateTime.parse(json['last_modified']) : null,

  categories: (json['categories'] as List<dynamic> ?)
  ?.map((e) => Category.fromJson(e)).
  toList() ?? [],
  transactions: (json['transactions'] as List<dynamic>?)
  ?.map((e) => Transaction
  .fromJson(e))
  .toList() ?? [],
  );
  

  


  Map<String, dynamic> toMap() =>{
    'id': id,
    'name': name,
    'start_date':startDate.toIso8601String(),
    'end_date':endDate.toIso8601String(),
    'status': status,
    'is_synced': isSynced ? 1 : 0,
    'last_modified': (lastModified ?? DateTime.now()).toIso8601String()
  };

  factory Plan.fromMap(Map<String,dynamic> map) => Plan(
  id: map['id'], 
  name: map['name'], 
  startDate: DateTime.parse(map['start_date']), 
  endDate: DateTime.parse(map['end_date']), 
  status: map['status'] ?? 'ACTIVE', 
  isSynced: (map['is_synced' ] ?? 1) == 1,
  lastModified: map['last_modified'] != null
  ?DateTime.parse(map['last_modified']):null,
  categories: const[],
   transactions: const[],
   );
}