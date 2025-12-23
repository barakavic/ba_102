import 'package:ba_102_fe/data/local/category_ls.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/data/api/categoryService.dart';
import 'package:ba_102_fe/data/models/models.dart';

import 'package:ba_102_fe/ui/pages/categoryDetailsPage.dart';
import 'package:ba_102_fe/features/categories/presentation/cat_form_page.dart';

const Color priColor = Color(0xFF4B0082);

final CategoriesProvider = FutureProvider<List<Category>>((ref) async {
  
  try{
    // try Online
    final onlineCategory = await Categoryservice().fetchCategories();

    // save to offline later 
    final db = await DatabaseHelper.instance.database;
    final localService = await CategoryLs(db);


    for(var cat in onlineCategory){
      await localService.insertCategory(cat);

    }
    return onlineCategory;


    
  }
  catch(e){
    print('Fetching from local DB due to error: $e');
    final db = await DatabaseHelper.instance.database;
    final localService = await CategoryLs(db);
    final localCategory = localService.getCategories();
    return localCategory;

  }

//  return await Categoryservice().fetchCategories(); 
});
 

class CategoriesPage extends ConsumerWidget{
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final categoriesAsync = ref.watch(CategoriesProvider);
    return Scaffold(
      body: categoriesAsync.when(
        data: (categories){
          if (categories.isEmpty){
            return const Center(
              child:
               Text('No categories found'),);

          }

          return Padding(padding: const EdgeInsets.all(8.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
            ), 
            itemCount: categories.length,
            itemBuilder: (context, index){
              final category = categories[index];
              return GestureDetector(
                onTap: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: 
                    (_) => CategoryDetailsPage(category: category),
                    )
                  );

                },

                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  color: category.id == -1 ? Colors.orange.shade50 : Colors.white,
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
                      if (category.id != -1 && category.limitAmount > 0) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (category.transactions.fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0)) / category.limitAmount).clamp(0, 1),
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    (category.transactions.fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0)) > category.limitAmount)
                                        ? Colors.red
                                        : priColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'KES ${category.transactions.fold<double>(0, (sum, tx) => sum + (tx.amount ?? 0)).toStringAsFixed(0)} / ${category.limitAmount.toStringAsFixed(0)}',
                                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
              
              

            },

          
            ),);


        },
        loading: () => const Center(child: CircularProgressIndicator(),),
        error: (err, stack) =>Center(child: Text('Error: $err'),)
      ),

 

      floatingActionButton: FloatingActionButton(
      onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CatFormPage(planId: 0)), // Replace 0 with actual planId if needed
        );
      },
        child: const Icon(Icons.add),
      ),
    );
    
  }
}