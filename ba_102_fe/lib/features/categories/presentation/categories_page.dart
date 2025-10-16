import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/data/api/categoryService.dart';
import 'package:ba_102_fe/data/models/models.dart';

final CategriesProvider = FutureProvider<List<Category>>((ref) async{
  return Categoryservice().fetchCategories();
});


class CategoriesPage extends ConsumerWidget{
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final categoriesAsync = ref.watch(CategriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        centerTitle: true,
      ),

      body: categoriesAsync.when(
        data: (categories){
          if (categories.isEmpty){
            return const Center(
              child:
               Text('No categories found'),);

          }

          return Padding(padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
            ), 
            itemCount: categories.length,
            itemBuilder: (context, index){
              final category = categories[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                child: Center(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      
                      fontSize: 18,
                      fontWeight: FontWeight.w600
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

 

    );
    
  }
}