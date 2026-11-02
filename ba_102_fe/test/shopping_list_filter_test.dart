import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detaiil_category.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShoppingListFilter logic tests', () {
    test('ShoppingListFilterResult isActive reflects categoryIds and priceRange', () {
      final emptyResult = ShoppingListFilterResult(
        categoryIds: {},
        priceRange: null,
      );
      expect(emptyResult.isActive, isFalse);

      final catResult = ShoppingListFilterResult(
        categoryIds: {'cat_1'},
        priceRange: null,
      );
      expect(catResult.isActive, isTrue);

      final priceResult = ShoppingListFilterResult(
        categoryIds: {},
        priceRange: const RangeValues(10, 100),
      );
      expect(priceResult.isActive, isTrue);
    });

    test('Filter items by Category and Price Range strictly bounded', () {
      final cat1 = CategoryDraft(
        id: 'cat_dairy',
        name: 'Dairy',
        color: Colors.blue,
        items: [
          CategoryItemDraft(
            id: 'item_milk',
            name: 'Milk',
            quantity: 1,
            price: 150.0,
          ),
          CategoryItemDraft(
            id: 'item_cheese',
            name: 'Cheese',
            quantity: 1,
            price: 800.0,
          ),
        ],
      );

      final cat2 = CategoryDraft(
        id: 'cat_bakery',
        name: 'Bakery',
        color: Colors.orange,
        items: [
          CategoryItemDraft(
            id: 'item_bread',
            name: 'Bread',
            quantity: 1,
            price: 65.0,
          ),
        ],
      );

      final allCategories = [cat1, cat2];

      // Dynamic max existent price calculation
      double maxPrice = 0.0;
      for (final cat in allCategories) {
        for (final item in cat.items) {
          if (item.price > maxPrice) {
            maxPrice = item.price;
          }
        }
      }
      expect(maxPrice, equals(800.0));

      // Filter: price between 0 and 200
      const range = RangeValues(0, 200);
      final filtered1 = cat1.items.where((i) => i.price >= range.start && i.price <= range.end).toList();
      expect(filtered1.length, equals(1));
      expect(filtered1.first.name, equals('Milk'));

      // Filter: only cat_bakery
      final activeCategories = allCategories.where((c) => {'cat_bakery'}.contains(c.id)).toList();
      expect(activeCategories.length, equals(1));
      expect(activeCategories.first.name, equals('Bakery'));

      // Clean up controllers
      cat1.dispose();
      cat2.dispose();
    });
  });
}

