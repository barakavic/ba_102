import 'dart:io';

import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/goals_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/goals/providers/goal_providers.dart';
import 'package:ba_102_fe/features/goals/presentation/goal_commitment_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const _goalKinds = <String, String>{
  'product': 'Product goal',
  'squirrel': 'Squirrel fund',
  'rainy_day': 'Rainy Day fund',
  'icoe': 'In Case of Emergency fund',
  'spending_budget': 'Spending budget',
};

Future<void> _openProductSearch(BuildContext context, String rawQuery) async {
  final query = rawQuery.trim();
  if (query.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enter a product name to search.')),
    );
    return;
  }
  final searchUri = Uri.https('www.google.com', '/search', {'q': query});
  Object? lastError;
  try {
    if (await launchUrl(searchUri, mode: LaunchMode.externalApplication)) {
      return;
    }
  } catch (error) {
    lastError = error;
  }

  debugPrint('Product search launch failed: $lastError');
  if (context.mounted) {
    final noAndroidHandler = lastError.toString().contains(
      'ACTIVITY_NOT_FOUND',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          noAndroidHandler
              ? 'Android could not find a browser app. Install or enable one, then try again.'
              : 'Could not open a browser. Copy the search link instead.',
        ),
        action: SnackBarAction(
          label: 'Copy link',
          onPressed: () =>
              Clipboard.setData(ClipboardData(text: searchUri.toString())),
        ),
      ),
    );
  }
}

bool _isScheduledSavingDay(DateTime day, Goal goal) {
  return goal.scheduleType == 'daily' ||
      goal.savingDays.contains(day.weekday) ||
      (goal.savingDays.isEmpty && day.weekday <= goal.contributionsPerWeek);
}

int _scheduledSlots(DateTime start, DateTime end, Goal goal) {
  final first = DateTime(start.year, start.month, start.day);
  final last = DateTime(end.year, end.month, end.day);
  if (last.isBefore(first)) return 0;
  var slots = 0;
  for (
    var day = first;
    !day.isAfter(last);
    day = day.add(const Duration(days: 1))
  ) {
    if (_isScheduledSavingDay(day, goal)) slots++;
  }
  return slots;
}

DateTime? _estimatedFinishDate(Goal goal) {
  final amount = goal.contributionAmount;
  final target = goal.targetAmount;
  if (amount == null ||
      amount <= 0 ||
      target == null ||
      target <= goal.currentAmount) {
    return null;
  }
  final slotsNeeded = ((target - goal.currentAmount) / amount).ceil();
  final now = DateTime.now();
  var slots = 0;
  for (var offset = 0; offset <= 36500; offset++) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: offset));
    if (_isScheduledSavingDay(day, goal) && ++slots >= slotsNeeded) return day;
  }
  return null;
}

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Could not load goals: $error')),
        data: (goals) => goals.isEmpty
            ? _empty(context)
            : RefreshIndicator(
                onRefresh: () => ref.read(goalsProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    _weeklyOverview(context, goals),
                    const SizedBox(height: 12),
                    for (final goal in goals) _GoalCard(goal: goal),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add goal'),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.spa_outlined,
            size: 68,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Start with one goal or fund',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set a target, build a small saving habit, or add a spending budget.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _weeklyOverview(BuildContext context, List<Goal> goals) {
    final savingsGoals = goals
        .where((g) => g.kind != 'spending_budget')
        .toList();
    final saved = savingsGoals.fold<double>(
      0,
      (sum, goal) => sum + goal.currentAmount,
    );
    final activeBudgets = goals
        .where((g) => g.kind == 'spending_budget')
        .length;
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.savings_outlined, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Savings across your goals'),
                  Text(
                    NumberFormat.currency(
                      name: 'KES',
                      symbol: 'KES ',
                      decimalDigits: 0,
                    ).format(saved),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (activeBudgets > 0) Chip(label: Text('$activeBudgets budgets')),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Goal? goal,
  }) async {
    final saved = await showDialog<Goal>(
      context: context,
      builder: (_) => _GoalEditor(goal: goal),
    );
    if (saved != null) await ref.read(goalsProvider.notifier).saveGoal(saved);
  }
}

