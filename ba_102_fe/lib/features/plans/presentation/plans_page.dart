import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/plan_ls.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


// import 'package:ba_102_fe/features/plans/presentation/add_plan_page.dart';
import 'package:ba_102_fe/data/models/models.dart';

final plansProvider = FutureProvider<List<Plan>>((ref) async {
  // try{
    // try online first
    // final onlinePlans = await Planservice().fetchPlans();

  // save to offline later
    final db = await DatabaseHelper.instance.database;
    return PlanLs(db).getPlans();
    // final localService = PlanLs(db);
    // await localService.deleteAllPlans();

    /* for(var plan in onlinePlans){
      await localService.insertPlan(plan);
    }
    return onlinePlans;
  } catch(e){
    // N/w fails rollback to sqlite
    print('Fetching from local DB due to error: $e');
    final db = await DatabaseHelper.instance.database;
    final localService = await PlanLs(db);
    final localPlans= await localService.getPlans();
    return localPlans;
    
  } */
  
});

class PlansPage extends ConsumerWidget{

  
  const PlansPage({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final plansAsyncValue = ref.watch(plansProvider);
   return Scaffold(
   
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

    

    
    
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_)=> const PlansFormPage(),
          ),
          );
        },
        child: const Icon(Icons.add),
      ),
   );
    // throw UnimplementedError();
  }
}