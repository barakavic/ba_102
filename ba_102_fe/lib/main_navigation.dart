import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/dashboard_page.dart';

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget{
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref){
    final currentIndex = ref.watch(navIndexProvider);
    
    final pages  = const [
      DashboardPage(),
      Placeholder(),
      Placeholder(),
      Placeholder(),
      Placeholder()
      
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,

      ),
      bottomNavigationBar: NavigationBar(selectedIndex: currentIndex,
      onDestinationSelected: (index) => 
      ref.read(navIndexProvider.notifier).state = index,
      destinations: const[
        NavigationDestination(icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
         label: "Dashboard"),
         NavigationDestination(icon: Icon(Icons.category_outlined), 
         selectedIcon: Icon(Icons.category) , 
         label: "Categories"),
         NavigationDestination(icon: Icon(Icons.swap_horiz_outlined),
          selectedIcon: Icon(Icons.swap_horiz),
          label: "Transactions"),
          NavigationDestination(icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings), 
          label: "Settings"),

      ],
      

      
      ),
      
      
    
      

      


    );
  }
}