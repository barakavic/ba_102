import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/providers/theme_provider.dart';
import 'package:ba_102_fe/theme/colorscheme.dart';
import 'package:ba_102_fe/main_navigation.dart';
import 'package:permission_handler/permission_handler.dart';


Future <void> requestBackgroundPermissions() async{
  if(await Permission.ignoreBatteryOptimizations.isDenied){
    await Permission.ignoreBatteryOptimizations.request();
  }
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  await requestBackgroundPermissions();

  


  runApp(const ProviderScope(child: BudgetingApp()));
}

class BudgetingApp extends ConsumerWidget {
  const BudgetingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'HoneyBadger',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: AppColors.lightScheme,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: AppColors.darkScheme,
        useMaterial3: true,
      ),
      home: MainNavigation(),
    );
  }
}