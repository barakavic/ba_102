import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/plan_ls.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_form_page.dart';
import 'package:ba_102_fe/features/plans/presentation/plan_details_page.dart';
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(plansProvider);
          await ref.read(plansProvider.future);
        },
        child: plansAsyncValue.when(
          data: (plans) {
            if (plans.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(child: Text("No plans are available")),
                ],
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

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlanDetailsPage(planId: plan.id),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: statusColor.withOpacity(0.1),
                                    child: Icon(
                                      statusText == 'OVERSPENT' ? Icons.error_outline : 
                                      statusText == 'WARNING' ? Icons.warning_amber : Icons.check_circle_outline,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          plan.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          '${plan.planType.toUpperCase()} PLAN',
                                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, letterSpacing: 1.2),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (plan.limitAmount > 0) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'KES ${spent.toStringAsFixed(0)} spent',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor),
                                    ),
                                    Text(
                                      'Limit: KES ${plan.limitAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade100,
                                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                    minHeight: 8,
                                  ),
                                ),
                              ] else ...[
                                const Text('No budget limit set', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${plan.startDate.toLocal().toIso8601String().substring(0, 10)} to ${plan.endDate.toIso8601String().substring(0, 10)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
                                ],
                              ),
                            ],
                          ),
                        ),
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
      where: 'date >= ? AND date <= ? AND (type = ? OR type = ?)',
      whereArgs: [
        plan.startDate.toIso8601String(), 
        plan.endDate.toIso8601String(),
        'outbound',
        'withdrawal'
      ],
    );

    return maps.fold<double>(0.0, (sum, map) => sum + (map['amount'] as num).toDouble());
  }
}