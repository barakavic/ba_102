import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlansPage extends ConsumerWidget{
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
   return Scaffold(
    appBar: AppBar(
      title: const Text("Plans"),
      centerTitle: true,
    ),

    body: Center(
      child: Text("Active and Past Plans will be managed here",
      style: TextStyle(fontSize: 16.0),),
    ),

    

    
   );
    // throw UnimplementedError();
  }
}