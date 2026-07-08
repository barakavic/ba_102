import 'package:flutter/material.dart';

class AddItemRow extends StatefulWidget {
  final Color listColor;
  final void Function(String name, double? price) onAdd;

  const AddItemRow({super.key, required this.listColor, required this.onAdd});

  @override
  State<AddItemRow> createState() => _AddItemRowState();
}

class _AddItemRowState extends State<AddItemRow> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  bool _expanded = false;

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final price = double.tryParse(_priceController.text.trim());
    widget.onAdd(name, price);
    _nameController.clear();
    _priceController.clear();
    setState(() => _expanded = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  onTap: () => setState(() => _expanded = true),
                  decoration: InputDecoration(
                    hintText: 'Add item...',
                    hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.add_circle_outline, color: widget.listColor, size: 20),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              if (_expanded)
                TextButton(
                  onPressed: _submit,
                  child: Text('Add', style: TextStyle(color: widget.listColor, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 8, bottom: 4),
              child: TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  hintText: 'Estimated price (optional)',
                  hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
