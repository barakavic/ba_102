import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class CategorizationService {
  static final CategorizationService _instance = CategorizationService._internal();
  factory CategorizationService() => _instance;
  CategorizationService._internal();

  // Hardcoded rules for initial auto-categorization
  final Map<String, String> _hardcodedRules = {
    'safaricom data bundles': 'Utilities',
    'safaricom airtime': 'Utilities',
    'kplc': 'Utilities',
    'kfc': 'Food',
    'uber': 'Transport',
    'bolt': 'Transport',
    'zuku': 'Utilities',
    'netflix': 'Entertainment',
    'airtel': 'Utilities',
    'naivas': 'Shopping',
    'carrefour': 'Shopping',
    'jumia': 'Shopping',
    'java house': 'Food',
    'pizza inn': 'Food',
    'chicken inn': 'Food',
  };

  Future<int?> getCategoryIdForVendor(String vendorName) async {
    final db = await DatabaseHelper.instance.database;
    
    // 1. Check user-defined mappings in DB
    final List<Map<String, dynamic>> maps = await db.query(
      'vendor_mappings',
      where: 'vendor_name = ?',
      whereArgs: [vendorName.toLowerCase()],
    );

    if (maps.isNotEmpty) {
      return maps.first['category_id'] as int?;
    }

    // 2. Check hardcoded rules
    String? categoryName;
    final lowerVendor = vendorName.toLowerCase();
    
    for (var entry in _hardcodedRules.entries) {
      if (lowerVendor.contains(entry.key)) {
        categoryName = entry.value;
        break;
      }
    }

    if (categoryName != null) {
      // Find the ID for this category name (case-insensitive)
      final List<Map<String, dynamic>> catMaps = await db.query(
        'budget_category',
        where: 'LOWER(name) = ?',
        whereArgs: [categoryName.toLowerCase()],
      );
      
      if (catMaps.isNotEmpty) {
        return catMaps.first['id'] as int?;
      }
    }

    return null; // Uncategorized
  }

  Future<void> saveVendorMapping(String vendorName, int categoryId) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'vendor_mappings',
      {
        'vendor_name': vendorName.toLowerCase(),
        'category_id': categoryId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> recategorizeUncategorizedTransactions() async {
    final db = await DatabaseHelper.instance.database;
    
    // Find all transactions with no category
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'category_id IS NULL',
    );

    int count = 0;
    for (var map in maps) {
      final vendor = map['vendor'] as String?;
      if (vendor != null) {
        final newCatId = await getCategoryIdForVendor(vendor);
        if (newCatId != null) {
          await db.update(
            'transactions',
            {'category_id': newCatId},
            where: 'id = ?',
            whereArgs: [map['id']],
          );
          count++;
        }
      }
    }
    return count;
  }
}
