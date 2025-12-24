
class Transaction{
  final int? id;
  final double? amount;
  final String? description;
  final DateTime? date;
  final int? categoryId;
  final int? planId;
  final String type;
  final String? vendor;
  final String? mpesaReference;
  final double? balance;
  final String? rawSmsMessage;


  Transaction({
    this.id,
    this.amount,
    this.description,
    this.date,
    this.categoryId,
    this.planId,
    this.balance,
    this.mpesaReference,
    this.rawSmsMessage,
    this.type = 'outbound',
    this.vendor,


  });

  

// API deserialization
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
  id: json['id'], 
  amount: (json['amount']as num?)?.toDouble() ?? 0.0, 
  description: json['description'] ?? '',
  date: DateTime.parse(json['date']),
  categoryId: json['categoryId'],
  planId: json['plan_id'],
  balance: json['balance'] ?? 0,
  rawSmsMessage: json['raw_sms_message'] as String?,
  type: json['type'],
  vendor: json['vendor'],
  mpesaReference: json['mpesa_reference']

   );

  //  Local DB mapping
  Map<String, dynamic> toMap()=>{
    'id': id,
    'amount': amount,
    'description': description,
    'date': date?.toIso8601String(),
    'category_id': categoryId,
    'plan_id': planId,
    'type': type,
    'vendor': vendor,
    'mpesa_reference': mpesaReference,
    'balance': balance,
    'raw_sms_message': rawSmsMessage
  };

  factory Transaction.fromMap(Map<String, dynamic> map)=>Transaction(
  id: map['id'], 
  amount: (map['amount']as num ?)?.toDouble() ?? 0.0, 
  description: map['description'] ?? '', 
  date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
  categoryId: map['category_id'] as int?,
  planId: map['plan_id'] as int?,
  type: map['type'] as String? ?? 'outbound',
  vendor: map['vendor'] as String?,
  mpesaReference: map['mpesa_reference'] as String?,
  balance: map['balance'] as double?,
  rawSmsMessage: map['raw_sms_message'] as String?,
  );

  Transaction copyWith({
    int? id,
    String? description,
    double? amount,
    DateTime? date,
    int? categoryId,
    int? planId,
    String? type,
    String? vendor,
    String? mpesaReference,
    double? balance,
    String? rawSmsMessage,


  }){
    return Transaction(
    id: id??this.id, 
    amount: amount ?? this.amount, 
    description: description?? this.description, 
    date: date?? this.date,
    categoryId: categoryId ?? this.categoryId,
    planId: planId ?? this.planId,
    type: type ?? this.type,
    vendor: vendor ?? this.vendor,
    mpesaReference: mpesaReference ?? this.mpesaReference,
    balance: balance ?? this.balance,
    rawSmsMessage: rawSmsMessage ?? this.rawSmsMessage
    );
  }
}

class Category{
  final int id;
  final String name;
  final double limitAmount;
  final String? icon;
  final String? color;
  final List<Transaction> transactions;

  Category({
    required this.id,
    required this.name,
    this.limitAmount = 0.0,
    this.icon,
    this.color,
    required this.transactions,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'], 
    name: json['name'], 
    limitAmount: (json['limit_amount'] as num?)?.toDouble() ?? 0.0,
    icon: json['icon'] as String?,
    color: json['color'] as String?,
    transactions: (json['transactions'] as List?)?.map((t) => Transaction.fromJson(t)).toList() ?? [],
  );

  Map<String, dynamic> toMap() => {
    if (id != 0) 'id': id,
    'name': name,
    'limit_amount': limitAmount,
    'icon': icon,
    'color': color,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int, 
    name: map['name'] ?? '', 
    limitAmount: (map['limit_amount'] as num?)?.toDouble() ?? 0.0,
    icon: map['icon'] as String?,
    color: map['color'] as String?,
    transactions: const[],
  );

  Category copyWith({
    int? id,
    String? name,
    double? limitAmount,
    String? icon,
    String? color,
    List<Transaction>? transactions,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      limitAmount: limitAmount ?? this.limitAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      transactions: transactions ?? this.transactions,
    );
  }
}

class Plan {
  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final double limitAmount;
  final String planType;

  Plan({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.limitAmount = 0.0,
    this.planType = 'monthly',
  });

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['id'], 
    name: json['name'], 
    startDate: DateTime.parse(json['start_date']), 
    endDate: DateTime.parse(json['end_date']), 
    status: json['status'] ?? 'ACTIVE', 
    limitAmount: (json['limit_amount'] as num?)?.toDouble() ?? 0.0,
    planType: json['plan_type'] ?? 'monthly',
  );

  Map<String, dynamic> toMap() => {
    if (id != 0) 'id': id,
    'name': name,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'status': status,
    'limit_amount': limitAmount,
    'plan_type': planType,
  };

  factory Plan.fromMap(Map<String, dynamic> map) => Plan(
    id: map['id'], 
    name: map['name'], 
    startDate: DateTime.parse(map['start_date']), 
    endDate: DateTime.parse(map['end_date']), 
    status: map['status'] ?? 'ACTIVE', 
    limitAmount: (map['limit_amount'] as num?)?.toDouble() ?? 0.0,
    planType: map['plan_type'] ?? 'monthly',
  );
}