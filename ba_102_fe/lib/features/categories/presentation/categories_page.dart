import 'package:ba_102_fe/data/local/category_ls.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/data/api/categoryService.dart';
import 'package:ba_102_fe/data/models/models.dart';

import 'package:ba_102_fe/ui/pages/categoryDetailsPage.dart';

final CategriesProvider = FutureProvider<List<Category>>((ref) async {
  
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

    final categoriesAsync = ref.watch(CategriesProvider);
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,
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
                  child: Center(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                                    
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
          // TODO: Implement add category functionality
        },
        child: const Icon(Icons.add),
      ),
    );
    
  }
}