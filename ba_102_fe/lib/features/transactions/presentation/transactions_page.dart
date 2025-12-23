// import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/transactions_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/categories/presentation/categories_page.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:ba_102_fe/providers/sms_provider.dart';
import 'package:ba_102_fe/services/Sms_Message_Parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      child: Scaffold(
        appBar: AppBar(
        title: const Text('Transaction'),
        centerTitle: true,
        actions: [
          Padding(padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(smsState.isListening ? Icons.sms : Icons.sms_failed,
              color: smsState.isListening ? Colors.green.shade400 : Colors.grey,
              size: 20,
              ),
              if (smsState.transactionCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 4.0),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:  Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${smsState.transactionCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,


                  ),
                ),
              ),

            ],
          ),
          ),
          // In AppBar actions:

// Test Message buttton
IconButton(
  icon: const Icon(Icons.bug_report, color: Colors.orange),
  tooltip: 'Simulate M-Pesa SMS',
  onPressed: () {
    final testMessages = [
      "REPLACEME Confirmed. Ksh1,200.00 sent to KFC ADAMS for account KFC on 23/12/25 at 12:14 PM.",
      "REPLACEME Confirmed. Ksh2,500.00 sent to KPLC for account 12345678 on 23/12/25 at 1:00 PM.",
      "REPLACEME Confirmed. Ksh150.00 sent to BOLT TAXI on 23/12/25 at 2:30 PM.",
      "REPLACEME Confirmed. Ksh50.00 bought Safaricom Airtime on 23/12/25 at 3:00 PM.",
      "REPLACEME Confirmed. Ksh3,000.00 sent to NAIVAS for account GROCERIES on 10/01/26 at 10:00 AM.",
    ];
    
    // Pick a random message and inject a random reference
    final random = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final rawMsg = testMessages[DateTime.now().millisecond % testMessages.length];
    final msg = rawMsg.replaceFirst("REPLACEME", "TEST$random");

    print("Simulating SMS: $msg");
    ref.read(smsProvider.notifier).simulateSms(msg, "MPESA");
  },
)
        ],
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
            TransactionDetailsView(ref: ref,
            txAsyncValue: txAsyncValue
            ),
            CategoriesPage(),
            PlansPage()
            
            
          ]))
          
          
        ],
      ),
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
  final AsyncValue<List<Transaction>> txAsyncValue;
  const TransactionDetailsView({
    super.key, 
    required this.ref,
    required this.txAsyncValue,
    });

   /* // Mock data for the list view 
  static const List<Map<String, dynamic>> mockTransactions = [
    {'name': 'Travel', 'date': '26-11-23', 'amount': -10000.0, 'icon': Icons.airplanemode_active},
    {'name': 'Food', 'date': '24-11-23', 'amount': -2000.0, 'icon': Icons.fastfood},
    {'name': 'Shopping', 'date': '23-11-23', 'amount': -3000.0, 'icon': Icons.shopping_bag},
    {'name': 'Salary', 'date': '20-11-23', 'amount': 50000.0, 'icon': Icons.account_balance_wallet},
  ];
 */
  @override
  Widget build(BuildContext context) {
    
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
          Expanded(child: RefreshIndicator(onRefresh: ()async{
            ref.invalidate(txProv);

            await ref.read(txProv.future);

          },
          child: txAsyncValue.when(data: (transactions){
            if (transactions.isEmpty){
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16,),
                        Text(
                          'No Transactions yet',
                          style: TextStyle(
                            color: Colors.grey, fontSize: 16
                          ),
                          
                        ),
                        SizedBox(height: 8),
                        Text(
                          'M-Pesa transactions will appear here automattically',
                          style: TextStyle(color: Colors.grey,
                          fontSize: 12),

                          textAlign: TextAlign.center,
                        ),
                        ],
                        ),
                  ),
                ],
              );
            }
                    

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 8
              ),
              children: [
                ListTile(
                  title: Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: priColor,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  
                ),
                ...transactions.map((tx)=> _TransactionItem(transaction: tx)).toList(),
              ],
            );
          }, 
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
            SizedBox(height: 100),
            Center(child: CircularProgressIndicator()),
            ]
          ),
          error: (error, stack) => ListView( 
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
            SizedBox(height: 100,),  
            Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red,),
                SizedBox(height: 16),
                Text('Error loading transactions', style: TextStyle(color: Colors.red),),
                SizedBox(height: 8.0,),
                Text(error.toString(), style: TextStyle(fontSize: 12)),
                SizedBox(height: 16.0,),
                ElevatedButton(onPressed: () =>ref.invalidate(txProv), 
                child: Text('Retry'),
                ),
              ],
            ),
          ), ],
          ),
          ),

        
          ),
          ),
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

  final Transaction transaction;

  const _TransactionItem({
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'outbound' || transaction.type == 'withdrawal';
    IconData icon = _getIcon();
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: priColor.withOpacity(0.1),
        child: Icon(icon, color: priColor, size: 20,),
      ),
      title: Text(transaction.description ?? transaction.vendor ?? 'Uknown'),
      subtitle: Row(
        children: [
          Text(
            _formatDate(transaction.date),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey
            ),
          ),
          if(transaction.mpesaReference != null) ...[
            SizedBox(width: 8),
            Text(
              'Ref: ${transaction.mpesaReference}',
              style: TextStyle(fontSize: 10.0, color: Colors.grey),

            ),
          ],
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          Text(
            '${isExpense ? '-' : '+'}KES${transaction.amount?.toStringAsFixed(0) ?? '0'}',

            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red.shade700 : Colors.grey
            ),
          ),
          if (transaction.balance != null)
          Text(
            'Bal: ${transaction.balance!.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );

}

    IconData _getIcon(){
      switch(transaction.type){
        case 'inbound':
        return Icons.arrow_downward;
        case 'withdrawal':
        return Icons.local_atm;
        case 'deposit':
        return Icons.account_balance;
        case 'outbound':
        default:
          final vendor = (transaction.vendor ?? transaction.description ?? '').toLowerCase();

          if (vendor.contains('food') || vendor.contains('restaurant') || vendor.contains('cafe') || vendor.contains('hotel')){
            return Icons.fastfood;
          }
          if (vendor.contains('shop') || vendor.contains('store') || vendor.contains('market')){
            return Icons.shopping_bag;
          }
          if (vendor.contains('uber') || vendor.contains('bolt') || vendor.contains('taxi') || vendor.contains('transport')){
            return Icons.local_taxi;
          }
          if (vendor.contains('fuel') || vendor.contains('petrol')){
            return Icons.local_gas_station;
          }
          if (vendor.contains('electric') || vendor.contains('kplc') || vendor.contains('water') || vendor.contains('bill')){
            return Icons.receipt;
          }
          return Icons.payments;
      }
    }

    String _formatDate(DateTime? date){

      if (date == null) return 'No date';
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0){
        return 'Today ${date.hour}: ${date.minute.toString().padLeft(2, '0')}';
      }
      else if(difference.inDays ==1){
        return 'Yesterday';
      }
      else if(difference.inDays <7){
        return '${difference.inDays} days ago';
      }
      else{
        return '${date.day}/${date.month}/${date.year}';
      }
    }

}





