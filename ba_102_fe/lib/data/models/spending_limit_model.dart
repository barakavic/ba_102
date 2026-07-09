class SpendingLimit {
  final int id;
  final String limitType;
  final double amount;
  final int alertPercentage;
  final List<String>? specificDays;
  final DateTime createdAt;

  const SpendingLimit({
    required this.id,
    required this.limitType,
    required this.amount,
    required this.alertPercentage,
    this.specificDays,
    required this.createdAt
  });

  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'title': limitType,
      'amount': amount,
      'alert_percentage': alertPercentage,
      'specific_days': specificDays?.join(','),
      'created_at': createdAt.toIso8601String()
    };
  }

  factory SpendingLimit.fromMap(Map<String, dynamic> map){
    return SpendingLimit(
      id: map['id'] as int, 
      limitType: map['limit_type'] as String, 
      amount: (map['amount'] as num).toDouble(), 
      alertPercentage: map['alert_percentage'] as int, 
      specificDays: (map['specific_days'] as String?)?.split(','),
      createdAt: DateTime.parse(map['created_at'] as String));
  }

}