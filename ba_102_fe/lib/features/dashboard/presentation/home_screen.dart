import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget{
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: implement build
    // throw UnimplementedError();

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          // child: BudgetSummary()
        ),
        const SliverToBoxAdapter(
          // child: SpendingGraph(),
        ),
        const SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 10.0),
          child: Text(
            'Your recent transactions',
            style:TextStyle(fontSize: 18, fontWeight: FontWeight.bold),

          ),
          ),
        ),

        // const RecentTransactionList()

      ],
    );
  }
}