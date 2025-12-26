import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/local/plan_ls.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/features/plans/presentation/plans_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final addPlanProvider = Provider ((ref){
  return (Plan plan) async {
    final db = await DatabaseHelper.instance.database;
    await PlanLs(db).insertPlan(plan);
    ref.refresh(plansProvider);
  };
});

class PlansFormPage extends ConsumerStatefulWidget {
  final Plan? plan;
  const PlansFormPage({super.key, this.plan});

  @override
  ConsumerState<PlansFormPage> createState() => _PlansFormPageState();
}

class _PlansFormPageState extends ConsumerState<PlansFormPage> {
  late final TextEditingController nameCtrl;
  late final TextEditingController limitCtrl;
  late String selectedType;
  late DateTime start;
  late DateTime end;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.plan?.name ?? '');
    limitCtrl = TextEditingController(text: widget.plan?.limitAmount.toString() ?? '');
    selectedType = widget.plan?.planType ?? 'monthly';
    start = widget.plan?.startDate ?? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    end = widget.plan?.endDate ?? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? start : end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4B0082),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (isStart && widget.plan != null) {
        final now = DateTime.now();
        final planStart = widget.plan!.startDate;
        if (now.isAfter(planStart) || now.isAtSameMomentAs(planStart)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Cannot change start date: This plan has already started."),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        if (isStart) {
          start = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
          // Auto-adjust end date based on type if not custom
          _updateEndDate();
        } else {
          end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
          selectedType = 'custom';
        }
      });
    }
  }

  void _updateEndDate() {
    if (selectedType == 'weekly') {
      end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    } else if (selectedType == 'monthly') {
      end = start.add(const Duration(days: 29, hours: 23, minutes: 59, seconds: 59));
    } else if (selectedType == 'quarterly') {
      end = start.add(const Duration(days: 89, hours: 23, minutes: 59, seconds: 59));
    } else if (selectedType == 'yearly') {
      end = start.add(const Duration(days: 364, hours: 23, minutes: 59, seconds: 59));
    }
  }

  bool get _isLimitInvalid {
    final val = double.tryParse(limitCtrl.text.trim());
    return val != null && val < 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.plan == null ? 'New Budget Plan' : 'Edit Plan', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLimitInvalid 
                    ? [Colors.red.shade800, Colors.red.shade400]
                    : [const Color(0xFF4B0082), const Color(0xFF8A2BE2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (_isLimitInvalid ? Colors.red : const Color(0xFF4B0082)).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameCtrl.text.isEmpty ? "Plan Name" : nameCtrl.text,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${selectedType.toUpperCase()} • ${start.toLocal().toIso8601String().substring(0, 10)} to ${end.toLocal().toIso8601String().substring(0, 10)}",
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  const Text("BUDGET LIMIT", style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.5)),
                  Text(
                    "KES ${limitCtrl.text.isEmpty ? '0' : limitCtrl.text}",
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                  if (_isLimitInvalid)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "⚠️ Limit cannot be negative",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Form Fields
            _buildSectionTitle("Basic Details"),
            _buildCard([
              _buildTextField(
                controller: nameCtrl,
                label: "Plan Name",
                icon: Icons.edit_note,
                hint: "e.g. January Savings",
                onChanged: (v) => setState(() {}),
              ),
              const Divider(height: 30),
              _buildTextField(
                controller: limitCtrl,
                label: "Budget Limit (KES)",
                icon: Icons.account_balance_wallet,
                hint: "0.00",
                isNumber: true,
                readOnly: widget.plan != null,
                error: _isLimitInvalid ? "Invalid limit" : (widget.plan != null ? "Limits cannot be changed after creation" : null),
                onChanged: (v) => setState(() {}),
              ),
              if (widget.plan == null) ...[
                const SizedBox(height: 10),
                const Text(
                  "Recommended Limits:",
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [5000, 10000, 20000, 50000].map((amount) {
                    return ActionChip(
                      label: Text("KES ${amount ~/ 1000}k"),
                      labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF4B0082)),
                      backgroundColor: const Color(0xFF4B0082).withOpacity(0.05),
                      onPressed: () {
                        setState(() {
                          limitCtrl.text = amount.toString();
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ]),

            const SizedBox(height: 25),
            _buildSectionTitle("Duration & Timeline"),
            _buildCard([
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: "Plan Type",
                  prefixIcon: Icon(Icons.timer, color: Color(0xFF4B0082)),
                  border: InputBorder.none,
                ),
                items: const [
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                  DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Range')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedType = val;
                      _updateEndDate();
                    });
                  }
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today, color: Color(0xFF4B0082)),
                title: const Text("Start Date", style: TextStyle(fontSize: 14)),
                subtitle: Text(start.toLocal().toIso8601String().substring(0, 10)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (widget.plan != null) {
                    final now = DateTime.now();
                    final planStart = widget.plan!.startDate;
                    if (now.isAfter(planStart) || now.isAtSameMomentAs(planStart)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cannot change start date: This plan has already started."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                  }
                  _selectDate(context, true);
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_available, color: Color(0xFF4B0082)),
                title: const Text("End Date", style: TextStyle(fontSize: 14)),
                subtitle: Text(end.toLocal().toIso8601String().substring(0, 10)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectDate(context, false),
              ),
            ]),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLimitInvalid ? null : () async {
                  if (nameCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a plan name")),
                    );
                    return;
                  }
                  final plan = Plan(
                    id: widget.plan?.id ?? 0,
                    name: nameCtrl.text.trim(),
                    startDate: start,
                    endDate: end,
                    status: widget.plan?.status ?? "ACTIVE",
                    limitAmount: double.tryParse(limitCtrl.text.trim()) ?? 0.0,
                    planType: selectedType,
                  );

                  final savePlan = ref.read(addPlanProvider);
                  await savePlan(plan);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLimitInvalid ? Colors.grey : const Color(0xFF4B0082),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: Text(widget.plan == null ? "CREATE PLAN" : "UPDATE", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? error,
    bool isNumber = false,
    bool readOnly = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        prefixIcon: Icon(icon, color: error != null ? Colors.red : const Color(0xFF4B0082)),
        border: InputBorder.none,
        labelStyle: TextStyle(fontSize: 14, color: error != null ? Colors.red : null),
      ),
    );
  }
}