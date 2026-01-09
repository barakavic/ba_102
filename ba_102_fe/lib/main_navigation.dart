import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/features/categories/presentation/categories_page.dart';
import 'package:ba_102_fe/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:ba_102_fe/features/settings/presentation/settings_page.dart';
import 'package:ba_102_fe/features/transactions/presentation/transactions_page.dart';
import 'package:ba_102_fe/providers/sms_provider.dart';
import 'package:ba_102_fe/utils/test_data_seeder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/dashboard_page.dart';

const Color primaryColor = Color(0xFF4B0082);

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget {
  MainNavigation({super.key});

  // We use a GlobalKey to control the Scaffold (opening the drawer) from the AppBar
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navIndexProvider);
    final titles = ['Total Budget', 'Transactions', 'Settings'];

    final pages = const [
      DashboardPage(),
      TransactionsPage(),
      SettingsPage()
    ];

    void selectDestination(int index) {
      ref.read(navIndexProvider.notifier).state = index;
    }

    return Scaffold(
      key: _scaffoldKey, // Attach the key here
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // This opens the drawer using the GlobalKey
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(titles[currentIndex]),
        centerTitle: currentIndex == 2,
        actions: [
          if (currentIndex == 0)
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
            ),
          if (currentIndex == 1) ...[
            IconButton(
              icon: const Icon(Icons.history, color: primaryColor),
              onPressed: () async {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sync M-Pesa History'),
                    content: const Text('This will scan your SMS inbox for M-Pesa messages from the current month. Continue?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        child: const Text('Sync Now'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  int count = await ref.read(smsProvider.notifier).syncHistoricalMessages();
                  ref.invalidate(mpesaBalanceProvider);
                  ref.invalidate(mpesaBalanceHistoryProvider);
                  ref.invalidate(monthlySummaryProvider);
                  ref.invalidate(topCategoriesProvider);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(count > 0 ? 'Added $count new transactions.' : 'No new transactions found.'),
                        backgroundColor: count > 0 ? Colors.green : Colors.orange,
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.orange),
              onPressed: () async {
                final db = await DatabaseHelper.instance.database;
                await TestDataSeeder.seedTestTransactions(db);
                ref.invalidate(txProv);
                ref.invalidate(plansProvider);
              },
            ),
          ],
        ],
      ),
      // This is our new Global Drawer
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Center(
                child: Text(
                  "Command Center",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("App Info"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              secondary: Icon(
                ref.watch(privacyModeProvider) ? Icons.visibility_off : Icons.visibility,
                color: primaryColor,
              ),
              title: const Text("Privacy Mode"),
              subtitle: const Text("Hide balances on screens"),
              value: ref.watch(privacyModeProvider),
              onChanged: (value) {
                ref.read(privacyModeProvider.notifier).state = value;
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("v1.0.2 - Financial OS", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
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