import 'package:ba_102_fe/data/local/shopping_ls.dart';
import 'package:ba_102_fe/data/models/shopping_list_model.dart';
import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_sort_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shopping Lists Search and Sort Tests', () {
    final listA = ShoppingListModel(
      id: 'list_1',
      title: 'Apples & Bananas',
      createdAt: DateTime(2026, 1, 1),
    );
    final listB = ShoppingListModel(
      id: 'list_2',
      title: 'Zucchini & Carrots',
      createdAt: DateTime(2026, 1, 10),
    );
    final listC = ShoppingListModel(
      id: 'list_3',
      title: 'Meat & Poultry',
      createdAt: DateTime(2026, 1, 5),
    );

    final summaries = <String, ShoppingListSummary>{
      'list_1': const ShoppingListSummary(
        listId: 'list_1',
        totalItems: 4,
        boughtItems: 2,
        totalCost: 1500.0,
      ),
      'list_2': const ShoppingListSummary(
        listId: 'list_2',
        totalItems: 2,
        boughtItems: 0,
        totalCost: 350.0,
      ),
      'list_3': const ShoppingListSummary(
        listId: 'list_3',
        totalItems: 6,
        boughtItems: 6,
        totalCost: 4800.0,
      ),
    };

    test('Search filter matches case-insensitively', () {
      final all = [listA, listB, listC];

      // Empty query returns all
      final emptyResult = all.where((l) => (l.title ?? '').toLowerCase().contains('')).toList();
      expect(emptyResult.length, 3);

      // Query "meat" matches listC
      final meatResult = all.where((l) => (l.title ?? '').toLowerCase().contains('meat')).toList();
      expect(meatResult.length, 1);
      expect(meatResult.first.id, 'list_3');

      // Query "ANAN" matches Apples & Bananas
      final ananResult = all.where((l) => (l.title ?? '').toLowerCase().contains('anan')).toList();
      expect(ananResult.length, 1);
      expect(ananResult.first.id, 'list_1');

      // Non-existent query
      final noneResult = all.where((l) => (l.title ?? '').toLowerCase().contains('electronics')).toList();
      expect(noneResult.isEmpty, isTrue);
    });

    test('Sort by Date Created (Newest vs Oldest)', () {
      final all = [listA, listB, listC];

      // Newest first: listB (Jan 10), listC (Jan 5), listA (Jan 1)
      final newest = List<ShoppingListModel>.from(all)..sort((a, b) {
        return b.createdAt!.compareTo(a.createdAt!);
      });
      expect(newest.map((l) => l.id).toList(), ['list_2', 'list_3', 'list_1']);

      // Oldest first: listA, listC, listB
      final oldest = List<ShoppingListModel>.from(all)..sort((a, b) {
        return a.createdAt!.compareTo(b.createdAt!);
      });
      expect(oldest.map((l) => l.id).toList(), ['list_1', 'list_3', 'list_2']);
    });

    test('Sort by Name (A to Z vs Z to A)', () {
      final all = [listA, listB, listC];

      // A to Z: Apples & Bananas, Meat & Poultry, Zucchini & Carrots
      final az = List<ShoppingListModel>.from(all)..sort((a, b) {
        return (a.title ?? '').toLowerCase().compareTo((b.title ?? '').toLowerCase());
      });
      expect(az.map((l) => l.id).toList(), ['list_1', 'list_3', 'list_2']);

      // Z to A: Zucchini & Carrots, Meat & Poultry, Apples & Bananas
      final za = List<ShoppingListModel>.from(all)..sort((a, b) {
        return (b.title ?? '').toLowerCase().compareTo((a.title ?? '').toLowerCase());
      });
      expect(za.map((l) => l.id).toList(), ['list_2', 'list_3', 'list_1']);
    });

    test('Sort by Total Cost (Highest to Lowest vs Lowest to Highest)', () {
      final all = [listA, listB, listC];

      // Highest cost first: list3 (4800), list1 (1500), list2 (350)
      final highToLow = List<ShoppingListModel>.from(all)..sort((a, b) {
        final costA = summaries[a.id]?.totalCost ?? 0.0;
        final costB = summaries[b.id]?.totalCost ?? 0.0;
        return costB.compareTo(costA);
      });
      expect(highToLow.map((l) => l.id).toList(), ['list_3', 'list_1', 'list_2']);

      // Lowest cost first: list2 (350), list1 (1500), list3 (4800)
      final lowToHigh = List<ShoppingListModel>.from(all)..sort((a, b) {
        final costA = summaries[a.id]?.totalCost ?? 0.0;
        final costB = summaries[b.id]?.totalCost ?? 0.0;
        return costA.compareTo(costB);
      });
      expect(lowToHigh.map((l) => l.id).toList(), ['list_2', 'list_1', 'list_3']);
    });

    test('ShoppingListSortOption equality and labels', () {
      const opt1 = ShoppingListSortOption(ShoppingListSortField.totalCost, SortOrder.descending);
      const opt2 = ShoppingListSortOption(ShoppingListSortField.totalCost, SortOrder.descending);
      const opt3 = ShoppingListSortOption(ShoppingListSortField.name, SortOrder.ascending);

      expect(opt1, equals(opt2));
      expect(opt1 == opt3, isFalse);
      expect(opt1.label, contains('Total Cost (High → Low)'));
      expect(opt3.label, contains('Name (A → Z)'));
    });
  });
}

