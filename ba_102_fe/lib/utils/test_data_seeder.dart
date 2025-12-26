import 'package:sqflite/sqflite.dart';

class TestDataSeeder {
  static Future<int> seedTestTransactions(Database db) async {
    final List<Map<String, dynamic>> categories = await db.query('budget_category');
    final Map<String, int> catMap = {for (var c in categories) c['name'] as String: c['id'] as int};

    final now = DateTime.now();
    final List<Map<String, dynamic>> testData = [
      // Food
      {'desc': 'Lunch at KFC', 'amt': 1200.0, 'vendor': 'KFC', 'cat': 'Food', 'days': 2},
      {'desc': 'Java House Coffee', 'amt': 450.0, 'vendor': 'Java House', 'cat': 'Food', 'days': 1},
      {'desc': 'Pizza Inn Dinner', 'amt': 2100.0, 'vendor': 'Pizza Inn', 'cat': 'Food', 'days': 5},
      {'desc': 'Burger King', 'amt': 850.0, 'vendor': 'Burger King', 'cat': 'Food', 'days': 8},
      {'desc': 'Lunch at KFC', 'amt': 1100.0, 'vendor': 'KFC', 'cat': 'Food', 'days': 12},
      
      // Utilities
      {'desc': 'Kenya Power Token', 'amt': 2000.0, 'vendor': 'Kenya Power', 'cat': 'Utilities', 'days': 15},
      {'desc': 'Zuku Internet', 'amt': 4500.0, 'vendor': 'Zuku', 'cat': 'Utilities', 'days': 20},
      {'desc': 'Nairobi Water', 'amt': 800.0, 'vendor': 'Nairobi Water', 'cat': 'Utilities', 'days': 25},
      
      // Transport
      {'desc': 'Uber Trip', 'amt': 650.0, 'vendor': 'Uber', 'cat': 'Transport', 'days': 1},
      {'desc': 'Shell Fuel', 'amt': 5000.0, 'vendor': 'Shell', 'cat': 'Transport', 'days': 3},
      {'desc': 'Bolt Ride', 'amt': 400.0, 'vendor': 'Bolt', 'cat': 'Transport', 'days': 4},
      {'desc': 'Uber Trip', 'amt': 800.0, 'vendor': 'Uber', 'cat': 'Transport', 'days': 7},
      {'desc': 'Total Energies', 'amt': 3000.0, 'vendor': 'Total', 'cat': 'Transport', 'days': 10},
      
      // Shopping
      {'desc': 'Naivas Groceries', 'amt': 4200.0, 'vendor': 'Naivas', 'cat': 'Shopping', 'days': 2},
      {'desc': 'Carrefour Items', 'amt': 7500.0, 'vendor': 'Carrefour', 'cat': 'Shopping', 'days': 6},
      {'desc': 'Quickmart Shopping', 'amt': 1200.0, 'vendor': 'Quickmart', 'cat': 'Shopping', 'days': 9},
      {'desc': 'Jumia Order', 'amt': 3400.0, 'vendor': 'Jumia', 'cat': 'Shopping', 'days': 14},
      
      // Entertainment
      {'desc': 'Netflix Subscription', 'amt': 1100.0, 'vendor': 'Netflix', 'cat': 'Entertainment', 'days': 28},
      {'desc': 'Spotify Premium', 'amt': 300.0, 'vendor': 'Spotify', 'cat': 'Entertainment', 'days': 28},
      {'desc': 'Showmax', 'amt': 760.0, 'vendor': 'Showmax', 'cat': 'Entertainment', 'days': 28},
      
      // Uncategorized / Mixed (for testing Smart Bulk Move)
      {'desc': 'Crank Investment Payment', 'amt': 5000.0, 'vendor': 'Crank Investment', 'cat': null, 'days': 1},
      {'desc': 'Crank Investment Payment', 'amt': 2500.0, 'vendor': 'Crank Investment', 'cat': null, 'days': 5},
      {'desc': 'Crank Investment Payment', 'amt': 3000.0, 'vendor': 'Crank Investment', 'cat': null, 'days': 10},
      {'desc': 'Mama Mboga', 'amt': 450.0, 'vendor': 'Mama Mboga', 'cat': null, 'days': 1},
      {'desc': 'Random Kiosk', 'amt': 120.0, 'vendor': 'Random Shop', 'cat': null, 'days': 2},
      {'desc': 'Pharmacy Meds', 'amt': 1500.0, 'vendor': 'Goodlife', 'cat': null, 'days': 3},
    ];

    int count = 0;
    for (var data in testData) {
      await db.insert('transactions', {
        'description': data['desc'],
        'amount': data['amt'],
        'vendor': data['vendor'],
        'category_id': data['cat'] != null ? catMap[data['cat']] : null,
        'date': now.subtract(Duration(days: data['days'] as int)).toIso8601String(),
        'type': 'outbound',
      });
      count++;
    }
    
    return count;
  }
}
