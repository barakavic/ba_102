import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/plan_ls.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ba_102_fe/data/models/models.dart';

final plansProvider = FutureProvider<List<Plan>>((ref) async {
  final db = await DatabaseHelper.instance.database;
  return PlanLs(db).getPlans();
});

class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsyncValue = ref.watch(plansProvider);
    return Scaffold(
      body: plansAsyncValue.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(
              child: Text("No plans are available"),
            );
          }

          return ListView.builder(
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];

              return FutureBuilder<double>(
                future: _calculatePlanSpending(plan),
                builder: (context, snapshot) {
                  final spent = snapshot.data ?? 0.0;
                  final progress = plan.limitAmount > 0 ? (spent / plan.limitAmount).clamp(0.0, 1.0) : 0.0;
                  
                  // Determine status and color
                  Color statusColor = Colors.green;
                  String statusText = 'NORMAL';
                  if (plan.limitAmount > 0) {
                    if (spent >= plan.limitAmount) {
                      statusColor = Colors.red;
                      statusText = 'OVERSPENT';
                    } else if (spent >= plan.limitAmount * 0.8) {
                      statusColor = Colors.orange;
                      statusText = 'WARNING';
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: statusColor, width: 2),
                    ),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(
                          statusText == 'OVERSPENT' ? Icons.error_outline : 
                          statusText == 'WARNING' ? Icons.warning_amber : Icons.check_circle_outline,
                          color: statusColor,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              plan.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${plan.planType.toUpperCase()} PLAN',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, letterSpacing: 1.2),
                          ),
                          Text(
                            '${plan.startDate.toLocal().toIso8601String().substring(0, 10)} to ${plan.endDate.toIso8601String().substring(0, 10)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (plan.limitAmount > 0) ...[
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Spent: KES ${spent.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                                ),
                                Text(
                                  'Limit: KES ${plan.limitAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            const Text('No budget limit set', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Divider(),
                              Text(
                                'This plan tracks all spending from ${plan.startDate.toLocal().toIso8601String().substring(0, 10)}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_plan_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PlansFormPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<double> _calculatePlanSpending(Plan plan) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ?',
      whereArgs: [plan.startDate.toIso8601String(), plan.endDate.toIso8601String()],
    );

    return maps.fold<double>(0.0, (sum, map) => sum + (map['amount'] as num).toDouble());
  }
}