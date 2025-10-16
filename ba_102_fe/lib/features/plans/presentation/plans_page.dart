import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:ba_102_fe/data/api/planService.dart';
import 'package:ba_102_fe/data/models/models.dart';

final plansProvider = FutureProvider<List<Plan>>((ref) async {
  return Planservice().fetchPlans();
});

class PlansPage extends ConsumerWidget{

  
  const PlansPage({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final plansAsyncValue = ref.watch(plansProvider);
   return Scaffold(
    appBar: AppBar(
      title: const Text("Plans"),
      centerTitle: true,
    ),


  body: plansAsyncValue.when(data: (plans) {
    if (plans.isEmpty){
      return const 
      Center(
        child: Text("No plans are available"),
      );
    }

    return ListView.builder(
      itemCount: plans.length,
      itemBuilder: (context, index){
        final plan = plans[index];
        return ExpansionTile(
          title: Text(plan.name),
          
          subtitle: Text('Status: ${plan.status}'),
          children: [
            ...plan.categories.map((c)=> ListTile(
              title: Text(c.name),
              subtitle: Text('Spent: ${c.spentAmount} / ${c.limitAmount}'),
              trailing: Text(c.status),
              )),
          ...plan.transactions.map((t)=> ListTile(
            title: Text(t.description),
            subtitle: Text('${t.amount} - ${t.date}'),
          ))
          ],
          
        );
      },
    
    );
  } ,
  
  loading: ()=> const Center(child: CircularProgressIndicator(),),
  error: (err,_) => Center(child: Text('Error: $err')),
  ),

    

    
   );
    // throw UnimplementedError();
  }
}