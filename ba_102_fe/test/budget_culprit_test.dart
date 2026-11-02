import 'package:ba_102_fe/features/shopping/presentation/utils/budget_culprit_helper.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detaiil_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetCulpritHelper', () {
    test('returns null when category is under or equal to budget', () {
      final category = CategoryDraft(
        id: '1',
        name: 'Groceries',
        color: Colors.blue,
        categoryBudget: 1000,
        items: [
          CategoryItemDraft(id: 'i1', name: 'Apples', price: 200, quantity: 2),
        ],
      );

      final culprit = BudgetCulpritHelper.findCategoryCulprit(category);
      expect(culprit, isNull);
    });

    test('picks best covering item and suggests quantity reduction when applicable', () {
      final category = CategoryDraft(
        id: '1',
        name: 'Groceries',
        color: Colors.blue,
        categoryBudget: 500,
        items: [
          CategoryItemDraft(id: 'i1', name: 'Bread', price: 100, quantity: 1), // total 100
          CategoryItemDraft(id: 'i2', name: 'Milk', price: 150, quantity: 4),  // total 600
        ], // category total = 700, overspend = 200
      );

      final culprit = BudgetCulpritHelper.findCategoryCulprit(category);
      expect(culprit, isNotNull);
      expect(culprit!.item.name, 'Milk');
      expect(culprit.overspend, 200);
      // Milk is 150 each, overspend 200 -> ceil(200/150) = 2 units to cut -> from 4 to 2 (saves 300)
      expect(culprit.recommendation, contains('qty from 4 to 2'));
    });

    test('picks closest covering item over massive item to minimize collateral disruption', () {
      final category = CategoryDraft(
        id: '1',
        name: 'Electronics & Snacks',
        color: Colors.blue,
        categoryBudget: 1000,
        items: [
          CategoryItemDraft(id: 'i1', name: 'Chips', price: 250, quantity: 1), // total 250
          CategoryItemDraft(id: 'i2', name: 'TV', price: 1000, quantity: 1),   // total 1000
        ], // total 1250, overspend 250
      );

      final culprit = BudgetCulpritHelper.findCategoryCulprit(category);
      expect(culprit, isNotNull);
      // Chips total 250 exactly covers overspend 250 (surplus 0) vs TV (surplus 750)
      expect(culprit!.item.name, 'Chips');
    });

    test('overall culprit picks best item across multiple categories', () {
      final cat1 = CategoryDraft(
        id: 'c1',
        name: 'Produce',
        color: Colors.green,
        items: [
          CategoryItemDraft(id: 'i1', name: 'Bananas', price: 200, quantity: 1),
        ],
      );
      final cat2 = CategoryDraft(
        id: 'c2',
        name: 'Dairy',
        color: Colors.blue,
        items: [
          CategoryItemDraft(id: 'i2', name: 'Cheese', price: 800, quantity: 1),
        ],
      );

      final categories = [cat1, cat2];
      // total = 1000, budget limit = 700 -> overspend 300
      final culprit = BudgetCulpritHelper.findOverallCulprit(categories, 300);
      expect(culprit, isNotNull);
      expect(culprit!.item.name, 'Cheese');
      expect(culprit.categoryName, 'Dairy');
    });
  });
}

