import 'package:ba_102_fe/features/dashboard/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Total Budget'),
          actions: [
            IconButton(onPressed: (){}, 
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black,))
          ],
          automaticallyImplyLeading: false,
      ),
      body: const HomeScreen(),
    );
  }
}