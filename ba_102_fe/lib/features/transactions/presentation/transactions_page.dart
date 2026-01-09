// import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/categories/presentation/categories_page.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:ba_102_fe/providers/sms_provider.dart';
import 'package:ba_102_fe/services/Sms_Message_Parser.dart';
import 'package:ba_102_fe/utils/test_data_seeder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ba_102_fe/features/transactions/presentation/widgets/transaction_details_view.dart';
const Color priColor = Color(0xFF4B0082);

final txProv = FutureProvider<List<Transaction>>((ref) async{
  final db = await DatabaseHelper.instance.database;
  final localService = TransactionsLs(db);
  return await localService.getTransactions();
  /* try{
   /* // try online
    final onlineTx = await TransactionService().fetchTx();

 
    for (var tx in onlineTx){
      await localService.insertTransaction(tx);
    }
    return onlineTx;  */
       // save to offline
    final db = await DatabaseHelper.instance.database;
    final localService = TransactionsLs(db);
    
  }
  catch(e){
    // N/w fails rollback to sqlite
    final db = await DatabaseHelper.instance.database;
    final localService = await TransactionsLs(db);
    final localTx = await localService.getTransactions();
    return localTx;

  } */

});
class TransactionsPage  extends ConsumerWidget{
  const TransactionsPage({super.key});

 

  

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final txAsyncValue = ref.watch(txProv);
    final smsState = ref.watch(smsProvider);


    // Listen for new transactions and show the snackbar
    ref.listen<SmsState>(smsProvider, (previous, next){
      if (next.lastTransaction != null && next.lastTransaction != previous?.lastTransaction){
        _showTransactionSnackbar(context, next.lastTransaction!);

      }
    });

    return DefaultTabController(
      length: 3, 
      child: Column(
        children: <Widget>[
          const TabBar(
            labelColor: priColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: priColor,
            tabs: [
              Tab(text: 'Transactions'),
              Tab(text: 'Categories'),
              Tab(text: 'Plans'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                TransactionDetailsView(txAsyncValue: txAsyncValue),
                CategoriesPage(),
                PlansPage(),
              ],
            ),
          ),
        ],
      ),
    );
      
    // throw UnimplementedError();
  }

  void _showTransactionSnackbar(BuildContext context, MpesaTransaction transaction){
    String message;
    Color color;
    IconData icon;

    switch(transaction.type){
      case TransactionType.inbound:
      message = 'Received KES amount ${transaction.amount.toStringAsFixed(2)}';
      if (transaction.recipient != null ) message += 'to${transaction.recipient}';
      color = Colors.green;
      icon = Icons.arrow_downward;
      break;
      case TransactionType.outbound:
      message = 'Sent KES ${transaction.amount.toStringAsFixed(2)}';
      if (transaction.recipient != null) message += 'to ${transaction.recipient}';
      color = Colors.red;
      icon = Icons.arrow_upward;
      break;
      case TransactionType.withdrawal:
      message = 'Withdrawn KES ${transaction.amount.toStringAsFixed(2)}';
      color = Colors.orange.shade400;
      icon = Icons.local_atm;
      break;
      case TransactionType.deposit:
      message = 'Deposited KES ${transaction.amount.toStringAsFixed(2)}';
      color = Colors.blue;
      icon = Icons.account_balance;
      break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(
          width: 8,
        ),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Ref: ${transaction.reference}', style: const TextStyle(fontSize: 11),),
          ],
        ),),
      ],
      ),
      backgroundColor: color,
      action: SnackBarAction(
      label: 'View', 
      textColor: Colors.white,
      onPressed: (){},
      ),
      duration: 
       const Duration(seconds:  4),
      ),
      
    );
  }



  }
  
