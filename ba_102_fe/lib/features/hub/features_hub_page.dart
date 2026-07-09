import 'package:flutter/material.dart';
import 'package:ba_102_fe/features/shopping/presentation/shopping_lists_page.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:ba_102_fe/features/categories/presentation/categories_page.dart';
import 'package:ba_102_fe/features/goals/presentation/goals_page.dart';

class FeaturesHubPage extends StatelessWidget {
  const FeaturesHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    final List<Map<String, dynamic>> features = [
      {
        'title': 'Shopping Lists',
        'subtitle': 'Manage and track list items',
        'icon': Icons.shopping_bag_outlined,
        'color': const Color(0xFFE91E63),
        'page': const ShoppingListsPage(),
      },
      {
        'title': 'Budget Plans',
        'subtitle': 'Set budget limits & targets',
        'icon': Icons.insights_outlined,
        'color': const Color(0xFF4B0082),
        'page': const PlansPage(),
      },
      {
        'title': 'Categories',
        'subtitle': 'Manage custom categories',
        'icon': Icons.category_outlined,
        'color': const Color(0xFF009688),
        'page': const CategoriesPage(),
      },
      {
        'title': 'Savings Goals',
        'subtitle': 'Track financial savings goals',
        'icon': Icons.savings_outlined,
        'color': const Color(0xFFFF9800),
        'page': const GoalsPage(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.95,
        ),
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          final Color accentColor = feature['color'];

          return Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: onSurface.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            color: colorScheme.surface,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => feature['page']),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        feature['icon'],
                        color: accentColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      feature['title'],
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['subtitle'],
                      style: TextStyle(
                        fontSize: 11,
                        color: onSurface.withValues(alpha: 0.5),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}