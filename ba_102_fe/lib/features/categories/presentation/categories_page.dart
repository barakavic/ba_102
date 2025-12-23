import 'package:ba_102_fe/data/local/category_ls.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/ui/pages/categoryDetailsPage.dart';
import 'package:ba_102_fe/features/categories/presentation/cat_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Color priColor = Color(0xFF4B0082);

final CategoriesProvider = FutureProvider<List<Category>>((ref) async {
  try {
    final db = await DatabaseHelper.instance.database;
    final localService = CategoryLs(db);
    return await localService.getCategories();
  } catch (e) {
    print('Error fetching categories: $e');
    return [];
  }
});

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(CategoriesProvider);

    return Scaffold(
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryDetailsPage(category: category),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    color: category.id == -1 ? Colors.orange.shade50 : Colors.white,
                    child: Stack(
                      children: [
                        if (category.id != -1)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
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
                                    ref.refresh(CategoriesProvider);
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
                              Icon(
                                category.id == -1 ? Icons.help_outline : Icons.folder_open,
                                color: category.id == -1 ? Colors.orange : priColor,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category.name,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w600,
                                  color: category.id == -1 ? Colors.orange.shade900 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${category.transactions.length} Transactions',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                'Lifetime Total',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'KES ${category.transactions.fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0)).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: category.id == -1 ? Colors.orange.shade900 : priColor,
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
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_category_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CatFormPage(planId: 0)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}