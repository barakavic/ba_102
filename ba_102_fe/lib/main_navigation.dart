import 'dart:ui';
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
import 'package:ba_102_fe/services/sync_service.dart';
import 'package:ba_102_fe/features/settings/presentation/app_settings_page.dart';

const Color primaryColor = Color(0xFF4B0082);

final navIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget {
  MainNavigation({super.key});

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

    final smsState = ref.watch(smsProvider);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(
                    smsState.isListening ? Icons.sms : Icons.sms_failed,
                    color: smsState.isListening ? Colors.green.shade400 : Colors.grey,
                    size: 20,
                  ),
                  if (smsState.transactionCount > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 4.0),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green,
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
            IconButton(
              icon: const Icon(Icons.history, color: primaryColor),
              onPressed: () async {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sync M-Pesa History'),
                    content: const Text('This will scan your SMS inbox for new M-Pesa messages. Continue?'),
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
                  // 1. Local SMS Sync
                  int count = await ref.read(smsProvider.notifier).syncHistoricalMessages();
                  
                  // 2. Online Cloud Sync (Silent background task)
                  final isSyncEnabled = ref.read(cloudSyncProvider);
                  await SyncService().syncAll(isSyncEnabled);

                  ref.invalidate(mpesaBalanceProvider);
                  ref.invalidate(mpesaBalanceHistoryProvider);
                  ref.invalidate(monthlySummaryProvider);
                  ref.invalidate(topCategoriesProvider);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(count > 0 ? 'Added $count new transactions.' : 'No new transactions found.'),
                        backgroundColor: Colors.green,
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
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.70,
        child: Drawer(
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              color: Colors.white.withOpacity(0.7),
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.account_balance_wallet, size: 48, color: primaryColor),
                          const SizedBox(height: 10),
                          Text(
                            "Command Center",
                            style: TextStyle(color: Colors.grey.shade800, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text("Settings"),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AppSettingsPage()),
                      );
                    },
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
                    child: Text("v1.7.0 - Financial OS", style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: pages[currentIndex],
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(
                currentIndex == 0 ? Icons.dashboard : Icons.dashboard_outlined,
                color: currentIndex == 0 ? primaryColor : Colors.grey,
              ),
              onPressed: () => ref.read(navIndexProvider.notifier).state = 0,
            ),
            IconButton(
              icon: Icon(
                currentIndex == 1 ? Icons.swap_horiz : Icons.swap_horiz_outlined,
                color: currentIndex == 1 ? primaryColor : Colors.grey,
                size: 32, // Make the center action slightly larger
              ),
              onPressed: () => ref.read(navIndexProvider.notifier).state = 1,
            ),
            IconButton(
              icon: Icon(
                currentIndex == 2 ? Icons.settings : Icons.settings_outlined,
                color: currentIndex == 2 ? primaryColor : Colors.grey,
              ),
              onPressed: () => ref.read(navIndexProvider.notifier).state = 2,
            ),
          ],
        ),
      ),
    );
  }
}