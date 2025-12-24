import 'package:ba_102_fe/data/local/category_ls.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/ui/pages/categoryDetailsPage.dart';
import 'package:ba_102_fe/features/categories/presentation/cat_form_page.dart';
import 'package:ba_102_fe/services/categorization_service.dart';
import 'package:ba_102_fe/services/icon_service.dart';
import 'package:ba_102_fe/providers/categories_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

const Color priColor = Color(0xFF4B0082);



class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  Color _getCategoryColor(Category category) {
    if (category.id == -1) return Colors.orange;
    if (category.color != null) {
      try {
        return Color(int.parse(category.color!));
      } catch (_) {}
    }
    return priColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await CategorizationService().recategorizeUncategorizedTransactions();
          ref.invalidate(categoriesProvider);
          await ref.read(categoriesProvider.future);
        },
        child: categoriesAsync.when(
          data: (categories) {
            if (categories.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text('No categories found')),
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final color = _getCategoryColor(category);
                  final icon = IconService.getIcon(category.icon, category.name);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryDetailsPage(category: category),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: color.withOpacity(0.1)),
                      ),
                      child: Stack(
                        children: [
                          if (category.id != -1)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CatFormPage(
                                          planId: 0,
                                          category: category,
                                        ),
                                      ),
                                    );
                                  } else if (value == 'delete') {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Category'),
                                        content: Text('Are you sure you want to delete "${category.name}"? Transactions will be moved to Uncategorized.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      final db = await DatabaseHelper.instance.database;
                                      await CategoryLs(db).deleteCategory(category.id);
                                      ref.refresh(categoriesProvider);
                                    }
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Edit / Rename')),
                                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    category.id == -1 ? Icons.help_outline : icon,
                                    color: color,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  category.name,
                                  style: const TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${category.transactions.length} items',
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'KES ${NumberFormat('#,###').format(category.transactions.fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0)))}',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w900,
                                    color: color,
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
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_category_fab',
        backgroundColor: priColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CatFormPage(planId: 0)),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}