import 'package:flutter/material.dart';

class IconService {
  static final List<Map<String, dynamic>> availableIcons = [
    {'name': 'food', 'icon': Icons.fastfood, 'label': 'Food', 'keywords': ['groceries', 'restaurant', 'eat', 'dinner', 'lunch', 'breakfast', 'kfc', 'java', 'food']},
    {'name': 'coffee', 'icon': Icons.coffee, 'label': 'Coffee', 'keywords': ['cafe', 'starbucks', 'espresso', 'tea']},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Dining', 'keywords': ['dinner', 'lunch', 'eat out']},
    {'name': 'utilities', 'icon': Icons.lightbulb, 'label': 'Utilities', 'keywords': ['electricity', 'water', 'internet', 'wifi', 'tokens', 'kplc', 'zuku', 'utilities']},
    {'name': 'wifi', 'icon': Icons.wifi, 'label': 'Internet', 'keywords': ['data', 'broadband', 'fiber']},
    {'name': 'transport', 'icon': Icons.directions_car, 'label': 'Transport', 'keywords': ['uber', 'bolt', 'fuel', 'petrol', 'matatu', 'bus', 'taxi', 'transport']},
    {'name': 'shopping', 'icon': Icons.shopping_bag, 'label': 'Shopping', 'keywords': ['clothes', 'mall', 'jumia', 'amazon', 'supermarket', 'shopping']},
    {'name': 'entertainment', 'icon': Icons.movie, 'label': 'Entertainment', 'keywords': ['netflix', 'cinema', 'gaming', 'ps5', 'club', 'party', 'entertainment']},
    {'name': 'rent', 'icon': Icons.home, 'label': 'Rent/Home', 'keywords': ['house', 'apartment', 'repairs', 'furniture', 'rent']},
    {'name': 'health', 'icon': Icons.health_and_safety, 'label': 'Health', 'keywords': ['pharmacy', 'medicine', 'checkup', 'dentist', 'health']},
    {'name': 'medication', 'icon': Icons.medication, 'label': 'Medication', 'keywords': ['drugs', 'pharmacy', 'prescription']},
    {'name': 'hospital', 'icon': Icons.local_hospital, 'label': 'Hospital', 'keywords': ['emergency', 'surgery', 'clinic', 'doctor', 'hospital']},
    {'name': 'education', 'icon': Icons.school, 'label': 'Education', 'keywords': ['fees', 'books', 'course', 'tuition', 'uni', 'education']},
    {'name': 'gym', 'icon': Icons.fitness_center, 'label': 'Gym/Fitness', 'keywords': ['workout', 'protein', 'sports', 'football', 'gym']},
    {'name': 'savings', 'icon': Icons.savings, 'label': 'Savings', 'keywords': ['investment', 'sacco', 'emergency fund', 'crypto', 'savings']},
    {'name': 'travel', 'icon': Icons.flight, 'label': 'Travel', 'keywords': ['vacation', 'trip', 'flight', 'hotel', 'airbnb', 'tour', 'travel']},
    {'name': 'gifts', 'icon': Icons.card_giftcard, 'label': 'Gifts', 'keywords': ['birthday', 'wedding', 'donation', 'charity', 'gifts']},
    {'name': 'maintenance', 'icon': Icons.build, 'label': 'Maintenance', 'keywords': ['car repair', 'plumbing', 'electrician', 'maintenance']},
    {'name': 'subscriptions', 'icon': Icons.subscriptions, 'label': 'Subscriptions', 'keywords': ['youtube', 'spotify', 'apple', 'icloud', 'subscriptions']},
    {'name': 'work', 'icon': Icons.work, 'label': 'Work/Salary', 'keywords': ['office', 'business', 'tools', 'laptop', 'work']},
    {'name': 'pets', 'icon': Icons.pets, 'label': 'Pets', 'keywords': ['dog', 'cat', 'vet', 'pet food']},
    {'name': 'bills', 'icon': Icons.receipt_long, 'label': 'Bills', 'keywords': ['invoice', 'bill', 'payment']},
    {'name': 'insurance', 'icon': Icons.verified_user, 'label': 'Insurance', 'keywords': ['policy', 'coverage']},
    {'name': 'family', 'icon': Icons.family_restroom, 'label': 'Family', 'keywords': ['kids', 'parents', 'home']},
    {'name': 'beauty', 'icon': Icons.face, 'label': 'Beauty', 'keywords': ['salon', 'barber', 'makeup', 'spa']},
    {'name': 'donations', 'icon': Icons.volunteer_activism, 'label': 'Donations', 'keywords': ['church', 'tithe', 'charity']},
    {'name': 'other', 'icon': Icons.category, 'label': 'Other', 'keywords': []},
  ];

  /// Gets the best matching icon based on an explicit key OR a category name.
  static IconData getIcon(String? iconKey, [String? categoryName]) {
    final key = iconKey?.toLowerCase();
    final name = categoryName?.toLowerCase() ?? '';

    // 1. Exact match by key (the primary way)
    if (key != null) {
      final match = availableIcons.firstWhere(
        (e) => e['name'] == key,
        orElse: () => {},
      );
      if (match.isNotEmpty) return match['icon'] as IconData;
    }

    // 2. Fuzzy match by category name (the fallback for old/unmapped categories)
    if (name.isNotEmpty) {
      for (var item in availableIcons) {
        final iconName = item['name'] as String;
        final keywords = List<String>.from(item['keywords'] ?? []);
        
        // Check if name contains the icon name or any keyword
        if (name.contains(iconName) || keywords.any((k) => name.contains(k))) {
          return item['icon'] as IconData;
        }
      }
    }

    return Icons.category;
  }
}
