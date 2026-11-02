import 'package:flutter/material.dart';

class CreateListDialog extends StatefulWidget {
  const CreateListDialog({super.key});

  @override
  State<CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<CreateListDialog> {
  final _titleController = TextEditingController();
  Color _selectedColor = const Color(0xFF673AB7);
  bool _isLoading = false;

  static const List<Color> _swatches = [
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF1565C0), // Blue
    Color(0xFF00796B), // Teal
    Color(0xFFC62828), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFFE65100), // Orange
    Color(0xFF2E7D32), // Green
    Color(0xFF37474F), // Blue Grey
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('New Shopping List',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'List name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Color', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _swatches.map((color) {
              final isSelected = color == _selectedColor;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 6,
                            )
                          ]
                        : [],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () {
                  if (_titleController.text.trim().isEmpty) return;
                  setState(() => _isLoading = true);
                  Navigator.pop(context, {
                    'title': _titleController.text.trim(),
                    'color': _selectedColor.toARGB32(),
                  });
                },
          style: FilledButton.styleFrom(
            backgroundColor: _selectedColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Create',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}
