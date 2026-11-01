class ShoppingListModel {
  final String? id;
  final String? title;
  final int? colorSwatch;
  final double? budgetLimit;
  final bool isTemporary;
  final DateTime? createdAt;

  const ShoppingListModel({
    this.id,
    this.title,
    this.colorSwatch,
    this.budgetLimit,
    this.isTemporary = false,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "color_swatch": colorSwatch,
      "budget_limit": budgetLimit,
      "is_temporary": isTemporary ? 1 : 0,
      "createdAt": createdAt?.millisecondsSinceEpoch,
    };
  }

  factory ShoppingListModel.fromMap(Map<String, dynamic> map) {
    return ShoppingListModel(
      id: map['id'],
      title: map['title'],
      colorSwatch: map['color_swatch'],
      budgetLimit: map['budget_limit'] != null
          ? (map['budget_limit'] as num).toDouble()
          : null,
      isTemporary: map['is_temporary'] == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }

  ShoppingListModel copyWith({
    String? id,
    String? title,
    int? colorSwatch,
    double? budgetLimit,
    bool? isTemporary,
    DateTime? createdAt,
  }) {
    return ShoppingListModel(
      id: id ?? this.id,
      title: title ?? this.title,
      colorSwatch: colorSwatch ?? this.colorSwatch,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      isTemporary: isTemporary ?? this.isTemporary,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ShoppingListItemModel{
  final String? id;
  final String listId;
  final String name;
  final String? category;
  final double estimatedPrice;
  final int quantity;
  final bool isRequired;
  final bool isBought;
  final bool isPermanent;
  final String? brand;
  final DateTime? expiryDate;
  final String? volume;

  ShoppingListItemModel({
    this.id,
    required this.listId,
    required this.name,
    this.category,
    required this.estimatedPrice,
    required this.quantity,
    this.isRequired = false,
    this.isBought = false,
    this.isPermanent = true,
    this.brand,
    this.expiryDate,
    this.volume,
  });

  Map<String, dynamic> toMap(){
    return {
      'id': id,
      'list_id': listId,
      'name': name,
      'category': category,
      'estimated_price': estimatedPrice,
      'quantity': quantity,
      'is_required': isRequired ? 1 : 0,
      'is_bought': isBought ? 1 : 0,
      'is_permanent': isPermanent ? 1 : 0,
      'brand': brand,
      'expiry_date': expiryDate?.millisecondsSinceEpoch,
      'volume': volume,
    };
  }

  factory ShoppingListItemModel.fromMap(Map<String, dynamic> map){
    return ShoppingListItemModel(
      id: map['id'],
      listId: map['list_id'], 
      name: map['name'], 
      category: map['category'],
      estimatedPrice: map['estimated_price'] ?? 0.0,
      quantity: map['quantity'] ?? 1,
      isRequired: map['is_required'] == 1,
      isBought: map['is_bought'] == 1,
      isPermanent: map['is_permanent'] == 1,
      brand: map['brand'],
      expiryDate: map['expiry_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiry_date'] as int)
          : null,
      volume: map['volume'],
    );
  }

  ShoppingListItemModel copyWith({
    String? id,
    String? listId,
    String? name,
    String? category,
    double? estimatedPrice,
    int? quantity,
    bool? isRequired,
    bool? isBought,
    bool? isPermanent,
    String? brand,
    DateTime? expiryDate,
    String? volume,
  }){
    return ShoppingListItemModel(
      id: id ?? this.id,
      listId: listId ?? this.listId, 
      name: name ?? this.name, 
      category: category ?? this.category,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice, 
      quantity: quantity ?? this.quantity,
      isRequired: isRequired ?? this.isRequired,
      isBought: isBought ?? this.isBought,
      isPermanent: isPermanent ?? this.isPermanent,
      brand: brand ?? this.brand,
      expiryDate: expiryDate ?? this.expiryDate,
      volume: volume ?? this.volume,
    );
  }
}