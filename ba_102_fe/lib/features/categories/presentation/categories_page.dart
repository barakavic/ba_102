import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoriesPage extends ConsumerWidget{
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categories"),
        centerTitle: true,
      ),

      body: const Center (
        child: Text("Your Spending Categories will appear here.",
        style: TextStyle(
          fontSize: 16.0,
        ),),
      ),

    );
    
  }
}