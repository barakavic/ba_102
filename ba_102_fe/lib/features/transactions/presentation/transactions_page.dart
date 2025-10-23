import 'package:ba_102_fe/data/api/transaction_service.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),
        centerTitle: true,
      ),

      body: txAsyncValue.when(data: (txs){
        if(txs.isEmpty){
          return const Center(
            child: Text("No transactions available"),
          );
        }
        return ListView.builder(
        itemCount: txs.length, 
        itemBuilder: (context, index) {
          final tx = txs[index];

          return ListTile(
            title: Text(tx.description ?? 'no description'),
            subtitle: Text('Amount: ${tx.amount}'),
            trailing: Text(
              tx.date.toString(),
              style: TextStyle(color: Colors.blueGrey),
            ),
          );
          
        },);
      }, 
      error: (err,_) => Center (child: Text('Error: $err'),), 
      loading: ()=> const Center(child: CircularProgressIndicator(),)),

      



    );
    // throw UnimplementedError();
  }



  }

