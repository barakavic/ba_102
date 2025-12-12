import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/plan_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final addPlanProvider = Provider ((ref){
  return (Plan plan) async {
    final db = await DatabaseHelper.instance.database;
    await PlanLs(db).insertPlan(plan);
    ref.refresh(plansProvider);
  };
});

class PlansFormPage extends ConsumerStatefulWidget{
  const PlansFormPage({super.key});

  @override
  ConsumerState<PlansFormPage> createState() => _PlansFormPageState();

}

class _PlansFormPageState extends ConsumerState<PlansFormPage> {

  final nameCtrl = TextEditingController();
  DateTime? start;
  DateTime? end;

  @override
  Widget build(BuildContext context) {

   return Scaffold(
    appBar: AppBar(
      title: Text('Create Plan'),
      centerTitle: true,
    ),
    body: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(labelText: "Plan Name"),

          ),
          const SizedBox( height: 20,),

          ElevatedButton(onPressed: ()async{
            start = DateTime.now();
            end = DateTime.now().add(const Duration(days:30));

            final plan = Plan(
            id: 0, 
            name: nameCtrl.text.trim(), 
            startDate: start!, 
            endDate: end!, 
            status: "ACTIVE", 
            categories: [], 
            transactions: []);

            final savePlan = ref.read(addPlanProvider);
            await savePlan(plan);

            Navigator.pop(context);

            
          },
          child: const Text("Save Plan"),
          ),

          
        ]
 
      ),)

   );   
  }
}