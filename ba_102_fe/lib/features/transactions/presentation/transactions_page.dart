import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionsPage  extends ConsumerWidget{
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
        centerTitle: true,
      ),

      body: const Center(
        child: Text("Transactions will be shown here",
        style: TextStyle(
          fontSize: 16.0,
        ),),
      ),

    );
    // throw UnimplementedError();
  }



  }