class _GoalCard extends ConsumerWidget {
  final Goal goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (goal.kind == 'spending_budget') return _BudgetGoalCard(goal: goal);
    final currency = NumberFormat.currency(
      name: 'KES',
      symbol: 'KES ',
      decimalDigits: 0,
    );
    final target = goal.targetAmount;
    final progress = target == null || target <= 0
        ? 0.0
        : (goal.currentAmount / target).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: _TreeProgress(progress: progress, photoPath: goal.photoPath),
        title: Text(
          goal.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_goalKinds[goal.kind] ?? 'Savings goal'} · ${currency.format(goal.currentAmount)} saved${target == null ? '' : ' of ${currency.format(target)}'}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (goal.kind == 'product')
              IconButton.filledTonal(
                tooltip: 'Search the web for ${goal.name}',
                onPressed: () => _openProductSearch(context, goal.name),
                icon: const Icon(Icons.search_rounded),
              ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  final result = await showDialog<Goal>(
                    context: context,
                    builder: (_) => _GoalEditor(goal: goal),
                  );
                  if (result != null) {
                    await ref.read(goalsProvider.notifier).saveGoal(result);
                  }
                } else if (value == 'delete') {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete this goal?'),
                      content: const Text(
                        'Its manual contribution entries will also be removed. Transactions will remain saved and become unassigned.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(goalsProvider.notifier).deleteGoal(goal.id!);
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (target != null && target > 0) ...[
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${(progress * 100).round()}% · ${goal.planningMode == 'amount' ? 'saving' : 'suggested'} ${currency.format(_suggestedContribution(goal))} per contribution',
              ),
            ),
          ],
          if (goal.deadline != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Target date: ${DateFormat.yMMMd().format(goal.deadline!)}',
              ),
            ),
          if (goal.planningMode == 'amount' &&
              _estimatedFinishDate(goal) != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Estimated finish: ${DateFormat.yMMMd().format(_estimatedFinishDate(goal)!)}',
              ),
            ),
          const SizedBox(height: 12),
          GoalCommitmentGraph(goal: goal),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _editContribution(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('Log saving'),
                ),
              ),
              const SizedBox(width: 8),
              if (goal.accountName?.isNotEmpty == true)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _reviewSms(context, ref),
                    icon: const Icon(Icons.sms_outlined),
                    label: const Text('Review SMS'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Account match: ${goal.accountName?.isNotEmpty == true ? goal.accountName : 'Manual entries only'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _ContributionList(goal: goal),
        ],
      ),
    );
  }

  double _suggestedContribution(Goal goal) {
    if (goal.planningMode == 'amount' ||
        goal.targetAmount == null ||
        goal.deadline == null) {
      return goal.contributionAmount ?? 0;
    }
    final now = DateTime.now();
    final slots = _scheduledSlots(now, goal.deadline!, goal).clamp(1, 36500);
    return ((goal.targetAmount! - goal.currentAmount).clamp(
          0,
          double.infinity,
        )) /
        slots;
  }

  Future<void> _editContribution(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? existing,
  }) async {
    final amount = TextEditingController(
      text: existing?['amount']?.toString() ?? '',
    );
    final note = TextEditingController(
      text: existing?['note']?.toString() ?? '',
    );
    final result = await showDialog<(double, String?)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Log a saving' : 'Edit saving'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Amount (KES)'),
            ),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(amount.text.trim());
              if (value != null && value > 0) {
                Navigator.pop(context, (
                  value,
                  note.text.trim().isEmpty ? null : note.text.trim(),
                ));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    amount.dispose();
    note.dispose();
    if (result != null) {
      await ref
          .read(goalsProvider.notifier)
          .saveContribution(
            id: existing?['id'] as int?,
            goalId: goal.id!,
            amount: result.$1,
            date: existing == null
                ? DateTime.now()
                : DateTime.parse(existing['date'] as String),
            note: result.$2,
          );
    }
  }

  Future<void> _reviewSms(BuildContext context, WidgetRef ref) async {
    final db = await DatabaseHelper.instance.database;
    final transactions = await GoalsLs(
      db,
    ).getMatchingTransactionsSinceInception(goal.id!);
    if (!context.mounted) return;
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No matching M-Pesa messages since this goal started.'),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign ${goal.accountName} transfers'),
        content: SizedBox(
          width: 420,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final inbound = tx.type == 'inbound';
              return Card(
                child: ExpansionTile(
                  leading: Icon(
                    inbound ? Icons.south_west : Icons.north_east,
                    color: inbound ? Colors.orange : Colors.green,
                  ),
                  title: Text(
                    '${inbound ? 'Received' : 'Sent'} KES ${(tx.amount ?? 0).toStringAsFixed(0)} · ${tx.date == null ? '' : DateFormat.yMMMd().format(tx.date!)}',
                  ),
                  subtitle: Text(
                    '${tx.vendor ?? ''} · ${tx.goalId == goal.id
                        ? 'Counted here'
                        : tx.goalId == null
                        ? 'Unassigned'
                        : 'Counted toward another goal'}',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        tx.rawSmsMessage ??
                            tx.description ??
                            'The original SMS text is unavailable.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: () async {
                          await ref
                              .read(goalsProvider.notifier)
                              .assignTransaction(tx.id!, goal.id!);
                          if (context.mounted) Navigator.pop(context);
                        },
                        icon: Icon(
                          tx.goalId == goal.id
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                        ),
                        label: const Text('Assign this exact message'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ContributionList extends ConsumerWidget {
  final Goal goal;
  const _ContributionList({required this.goal});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: DatabaseHelper.instance.database.then(
      (db) => GoalsLs(db).getContributionTimeline(goal.id!),
    ),
    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const SizedBox.shrink();
      }
      final rows = snapshot.data!
        ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text(
              'Recent contributions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final row in rows.take(6))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                row['source'] == 'sms' ? Icons.sms_outlined : Icons.edit_note,
                size: 20,
              ),
              title: Text(
                '${row['source'] == 'sms' ? 'M-Pesa transfer' : 'Manual saving'} · KES ${(row['amount'] as num).toStringAsFixed(0)}',
              ),
              subtitle: Text(
                '${row['note'] ?? ''} ${DateFormat.yMMMd().format(DateTime.parse(row['date'] as String))}',
              ),
              trailing: row['source'] == 'manual'
                  ? PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await ref
                              .read(goalsProvider.notifier)
                              .deleteContribution(row['id'] as int);
                        } else {
                          final amount = TextEditingController(
                            text: row['amount'].toString(),
                          );
                          final note = TextEditingController(
                            text: row['note']?.toString() ?? '',
                          );
                          final edited = await showDialog<(double, String?)>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Edit saving'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: amount,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Amount',
                                    ),
                                  ),
                                  TextField(
                                    controller: note,
                                    decoration: const InputDecoration(
                                      labelText: 'Note',
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    final n = double.tryParse(amount.text);
                                    if (n != null && n > 0) {
                                      Navigator.pop(context, (n, note.text));
                                    }
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                          amount.dispose();
                          note.dispose();
                          if (edited != null) {
                            await ref
                                .read(goalsProvider.notifier)
                                .saveContribution(
                                  id: row['id'] as int,
                                  goalId: goal.id!,
                                  amount: edited.$1,
                                  date: DateTime.parse(row['date'] as String),
                                  note: edited.$2,
                                );
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    )
                  : null,
            ),
        ],
      );
    },
  );
}

