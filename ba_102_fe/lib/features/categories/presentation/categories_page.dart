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

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  Color _getCategoryColor(BuildContext context, Category category) {
    if (category.id == -1) return Colors.orange;
    if (category.color != null) {
      try {
        return Color(int.parse(category.color!));
      } catch (_) {}
    }
    return Theme.of(context).colorScheme.primary;
  }

  Map<String, double> _getCategoryStats(Category parent, List<Category> allCategories) {
    double spent = 0;
    double received = 0;

    void processTransactions(List<Transaction> txs) {
      for (var tx in txs) {
        final type = tx.type?.toLowerCase();
        if (type == 'inbound' || type == 'deposit') {
          received += (tx.amount ?? 0);
        } else {
          spent += (tx.amount ?? 0);
        }
      }
    }

    processTransactions(parent.transactions);
    final children = allCategories.where((c) => c.parentId == parent.id);
    for (var child in children) {
      processTransactions(child.transactions);
    }

    return {'spent': spent, 'received': received};
  }

  int _getTotalItems(Category parent, List<Category> allCategories) {
    int total = parent.transactions.length;
    final children = allCategories.where((c) => c.parentId == parent.id);
    for (var child in children) {
      total += child.transactions.length;
    }
    return total;
  }

  void _showMoveCategoryDialog(BuildContext context, WidgetRef ref, Category category, List<Category> allCategories) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move "${category.name}"'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select a parent category or move to Top-Level:"),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allCategories.where((c) => 
                    c.parentId == null && 
                    c.id != category.id && 
                    c.id != -1
                  ).length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.grid_view, color: Colors.grey),
                        title: const Text("None (Top-Level)"),
                        selected: category.parentId == null,
                        onTap: () async {
                          final db = await DatabaseHelper.instance.database;
                          await CategoryLs(db).updateCategory(category.copyWith(parentId: null));
                          ref.refresh(categoriesProvider);
                          Navigator.pop(context);
                        },
                      );
                    }
                    
                    final potentialParents = allCategories.where((c) => 
                      c.parentId == null && 
                      c.id != category.id && 
                      c.id != -1
                    ).toList();
                    final parent = potentialParents[index - 1];
                    
                    // Check if current category has children (it can't be a child then)
                    final hasChildren = allCategories.any((c) => c.parentId == category.id);
                    
                    return ListTile(
                      leading: Icon(IconService.getIcon(parent.icon, parent.name), color: _getCategoryColor(context, parent)),
                      title: Text(parent.name),
                      enabled: !hasChildren,
                      subtitle: hasChildren ? const Text("Cannot move: has sub-categories", style: TextStyle(fontSize: 10, color: Colors.orange)) : null,
                      onTap: () async {
                        final db = await DatabaseHelper.instance.database;
                        await CategoryLs(db).updateCategory(category.copyWith(parentId: parent.id));
                        ref.refresh(categoriesProvider);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ],
      ),
    );
  }

  void _showSubCategories(BuildContext context, WidgetRef ref, Category parent, List<Category> subCategories, List<Category> allCategories) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = _getCategoryColor(context, parent);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(IconService.getIcon(parent.icon, parent.name), color: categoryColor, size: 24),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Sub-categories",
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: subCategories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.list_alt, color: Colors.grey),
                      title: Text("View all ${parent.name} items"),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CategoryDetailsPage(category: parent)),
                        );
                      },
                    );
                  }
                  final sub = subCategories[index - 1];
                  final subColor = _getCategoryColor(context, sub);
                  return ListTile(
                    leading: Icon(IconService.getIcon(sub.icon, sub.name), color: subColor),
                    title: Text(sub.name),
                    subtitle: Text("${sub.transactions.length} items"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "In: KES ${NumberFormat('#,###').format(sub.transactions.where((tx) => tx.type?.toLowerCase() == 'inbound' || tx.type?.toLowerCase() == 'deposit').fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0)))}",
                              style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Out: KES ${NumberFormat('#,###').format(sub.transactions.where((tx) => tx.type?.toLowerCase() != 'inbound' && tx.type?.toLowerCase() != 'deposit').fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0)))}",
                              style: const TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: (val) async {
                            if (val == 'move') {
                              Navigator.pop(context);
                              _showMoveCategoryDialog(context, ref, sub, allCategories);
                            } else if (val == 'edit') {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CatFormPage(planId: 0, category: sub)),
                              );
                            } else if (val == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Category'),
                                  content: Text('Are you sure you want to delete "${sub.name}"? Transactions will be moved to Uncategorized.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final db = await DatabaseHelper.instance.database;
                                await CategoryLs(db).deleteCategory(sub.id);
                                ref.refresh(categoriesProvider);
                                if (context.mounted) Navigator.pop(context);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(value: 'move', child: Text('Move')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CategoryDetailsPage(category: sub)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final colorScheme = Theme.of(context).colorScheme;

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

            final topLevelCategories = categories.where((c) => c.parentId == null).toList();

            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: topLevelCategories.length,
                itemBuilder: (context, index) {
                  final category = topLevelCategories[index];
                  final color = _getCategoryColor(context, category);
                  final icon = IconService.getIcon(category.icon, category.name);
                  final subCategories = categories.where((c) => c.parentId == category.id).toList();
                  final stats = _getCategoryStats(category, categories);
                  final totalItems = _getTotalItems(category, categories);

                  return GestureDetector(
                    onTap: () {
                      if (subCategories.isNotEmpty) {
                        _showSubCategories(context, ref, category, subCategories, categories);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryDetailsPage(category: category),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
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
                                icon: Icon(Icons.more_vert, size: 18, color: colorScheme.onSurface.withOpacity(0.4)),
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
                                  } else if (value == 'move') {
                                    _showMoveCategoryDialog(context, ref, category, categories);
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
                                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  const PopupMenuItem(value: 'move', child: Text('Move')),
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
                                  style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                 const SizedBox(height: 4),
                                Text(
                                  '$totalItems items',
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    color: colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                if (subCategories.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "${subCategories.length} sub-categories",
                                      style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        Text("RECEIVED", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withOpacity(0.4))),
                                        Text(
                                          NumberFormat('#,###').format(stats['received']),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      children: [
                                        Text("SPENT", style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: colorScheme.onSurface.withOpacity(0.4))),
                                        Text(
                                          NumberFormat('#,###').format(stats['spent']),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ],
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
        backgroundColor: colorScheme.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CatFormPage(planId: 0)),
          );
        },
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }
}