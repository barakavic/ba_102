import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/providers/categories_provider.dart';
import 'package:ba_102_fe/features/transactions/presentation/transactions_page.dart';
import 'package:ba_102_fe/services/icon_service.dart';
import 'package:ba_102_fe/services/categorization_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class CategoryDetailsPage extends StatelessWidget {
  final Category category;

  const CategoryDetailsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    double totalSpent = 0;
    double totalReceived = 0;

    for (var tx in category.transactions) {
      final type = tx.type?.toLowerCase();
      if (type == 'inbound' || type == 'deposit') {
        totalReceived += (tx.amount ?? 0);
      } else {
        totalSpent += (tx.amount ?? 0);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("TOTAL RECEIVED", totalReceived, Colors.green),
                _buildStatCard("TOTAL SPENT", totalSpent, Colors.red),
              ],
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
                        final isIncome = tx.type?.toLowerCase() == 'inbound' || tx.type?.toLowerCase() == 'deposit';
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              title: Text(tx.description ?? 'No description', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              subtitle: Text(
                                'Date: ${tx.date?.toIso8601String().substring(0, 10) ?? 'N/A'}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${isIncome ? '+' : '-'}KES ${tx.amount?.toStringAsFixed(0) ?? '0'}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.drive_file_move_outlined, 
                                      color: category.id == -1 ? Colors.orange : Colors.grey.shade400,
                                      size: 18,
                                    ),
                                    onPressed: () => _showMoveDialog(context, tx),
                                  ),
                                ],
                              ),
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "RAW M-PESA MESSAGE",
                                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        tx.rawSmsMessage ?? "No raw message available.",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade800,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
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

  Widget _buildStatCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color.withOpacity(0.7), letterSpacing: 1.0),
            ),
            const SizedBox(height: 4),
            Text(
              'KES ${amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
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
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      title: const Text('Move to Category'),
      content: SizedBox(
        width: double.maxFinite,
        child: categoriesAsync.when(
          data: (categories) {
            final validCategories = categories.where((c) => c.id != -1).toList();
            final parents = validCategories.where((c) => c.parentId == null).toList();
            final List<Category> sortedList = [];
            for (var p in parents) {
              sortedList.add(p);
              sortedList.addAll(validCategories.where((c) => c.parentId == p.id));
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: sortedList.length,
              itemBuilder: (context, index) {
                final cat = sortedList[index];
                final isChild = cat.parentId != null;

                return ListTile(
                  dense: isChild,
                  contentPadding: EdgeInsets.only(left: isChild ? 32 : 16, right: 16),
                  leading: Icon(
                    IconService.getIcon(cat.icon, cat.name),
                    size: isChild ? 18 : 22,
                    color: isChild ? Colors.grey.shade400 : Colors.blue.shade700,
                  ),
                  title: Text(
                    cat.name,
                    style: TextStyle(
                      fontWeight: isChild ? FontWeight.normal : FontWeight.bold,
                      fontSize: isChild ? 14 : 15,
                      color: isChild ? Colors.black87 : Colors.black,
                    ),
                  ),
                  onTap: () async {
                    final db = await DatabaseHelper.instance.database;
                    final vendor = transaction.vendor;
                    
                    bool shouldPop = false;

                    if (vendor != null && vendor.isNotEmpty) {
                      final result = await db.rawQuery(
                        'SELECT COUNT(*) as count FROM transactions WHERE vendor = ? AND (category_id != ? OR category_id IS NULL) AND id != ?',
                        [vendor, cat.id, transaction.id],
                      );
                      int otherCount = sqflite.Sqflite.firstIntValue(result) ?? 0;

                      if (otherCount > 0) {
                        if (!context.mounted) return;
                        final bool? applyToAll = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Apply to all?'),
                            content: Text('We found $otherCount other transactions from "$vendor". Do you want to move all of them to "${cat.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('JUST THIS ONE', style: TextStyle(color: Colors.grey.shade600)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('MOVE ALL', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );

                        if (applyToAll == null) return; // User dismissed dialog

                        if (applyToAll) {
                          await db.update(
                            'transactions',
                            {'category_id': cat.id},
                            where: 'vendor = ?',
                            whereArgs: [vendor],
                          );
                        } else {
                          await db.update(
                            'transactions',
                            {'category_id': cat.id},
                            where: 'id = ?',
                            whereArgs: [transaction.id],
                          );
                        }
                        shouldPop = true;
                      } else {
                        await db.update(
                          'transactions',
                          {'category_id': cat.id},
                          where: 'id = ?',
                          whereArgs: [transaction.id],
                        );
                        shouldPop = true;
                      }
                      
                      // Always save the mapping for future transactions
                      await CategorizationService().saveVendorMapping(vendor, cat.id);
                    } else {
                      // No vendor, just update this one
                      await db.update(
                        'transactions',
                        {'category_id': cat.id},
                        where: 'id = ?',
                        whereArgs: [transaction.id],
                      );
                      shouldPop = true;
                    }

                    if (shouldPop && context.mounted) {
                      ref.invalidate(categoriesProvider);
                      ref.invalidate(txProv);
                      Navigator.pop(context); // Close selection dialog
                      Navigator.pop(context); // Go back to categories page
                    }
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