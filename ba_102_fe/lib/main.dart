import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class BudgetingApp extends StatelessWidget {
  const BudgetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HoneyBadger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple.shade700),
        useMaterial3: true,
      ),
      home: MainNavigation(),
    );
  }
}