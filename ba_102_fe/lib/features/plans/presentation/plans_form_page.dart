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

class PlansFormPage extends ConsumerStatefulWidget{
  const PlansFormPage({super.key});

  @override
  ConsumerState<PlansFormPage> createState() => _PlansFormPageState();

}

class _PlansFormPageState extends ConsumerState<PlansFormPage> {

  final nameCtrl = TextEditingController();
  final limitCtrl = TextEditingController();
  String selectedType = 'monthly';
  DateTime start = DateTime.now();
  DateTime end = DateTime.now().add(const Duration(days: 30));

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
      setState(() {
        if (isStart) {
          start = picked;
          // Auto-adjust end date based on type if not custom
          _updateEndDate();
        } else {
          end = picked;
          selectedType = 'custom';
        }
      });
    }
  }

  void _updateEndDate() {
    if (selectedType == 'weekly') {
      end = start.add(const Duration(days: 7));
    } else if (selectedType == 'monthly') {
      end = start.add(const Duration(days: 30));
    } else if (selectedType == 'quarterly') {
      end = start.add(const Duration(days: 90));
    } else if (selectedType == 'yearly') {
      end = start.add(const Duration(days: 365));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('New Budget Plan', style: TextStyle(fontWeight: FontWeight.bold)),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF4B0082), Color(0xFF8A2BE2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4B0082).withOpacity(0.3),
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
                onChanged: (v) => setState(() {}),
              ),
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
                onTap: () => _selectDate(context, true),
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
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a plan name")),
                    );
                    return;
                  }
                  final plan = Plan(
                    id: 0,
                    name: nameCtrl.text.trim(),
                    startDate: start,
                    endDate: end,
                    status: "ACTIVE",
                    limitAmount: double.tryParse(limitCtrl.text.trim()) ?? 0.0,
                    planType: selectedType,
                  );

                  final savePlan = ref.read(addPlanProvider);
                  await savePlan(plan);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4B0082),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: const Text("CREATE PLAN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
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
      child: Column(children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isNumber = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF4B0082)),
        border: InputBorder.none,
        labelStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}