class _BudgetGoalCard extends ConsumerWidget {
  final Goal goal;
  const _BudgetGoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) => FutureBuilder<double>(
    future: _spent(),
    builder: (context, snapshot) {
      final spent = snapshot.data ?? 0;
      final progress = goal.limitAmount <= 0
          ? 0.0
          : (spent / goal.limitAmount).clamp(0.0, 1.0);
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.account_balance_wallet_outlined),
          ),
          title: Text(
            goal.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${goal.scheduleType.toUpperCase()} spending budget · KES ${spent.toStringAsFixed(0)} / ${goal.limitAmount.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: progress),
              if (goal.startDate != null && goal.endDate != null)
                Text(
                  '${DateFormat.yMMMd().format(goal.startDate!)} – ${DateFormat.yMMMd().format(goal.endDate!)}',
                ),
            ],
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              final notifier = ref.read(goalsProvider.notifier);
              if (value == 'edit') {
                final edited = await showDialog<Goal>(
                  context: context,
                  builder: (_) => _GoalEditor(goal: goal),
                );
                if (edited != null) await notifier.saveGoal(edited);
              } else {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete budget?'),
                    content: const Text(
                      'The original saved budget record will remain available for recovery.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) await notifier.deleteGoal(goal.id!);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      );
    },
  );

  Future<double> _spent() async {
    final db = await DatabaseHelper.instance.database;
    final row = await db.rawQuery(
      '''SELECT COALESCE(SUM(amount), 0) total FROM transactions
      WHERE type IN ('outbound', 'withdrawal') AND date >= ? AND date <= ?''',
      [
        goal.startDate?.toIso8601String() ?? '0000',
        goal.endDate?.toIso8601String() ?? '9999',
      ],
    );
    return (row.first['total'] as num).toDouble();
  }
}

