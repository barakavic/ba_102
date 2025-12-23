
import 'package:ba_102_fe/data/local/category_ls.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/categories/presentation/categories_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatFormPage extends ConsumerStatefulWidget{
  
  final int planId;
  const CatFormPage({super.key, required this.planId});

  @override
  ConsumerState<CatFormPage> createState() => _CatFormPageState();


}

class _CatFormPageState extends ConsumerState<CatFormPage>{

  final nameCtrl = TextEditingController();
  final limitCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
   
   return Scaffold(
    appBar: AppBar(title: Text('Create Category'),
    ),
    body: Padding(padding: EdgeInsets.all(16),
    child: Column(
      children: [
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Category Name"),
        ),
        TextField(
          controller: limitCtrl,
          decoration: const InputDecoration(labelText: "Input the limit"),

          
        ),

        const SizedBox(
            height: 20,
          ),

        ElevatedButton(
        onPressed: ()async{

          final db = await DatabaseHelper.instance.database;
          final category = Category(
            id: 0, 
            name: nameCtrl.text.trim(), 
            limitAmount: double.tryParse(limitCtrl.text.trim()) ?? 0.0,
            transactions: []
          );

          await CategoryLs(db).insertCategory(category);

          ref.refresh(CategoriesProvider);
          Navigator.pop(context);
        }, 
        child: Text("Save Category"))
      ],
    ),
    ),
   );
  }
}