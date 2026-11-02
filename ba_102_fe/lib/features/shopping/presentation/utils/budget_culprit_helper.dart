import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/shopping_list_detaiil_category.dart';
import 'package:intl/intl.dart';

class BudgetCulprit {
  final CategoryItemDraft item;
  final String categoryName;
  final double overspend;
  final double itemTotal;
  final String recommendation;

  const BudgetCulprit({
    required this.item,
    required this.categoryName,
    required this.overspend,
    required this.itemTotal,
    required this.recommendation,
  });
}

class BudgetCulpritHelper {
  static final NumberFormat _formatter = NumberFormat('#,###');

  /// Finds the likeliest culprit within a specific category whose items exceed categoryBudget
  static BudgetCulprit? findCategoryCulprit(CategoryDraft category) {
    final budget = category.categoryBudget;
    if (budget == null || budget <= 0) return null;
    final overspend = category.total - budget;
    if (overspend <= 0) return null;

    final candidate = _pickBestCulprit(category.items, overspend);
    if (candidate == null) return null;

    final catName = category.name.trim().isEmpty ? 'Category' : category.name.trim();
    final recommendation = _generateRecommendation(candidate, overspend);

    return BudgetCulprit(
      item: candidate,
      categoryName: catName,
      overspend: overspend,
      itemTotal: candidate.total,
      recommendation: recommendation,
    );
  }

  /// Finds the likeliest culprit across all categories for total budget overspend
  static BudgetCulprit? findOverallCulprit(
    List<CategoryDraft> categories,
    double totalOverspend,
  ) {
    if (totalOverspend <= 0) return null;

    final allItemsWithCat = <_ItemWithCat>[];
    for (final cat in categories) {
      for (final item in cat.items) {
        if (item.total > 0) {
          allItemsWithCat.add(_ItemWithCat(item: item, categoryName: cat.name));
        }
      }
    }

    if (allItemsWithCat.isEmpty) return null;

    // Pick best culprit item
    final itemsOnly = allItemsWithCat.map((e) => e.item).toList();
    final candidate = _pickBestCulprit(itemsOnly, totalOverspend);
    if (candidate == null) return null;

    final matched = allItemsWithCat.firstWhere((e) => e.item == candidate);
    final catName =
        matched.categoryName.trim().isEmpty ? 'General' : matched.categoryName.trim();
    final recommendation = _generateRecommendation(candidate, totalOverspend);

    return BudgetCulprit(
      item: candidate,
      categoryName: catName,
      overspend: totalOverspend,
      itemTotal: candidate.total,
      recommendation: recommendation,
    );
  }

  /// Heuristic to select the best culprit:
  /// 1. Items with item.total >= overspend: choose the one with minimum surplus (item.total - overspend)
  ///    so reducing/removing it evens it out cleanly with minimal collateral disruption.
  /// 2. If no item has total >= overspend: choose the item with the highest total (biggest deficit contributor).
  static CategoryItemDraft? _pickBestCulprit(
    List<CategoryItemDraft> items,
    double overspend,
  ) {
    final validItems = items.where((i) => i.total > 0).toList();
    if (validItems.isEmpty) return null;

    final coveringItems = validItems.where((i) => i.total >= overspend).toList();

    if (coveringItems.isNotEmpty) {
      coveringItems.sort((a, b) => (a.total - overspend).compareTo(b.total - overspend));
      return coveringItems.first;
    }

    // Fallback: item with the largest total
    validItems.sort((a, b) => b.total.compareTo(a.total));
    return validItems.first;
  }

  /// Generates a concrete, actionable recommendation to even out the budget
  static String _generateRecommendation(
    CategoryItemDraft item,
    double overspend,
  ) {
    final qty = item.quantity;
    final price = item.price;
    final itemName = item.name.isEmpty ? 'this item' : item.name;

    if (qty > 1 && price > 0) {
      // Check if reducing quantity can balance the overspend
      final unitsToCut = (overspend / price).ceil();
      if (unitsToCut < qty) {
        final newQty = (qty - unitsToCut).toInt();
        final saved = unitsToCut * price;
        return 'Reduce $itemName qty from ${qty.toInt()} to $newQty (saves KES ${_formatter.format(saved)})';
      }
    }

    // Removing or reducing item
    if (item.total >= overspend) {
      return 'Remove or replace $itemName (saves KES ${_formatter.format(item.total)})';
    } else {
      return 'Reduce or remove $itemName to cut deficit by KES ${_formatter.format(item.total)}';
    }
  }
}

class _ItemWithCat {
  final CategoryItemDraft item;
  final String categoryName;
  const _ItemWithCat({required this.item, required this.categoryName});
}

