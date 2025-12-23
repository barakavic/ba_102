import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/features/categories/presentation/categories_page.dart';
import 'package:ba_102_fe/features/transactions/presentation/transactions_page.dart';
import 'package:ba_102_fe/services/categorization_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:ba_102_fe/data/models/models.dart';

class CategoryDetailsPage extends StatelessWidget {
  final Category category;

  const CategoryDetailsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final totalSpent = category.transactions.fold<double>(0.0, (sum, tx) => sum + (tx.amount ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total spent: ${totalSpent.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            Expanded(
              child: category.transactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No Transactions Yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: category.transactions.length,
                      itemBuilder: (context, index) {
                        final tx = category.transactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(tx.description ?? 'No description'),
                            subtitle: Text(
                              'Date: ${tx.date?.toIso8601String().substring(0, 10) ?? 'N/A'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tx.amount?.toStringAsFixed(2) ?? '0.00',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (category.id == -1) // Uncategorized
                                  IconButton(
                                    icon: const Icon(Icons.drive_file_move_outlined, color: Colors.orange),
                                    onPressed: () => _showMoveDialog(context, tx),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }

  void _showMoveDialog(BuildContext context, Transaction tx) {
    showDialog(
      context: context,
      builder: (context) => CategorySelectionDialog(transaction: tx),
    );
  }
}

class CategorySelectionDialog extends ConsumerWidget {
  final Transaction transaction;
  const CategorySelectionDialog({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(CategoriesProvider);

    return AlertDialog(
      title: const Text('Move to Category'),
      content: SizedBox(
        width: double.maxFinite,
        child: categoriesAsync.when(
          data: (categories) {
            final validCategories = categories.where((c) => c.id != -1).toList();
            return ListView.builder(
              shrinkWrap: true,
              itemCount: validCategories.length,
              itemBuilder: (context, index) {
                final cat = validCategories[index];
                return ListTile(
                  title: Text(cat.name),
                  onTap: () async {
                    final db = await DatabaseHelper.instance.database;

                    // 1. Update the transaction
                    await db.update(
                      'transactions',
                      {'category_id': cat.id},
                      where: 'id = ?',
                      whereArgs: [transaction.id],
                    );

                    // 2. Save the vendor mapping for future auto-categorization
                    if (transaction.vendor != null) {
                      await CategorizationService().saveVendorMapping(
                        transaction.vendor!,
                        cat.id,
                      );
                    }

                    ref.invalidate(CategoriesProvider);
                    ref.invalidate(txProv);
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to categories page to refresh
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text('Error: $err'),
        ),
      ),
    );
  }
}