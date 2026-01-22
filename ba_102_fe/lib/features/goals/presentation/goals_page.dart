import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/goals/providers/goal_providers.dart';
import 'package:ba_102_fe/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () => ref.read(goalsProvider.notifier).refresh(),
        child: goalsAsync.when(
          data: (goals) => goals.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    return _GoalCard(goal: goal);
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text("Error: $err"),
                ElevatedButton(
                  onPressed: () => ref.read(goalsProvider.notifier).refresh(),
                  child: const Text("Retry"),
                )
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGoalDialog(context, ref),
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.track_changes, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No goals yet",
            style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Add a goal to start tracking market prices.",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Goal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Product Name",
                hintText: "e.g. PS5, 3D Printer",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Target Budget (KES)",
                hintText: "How much do you think it costs?",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && amountController.text.isNotEmpty) {
                final newGoal = Goal(
                  name: nameController.text,
                  targetAmount: double.parse(amountController.text),
                  currentAmount: 0.0,
                );
                ref.read(goalsProvider.notifier).addGoal(newGoal);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text("Add Goal"),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends ConsumerWidget {
  final dynamic goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(symbol: "KES ", decimalDigits: 0);
    final progress = (goal.currentAmount / (goal.marketPrice ?? goal.targetAmount)).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (goal.marketStatus != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(goal.marketStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            goal.marketStatus!,
                            style: TextStyle(
                              color: _getStatusColor(goal.marketStatus),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: primaryColor),
                  onPressed: () => ref.read(goalsProvider.notifier).analyzeGoal(goal.id!),
                  tooltip: "Analyze with Hawkeye",
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Target: ${currencyFormat.format(goal.targetAmount)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                if (goal.marketPrice != null)
                  Text(
                    "Market: ${currencyFormat.format(goal.marketPrice)}",
                    style: const TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(goal.marketStatus)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Saved: ${currencyFormat.format(goal.currentAmount)} (${(progress * 100).toStringAsFixed(1)}%)",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (goal.rationale != null) ...[
              const Divider(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      goal.rationale!,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'BUY_NOW':
        return Colors.green;
      case 'WAIT':
        return Colors.orange;
      case 'UNAVAILABLE':
        return Colors.red;
      default:
        return primaryColor;
    }
  }
}
