
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
  final List<Transaction> transactions;

  Category({
    required this.id,
    required this.name,
    required this.transactions,
    
  });

  Category copyWith({
  int? id,
  String? name,
  List<Transaction>? transactions,
}) {
  return Category(
    id: id ?? this.id,
    name: name ?? this.name,
    transactions: transactions ?? this.transactions,
  );
}

  // API deserializaton
  factory Category.fromJson(
    Map<String, dynamic> json
  ) => Category(id: json['id'],
  name: json['name']?? '', 
  transactions: (json['transactions'] as List<dynamic>?)?.
  map((e)=>Transaction.
  fromJson(e)).toList()??[],
  );
  
  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int, 
    name: map['name'] ?? '', 
    transactions: const[],
    );

    // Local DB Mapping
  Map<String, dynamic> toMap()=>{
    if (id !=0) 'id':id,
    'name':name,
    };


    
 
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