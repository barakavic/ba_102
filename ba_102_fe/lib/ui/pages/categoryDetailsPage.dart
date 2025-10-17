import 'package:flutter/material.dart';
import 'package:ba_102_fe/data/models/models.dart';

class CategoryDetailsPage extends StatelessWidget{
  final Category category;

  const CategoryDetailsPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),

      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Limit: ${category.limitAmount ?? 'No Limit'}',
            
            ),
            const SizedBox(
              height: 8.0,
            ),

            Text(
              'SpentAmount: ${category.spentAmount}',
              style: const TextStyle(
                fontSize: 16.0
              ),
            ),

            const SizedBox(
              height: 8.0
            ),

            Expanded(child: category.transactions.isEmpty ? 
            const Center(
              child: Text('No Transactions Yet'),
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
                  title: Text(tx.description),
                  subtitle: Text(
                    'Date: ${tx.date} \n Amount: ${tx.amount}',

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