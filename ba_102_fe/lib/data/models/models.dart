import 'package:uuid/uuid.dart';

class Transaction {
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
  final String? clientId; // For sync-safety
  final bool isSynced; // Local sync status

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
    String? clientId,
    this.isSynced = false,
  }) : clientId = clientId ?? const Uuid().v4();

  // API deserialization
  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        description: json['description'] ?? '',
        date: json['date'] != null ? DateTime.parse(json['date']) : null,
        categoryId: json['categoryId'],
        planId: json['plan_id'],
        balance: (json['balance'] as num?)?.toDouble() ?? 0,
        rawSmsMessage: json['raw_sms_message'] as String?,
        type: json['type'] ?? 'outbound',
        vendor: json['vendor'],
        mpesaReference: json['mpesa_reference'],
        clientId: json['clientId'] ?? json['client_id'],
        isSynced: true, // If it comes from API, it's synced
      );

  // Local DB mapping
  Map<String, dynamic> toMap() => {
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
        'raw_sms_message': rawSmsMessage,
        'client_id': clientId,
        'is_synced': isSynced ? 1 : 0,
      };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
        id: map['id'],
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
        description: map['description'] ?? '',
        date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
        categoryId: map['category_id'] as int?,
        planId: map['plan_id'] as int?,
        type: map['type'] as String? ?? 'outbound',
        vendor: map['vendor'] as String?,
        mpesaReference: map['mpesa_reference'] as String?,
        balance: (map['balance'] as num?)?.toDouble(),
        rawSmsMessage: map['raw_sms_message'] as String?,
        clientId: map['client_id'] as String?,
        isSynced: (map['is_synced'] as int? ?? 0) == 1,
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
    String? clientId,
    bool? isSynced,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      planId: planId ?? this.planId,
      type: type ?? this.type,
      vendor: vendor ?? this.vendor,
      mpesaReference: mpesaReference ?? this.mpesaReference,
      balance: balance ?? this.balance,
      rawSmsMessage: rawSmsMessage ?? this.rawSmsMessage,
      clientId: clientId ?? this.clientId,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  // API serialization (matches Spring Boot camelCase)
  Map<String, dynamic> toJson() => {
        'amount': amount,
        'description': description,
        'date': date?.toIso8601String(),
        'type': type,
        'vendor': vendor,
        'mpesaReference': mpesaReference,
        'balance': balance,
        'rawSmsMessage': rawSmsMessage,
        'clientId': clientId,
        // Note: plan and category are handled as nested objects if needed, 
        // but for basic sync, IDs or nulls are often enough depending on backend logic.
      };
}

class Category{
  final int id;
  final String name;
  final double limitAmount;
  final String? icon;
  final String? color;
  final int? parentId;
  final List<Transaction> transactions;

  Category({
    required this.id,
    required this.name,
    this.limitAmount = 0.0,
    this.icon,
    this.color,
    this.parentId,
    required this.transactions,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'], 
    name: json['name'], 
    limitAmount: (json['limit_amount'] as num?)?.toDouble() ?? 0.0,
    icon: json['icon'] as String?,
    color: json['color'] as String?,
    parentId: json['parent_id'] as int?,
    transactions: (json['transactions'] as List?)?.map((t) => Transaction.fromJson(t)).toList() ?? [],
  );

  Map<String, dynamic> toMap() => {
    if (id != 0) 'id': id,
    'name': name,
    'limit_amount': limitAmount,
    'icon': icon,
    'color': color,
    'parent_id': parentId,
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int, 
    name: map['name'] ?? '', 
    limitAmount: (map['limit_amount'] as num?)?.toDouble() ?? 0.0,
    icon: map['icon'] as String?,
    color: map['color'] as String?,
    parentId: map['parent_id'] as int?,
    transactions: const[],
  );

  Category copyWith({
    int? id,
    String? name,
    double? limitAmount,
    String? icon,
    String? color,
    int? parentId,
    List<Transaction>? transactions,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      limitAmount: limitAmount ?? this.limitAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
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

class Goal {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final double? marketPrice;
  final String? trackingUrl;
  final DateTime? lastChecked;
  final String? marketStatus;
  final String? currency;
  final String? rationale;

  Goal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.deadline,
    this.marketPrice,
    this.trackingUrl,
    this.lastChecked,
    this.marketStatus,
    this.currency,
    this.rationale,
  });

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        name: json['name'],
        targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
        deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
        marketPrice: (json['marketPrice'] as num?)?.toDouble(),
        trackingUrl: json['trackingUrl'],
        lastChecked: json['lastChecked'] != null ? DateTime.parse(json['lastChecked']) : null,
        marketStatus: json['marketStatus'],
        currency: json['currency'],
        rationale: json['rationale'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline?.toIso8601String(),
        'marketPrice': marketPrice,
        'trackingUrl': trackingUrl,
        'lastChecked': lastChecked?.toIso8601String(),
        'marketStatus': marketStatus,
        'currency': currency,
        'rationale': rationale,
      };

  // Local DB mapping
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'current_amount': currentAmount,
        'deadline': deadline?.toIso8601String(),
        'market_price': marketPrice,
        'tracking_url': trackingUrl,
        'last_checked': lastChecked?.toIso8601String(),
        'market_status': marketStatus,
        'currency': currency,
        'rationale': rationale,
      };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'],
        name: map['name'],
        targetAmount: (map['target_amount'] as num?)?.toDouble() ?? 0.0,
        currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0.0,
        deadline: map['deadline'] != null ? DateTime.parse(map['deadline']) : null,
        marketPrice: (map['market_price'] as num?)?.toDouble(),
        trackingUrl: map['tracking_url'],
        lastChecked: map['last_checked'] != null ? DateTime.parse(map['last_checked']) : null,
        marketStatus: map['market_status'],
        currency: map['currency'],
        rationale: map['rationale'],
      );

  Goal copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    double? marketPrice,
    String? trackingUrl,
    DateTime? lastChecked,
    String? marketStatus,
    String? currency,
    String? rationale,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: deadline ?? this.deadline,
      marketPrice: marketPrice ?? this.marketPrice,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      lastChecked: lastChecked ?? this.lastChecked,
      marketStatus: marketStatus ?? this.marketStatus,
      currency: currency ?? this.currency,
      rationale: rationale ?? this.rationale,
    );
  }
}