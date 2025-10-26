// import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:ba_102_fe/data/api/transaction_service.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/categories/presentation/categories_page.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';

const Color priColor = Color(0xFF4B0082);

final txProv = FutureProvider<List<Transaction>>((ref) async{
  try{
    // try online
    final onlineTx = await TransactionService().fetchTx();

    // save to offline
    final db = await DatabaseHelper.instance.database;
    final localService = TransactionsLs(db);
    
    for (var tx in onlineTx){
      await localService.insertTransaction(tx);
    }
    return onlineTx;
  }
  catch(e){
    // N/w fails rollback to sqlite
    final db = await DatabaseHelper.instance.database;
    final localService = await TransactionsLs(db);
    final localTx = await localService.getTransactions();
    return localTx;

  }
});
class TransactionsPage  extends ConsumerWidget{
  const TransactionsPage({super.key});

 

  

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final txAsyncValue = ref.watch(txProv);

    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
        title: const Text('Transaction'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          const TotalSpendingHeader(),

          const TabBar(
            labelColor: priColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: priColor,
            tabs: [
            Tab(text: 'Transactions',),
            Tab(text: 'Categories',),
            Tab(text: 'Plans',),
          ],
          ),
          Expanded(child: TabBarView(children: [
            TransactionDetailsView(ref: ref),
            CategoriesPage(),
            PlansPage()
            
            
          ]))
          
          
        ],
      ),
      ),
      
      );
      
    // throw UnimplementedError();
  }



  }
  
  class TotalSpendingHeader extends StatelessWidget
{
  const TotalSpendingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Spendings this month',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(
            height: 8,
          ),
          const Text('75,000',
          style: TextStyle(
            fontSize: 32.0,
            fontWeight: FontWeight.bold,
            color: priColor
          ),
          ), //Placeholder
          

        ],
      ),
    );

    // TODO: implement build
    // throw UnimplementedError();
  }
}

class TransactionDetailsView extends StatelessWidget{
  final WidgetRef ref;
  const TransactionDetailsView({super.key, required this.ref});

   // Mock data for the list view 
  static const List<Map<String, dynamic>> mockTransactions = [
    {'name': 'Travel', 'date': '26-11-23', 'amount': -10000.0, 'icon': Icons.airplanemode_active},
    {'name': 'Food', 'date': '24-11-23', 'amount': -2000.0, 'icon': Icons.fastfood},
    {'name': 'Shopping', 'date': '23-11-23', 'amount': -3000.0, 'icon': Icons.shopping_bag},
    {'name': 'Salary', 'date': '20-11-23', 'amount': 50000.0, 'icon': Icons.account_balance_wallet},
  ];

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    // throw UnimplementedError();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
          horizontal: 16.0, 
          vertical: 8.0),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(onPressed: (){},
              icon: const Text('Nov 2025'), 
              label: const Icon(Icons.keyboard_arrow_down, size: 16,))
            ],

          ),
          ),

          Padding(
            padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('View All', selected: true),
                  _buildFilterChip('Food', icon: Icons.fastfood),
                  _buildFilterChip('Shopping', icon: Icons.shopping_bag),
                  _buildFilterChip('Travel', icon: Icons.airplanemode_active),
                  

                ],
              ),
            ),
          
          ),
          Expanded(child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              ListTile(
                title: Text('This week (26 Nov to 30 Nov)',
                style: TextStyle(color: priColor),
                ),

                
                // _TransactionItem(name: )
                
              ),

              ...mockTransactions.map(
                (tx) => _TransactionItem(
                  name: tx['name'] as String, 
                  amount: tx['amount'] as double, 
                  date: tx['date'] as String, 
                  icon: tx['icon'] as IconData)).toList(),
              
            ],
          )),

        
          
      ],
    );
  }

  Widget _buildFilterChip(String label, {IconData? icon, bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label),
        avatar: icon != null ? Icon(icon, size: 18) : null,
        backgroundColor: selected ? priColor : Colors.grey[200],
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
        side: BorderSide.none,
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget{

  final String name;
  final double amount;
  final String date;
  final IconData icon;

  const _TransactionItem({
    required this.name,
    required this.amount,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    // throw UnimplementedError();

    final isExpense = amount < 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: priColor.withOpacity(0.1),
        child: Icon(icon, color: priColor, size: 20,),
      ),
      title: Text(name),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          Text(
            '${isExpense ? '-kes' : '+kes'}${amount.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red.shade700 : Colors.grey
            ),
          ),
        ],
      ),
    );

    
  }

}