class _TreeProgress extends StatelessWidget {
  final double progress;
  final String? photoPath;
  const _TreeProgress({required this.progress, this.photoPath});

  @override
  Widget build(BuildContext context) {
    if (photoPath != null && File(photoPath!).existsSync()) {
      return CircleAvatar(backgroundImage: FileImage(File(photoPath!)));
    }
    final icon = progress >= 0.75
        ? Icons.local_florist
        : progress >= 0.4
        ? Icons.park
        : progress >= 0.1
        ? Icons.eco
        : Icons.grass;
    return CircleAvatar(child: Icon(icon, color: Colors.green.shade700));
  }
}

class _GoalEditor extends StatefulWidget {
  final Goal? goal;
  const _GoalEditor({this.goal});

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _account;
  late final TextEditingController _perContribution;
  late final TextEditingController _limit;
  late Set<int> _savingDays;
  late String _kind;
  late String _planningMode;
  late String _schedule;
  late int _count;
  DateTime? _deadline;
  late DateTime _budgetStart;
  late DateTime _budgetEnd;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _name = TextEditingController(text: goal?.name ?? '');
    _target = TextEditingController(text: goal?.targetAmount?.toString() ?? '');
    _account = TextEditingController(text: goal?.accountName ?? '');
    _perContribution = TextEditingController(
      text: goal?.contributionAmount?.toString() ?? '',
    );
    _limit = TextEditingController(text: goal?.limitAmount.toString() ?? '');
    _savingDays = goal?.savingDays.toSet() ?? <int>{};
    _kind = goal?.kind ?? 'product';
    _planningMode =
        goal?.planningMode ??
        (goal?.deadline == null && goal?.contributionAmount != null
            ? 'amount'
            : 'deadline');
    _schedule = goal?.scheduleType ?? 'weekly';
    _count = goal?.contributionsPerWeek ?? 3;
    _deadline = goal?.deadline;
    _budgetStart = goal?.startDate ?? DateTime.now();
    _budgetEnd = goal?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _photoPath = goal?.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _account.dispose();
    _perContribution.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    final directory = await getApplicationDocumentsDirectory();
    final ext = image.path.contains('.')
        ? image.path.substring(image.path.lastIndexOf('.'))
        : '.jpg';
    final destination = File(
      '${directory.path}/goal_${DateTime.now().microsecondsSinceEpoch}$ext',
    );
    await File(image.path).copy(destination.path);
    if (mounted) setState(() => _photoPath = destination.path);
  }

  Goal get _previewGoal => Goal(
    name: _name.text,
    kind: _kind,
    planningMode: _planningMode,
    targetAmount: double.tryParse(_target.text.trim()),
    currentAmount: widget.goal?.currentAmount ?? 0,
    scheduleType: _schedule,
    savingDays: _savingDays.toList(),
    contributionsPerWeek: _savingDays.isEmpty ? _count : _savingDays.length,
    contributionAmount: double.tryParse(_perContribution.text.trim()),
    deadline: _deadline,
  );

  double? _calculatedContribution() {
    final preview = _previewGoal;
    final deadline = _deadline;
    final target = preview.targetAmount;
    if (target == null || deadline == null) return null;
    final slots = _scheduledSlots(DateTime.now(), deadline, preview);
    if (slots == 0) return null;
    return ((target - preview.currentAmount).clamp(0, double.infinity)) / slots;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.goal == null ? 'Create a goal or budget' : 'Edit goal'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _goalKinds.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _kind = value ?? 'product';
                if (_kind == 'spending_budget') {
                  if (_schedule == 'daily') _schedule = 'weekly';
                } else if (_schedule != 'daily' && _schedule != 'weekly') {
                  _schedule = 'weekly';
                }
              }),
            ),
            if (_kind == 'product')
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _name,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Search the web for this product',
                    onPressed: () => _openProductSearch(context, _name.text),
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              )
            else
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            if (_kind == 'product' ||
                _kind == 'squirrel' ||
                _kind == 'rainy_day' ||
                _kind == 'icoe') ...[
              TextField(
                controller: _target,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _kind == 'product'
                      ? 'Declared price / target (KES)'
                      : 'Target (optional, KES)',
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_kind == 'product') ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _photoPath == null
                          ? 'Add product photo (optional)'
                          : 'Change product photo',
                    ),
                  ),
                ),
                if (_photoPath != null)
                  Image.file(File(_photoPath!), height: 70, fit: BoxFit.cover),
              ],
              TextField(
                controller: _account,
                decoration: const InputDecoration(
                  labelText: 'Account name from M-Pesa SMS (optional)',
                  hintText: 'e.g. Ziidi or KCB',
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: _schedule,
                decoration: const InputDecoration(labelText: 'Saving schedule'),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Every day')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (value) => setState(() => _schedule = value!),
              ),
              if (_schedule == 'weekly') ...[
                DropdownButtonFormField<int>(
                  initialValue: _count,
                  decoration: const InputDecoration(
                    labelText: 'Contributions per week',
                  ),
                  items: List.generate(
                    7,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1} times a week'),
                    ),
                  ),
                  onChanged: (value) => setState(() {
                    _count = value ?? 3;
                    _savingDays.clear();
                  }),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      'Choose weekdays (optional)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    const labels = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    return FilterChip(
                      label: Text(labels[index]),
                      selected: _savingDays.contains(day),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _savingDays.add(day);
                          _count = _savingDays.length;
                        } else {
                          _savingDays.remove(day);
                          if (_savingDays.isNotEmpty) {
                            _count = _savingDays.length;
                          }
                        }
                      }),
                    );
                  }),
                ),
              ],
              if ((_kind == 'product' ||
                  (double.tryParse(_target.text.trim()) ?? 0) > 0)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Which do you want to choose?',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Saving amount'),
                      selected: _planningMode == 'amount',
                      onSelected: (_) =>
                          setState(() => _planningMode = 'amount'),
                    ),
                    ChoiceChip(
                      label: const Text('Deadline'),
                      selected: _planningMode == 'deadline',
                      onSelected: (_) =>
                          setState(() => _planningMode = 'deadline'),
                    ),
                  ],
                ),
                if (_planningMode == 'amount') ...[
                  TextField(
                    controller: _perContribution,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Amount per saving contribution (KES)',
                    ),
                  ),
                  if (_estimatedFinishDate(_previewGoal) != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Estimated finish: ${DateFormat.yMMMd().format(_estimatedFinishDate(_previewGoal)!)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ] else ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      _deadline == null
                          ? 'Choose a deadline'
                          : 'Deadline: ${DateFormat.yMMMd().format(_deadline!)}',
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            _deadline ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _deadline = date);
                    },
                  ),
                  if (_calculatedContribution() != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Suggested: KES ${_calculatedContribution()!.toStringAsFixed(0)} per contribution',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ] else
                TextField(
                  controller: _perContribution,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Regular amount per saving (KES)',
                  ),
                ),
            ] else ...[
              DropdownButtonFormField<String>(
                initialValue: _schedule,
                decoration: const InputDecoration(labelText: 'Budget period'),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(
                    value: 'quarterly',
                    child: Text('Quarterly'),
                  ),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text('Custom dates'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _schedule = value ?? 'custom'),
              ),
              TextField(
                controller: _limit,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Spending limit (KES)',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Budget starts'),
                subtitle: Text(DateFormat.yMMMd().format(_budgetStart)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _budgetStart,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _budgetStart = date);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Budget ends'),
                subtitle: Text(DateFormat.yMMMd().format(_budgetEnd)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _budgetEnd.isBefore(_budgetStart)
                        ? _budgetStart
                        : _budgetEnd,
                    firstDate: _budgetStart,
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _budgetEnd = date);
                },
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save')),
    ],
  );

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final target = double.tryParse(_target.text.trim());
    final limit = double.tryParse(_limit.text.trim()) ?? 0;
    final enteredContribution = double.tryParse(_perContribution.text.trim());
    if (_kind == 'product' && (target == null || target <= 0)) return;
    if (_kind == 'spending_budget' && limit <= 0) return;
    final hasTarget = target != null && target > 0;
    final planningMode = hasTarget ? _planningMode : 'amount';
    if (_kind != 'spending_budget' &&
        planningMode == 'amount' &&
        (enteredContribution == null || enteredContribution <= 0)) {
      return;
    }
    if (_kind != 'spending_budget' &&
        planningMode == 'deadline' &&
        hasTarget &&
        _deadline == null) {
      return;
    }
    final days = _savingDays.toList()..sort();
    final goal = Goal(
      id: widget.goal?.id,
      name: name,
      kind: _kind,
      planningMode: _kind == 'spending_budget' ? 'deadline' : planningMode,
      targetAmount: _kind == 'spending_budget' ? null : target,
      currentAmount: widget.goal?.currentAmount ?? 0,
      deadline: planningMode == 'amount' ? null : _deadline,
      photoPath: _photoPath,
      accountName: _account.text.trim().isEmpty ? null : _account.text.trim(),
      scheduleType: _schedule,
      savingDays: _schedule == 'weekly' ? days.take(_count).toList() : const [],
      contributionsPerWeek: days.isEmpty ? _count : days.length,
      contributionAmount: planningMode == 'amount' ? enteredContribution : null,
      limitAmount: limit,
      startDate: _budgetStart,
      endDate: DateTime(
        (_budgetEnd.isBefore(_budgetStart) ? _budgetStart : _budgetEnd).year,
        (_budgetEnd.isBefore(_budgetStart) ? _budgetStart : _budgetEnd).month,
        (_budgetEnd.isBefore(_budgetStart) ? _budgetStart : _budgetEnd).day,
        23,
        59,
        59,
      ),
      budgetStatus: widget.goal?.budgetStatus ?? 'ACTIVE',
      legacyPlanId: widget.goal?.legacyPlanId,
      legacyGoalId: widget.goal?.legacyGoalId,
    );
    Navigator.pop(context, goal);
  }
}
