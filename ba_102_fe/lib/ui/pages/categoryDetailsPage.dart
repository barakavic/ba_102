import 'package:flutter/material.dart';
import 'package:ba_102_fe/data/models/models.dart';

class CategoryDetailsPage extends StatelessWidget{
  final Category category;

  const CategoryDetailsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {

    final totalSpent = category.transactions.fold<double>(0.0, (sum, tx)=> sum+tx.amount!);

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),

      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total spent: ${totalSpent.toStringAsFixed(2) }',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),            
            ),

            const SizedBox(
              height: 16.0,
            ),

            Expanded(
            child: category.transactions.isEmpty ? 
            const Center(
              child: Text('No Transactions Yet',
              style: TextStyle(color: Colors.grey),
              ),
            )
            : ListView.builder(
              itemCount: category.transactions.length,
              
              itemBuilder: (context, index){
              final tx = category.transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 4,
                  
                ),

                child: ListTile(
                  title: Text(tx.description!),
                  subtitle: Text(
                    'Date: ${tx.date?.toIso8601String().substring(0,10)} }',

                  ),
                  trailing: Text(
                    tx.amount!.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );

            },)
            )

          ],
        ),
        ),

    );
    // throw UnimplementedError();
  }
}