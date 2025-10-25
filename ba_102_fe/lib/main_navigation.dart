import 'package:ba_102_fe/features/categories/presentation/categories_page.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:ba_102_fe/features/settings/presentation/settings_page.dart';
import 'package:ba_102_fe/features/transactions/presentation/transactions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/dashboard_page.dart';

const Color primaryColor = Color(0xFF4B0082);

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget{
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final currentIndex = ref.watch(navIndexProvider);
    
    final pages  = const [
      DashboardPage(),
      // CategoriesPage(),
      TransactionsPage(),
      // PlansPage(),
      SettingsPage()
      
    ];

    void selectDestination(int index){
      ref.read(navIndexProvider.notifier).state = index;
    }

    

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,

      ),

      floatingActionButton: FloatingActionButton(
        onPressed: (){
          selectDestination(1);
        },
        shape: const CircleBorder(),
        backgroundColor: primaryColor,
        elevation: 4.0,
        child: const Icon(
          Icons.swap_horiz_rounded, 
          color: Colors.white, 
          size: 30,
          ),
          
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: primaryColor,
        shape: const CircularNotchedRectangle(),
        height: 60,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(onPressed: ()=> selectDestination(0), 
            icon: Icon(
              currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
              color: Colors.white,
              size: 30,
            ),
            
            
            ),
            const SizedBox(width: 40,),

            IconButton(
              onPressed: ()=>selectDestination(2), 
              icon: Icon(
                currentIndex == 2 ? Icons.person_rounded : Icons.person_outline_outlined,
                color: Colors.white,
                size: 30,
              ))
          ],
        ),
      )

      
      
      
      
    
      

      


    );
  }
}