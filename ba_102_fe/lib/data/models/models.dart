
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
  final int planId;
  final List<Transaction> transactions;

  Category({
    required this.id,
    required this.limitAmount,
    required this.spentAmount,
    required this.name,
    required this.status,
    required this.planId,
    required this.transactions,
    
  });

  Category copyWith({
  int? id,
  String? name,
  double? limitAmount,
  double? spentAmount,
  String? status,
  int? planId,
  List<Transaction>? transactions,
}) {
  return Category(
    id: id ?? this.id,
    name: name ?? this.name,
    limitAmount: limitAmount ?? this.limitAmount,
    spentAmount: spentAmount ?? this.spentAmount,
    status: status ?? this.status,
    planId: planId ?? this.planId,
    transactions: transactions ?? this.transactions,
  );
}

  // API deserializaton
  factory Category.fromJson(
    Map<String, dynamic> json
  ) => Category(id: json['id'],
   limitAmount: (json['limitAmount'] as num?)?.toDouble() ?? 0, 
  spentAmount: (json['spentAmount'] as num?)?.toDouble() ?? 0, 
  name: json['name']?? '', 
  status: json['status']?? 'NORMAL', 
  planId: json['planId'],
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
    'plan_id': planId,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int, 
    limitAmount: (map['limit_amount'] as num?)?.toDouble() ?? 0.0, 
    spentAmount: (map['spent_amount'] as num?)?.toDouble() ?? 0.0, 
    name: map['name'] ?? '', 
    status: map['status'] ?? 'NORMAL',
    planId: map['plan_id']  as int, 
    transactions: const[],
    );

    
 
}


class Plan {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  


Plan({
  required this.id,
  required this.name,
  required this.startDate,
  required this.endDate,
  required this.status,
  
});

// API Deserialization
factory Plan.fromJson(Map<String, dynamic> json) =>Plan(
  id: json['id'], 
  name: json['name'], 
  startDate: (DateTime.parse(json['start_date'])), 
  endDate: (DateTime.parse(json['end_date'])), 
  status: json['status'] ?? 'ACTIVE', 
  
  );
  

  

// SQLite serialization
  Map<String, dynamic> toMap() =>{
    if (id != 0 ) 'id': id,
    'name': name,
    'start_date':startDate.toIso8601String(),
    'end_date':endDate.toIso8601String(),
    'status': status,
   
  };

  factory Plan.fromMap(Map<String,dynamic> map) => Plan(
  id: map['id'], 
  name: map['name'], 
  startDate: DateTime.parse(map['start_date']), 
  endDate: DateTime.parse(map['end_date']), 
  status: map['status'] ?? 'ACTIVE', 
  
   );
}