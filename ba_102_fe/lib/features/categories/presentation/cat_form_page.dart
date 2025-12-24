import 'package:ba_102_fe/data/local/category_ls.dart';
import 'package:ba_102_fe/data/local/database_helper.dart';
import 'package:ba_102_fe/data/models/models.dart';
import 'package:ba_102_fe/providers/categories_provider.dart';
import 'package:ba_102_fe/services/icon_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatFormPage extends ConsumerStatefulWidget {
  final int planId;
  final Category? category;
  const CatFormPage({super.key, required this.planId, this.category});

  @override
  ConsumerState<CatFormPage> createState() => _CatFormPageState();
}

class _CatFormPageState extends ConsumerState<CatFormPage> {
  late final TextEditingController nameCtrl;
  late String selectedIcon;
  late Color selectedColor;

  final List<Map<String, dynamic>> availableIcons = IconService.availableIcons;

  final List<Color> availableColors = [
    const Color(0xFF4B0082), // Indigo
    const Color(0xFFFF5722), // Deep Orange
    const Color(0xFF009688), // Teal
    const Color(0xFFE91E63), // Pink
    const Color(0xFFFFC107), // Amber
    const Color(0xFF2196F3), // Blue
    const Color(0xFF4CAF50), // Green
    const Color(0xFF9C27B0), // Purple
    const Color(0xFF00BCD4), // Cyan
    const Color(0xFFCDDC39), // Lime
    const Color(0xFF795548), // Brown
    const Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    selectedIcon = widget.category?.icon ?? 'category';
    
    if (widget.category?.color != null) {
      try {
        selectedColor = Color(int.parse(widget.category!.color!));
      } catch (_) {
        selectedColor = availableColors[0];
      }
    } else {
      selectedColor = availableColors[0];
    }
  }

  String? _getSuggestedIconKey(String name) {
    if (name.isEmpty) return null;
    final normalized = name.toLowerCase();

    for (var item in availableIcons) {
      final key = item['name'] as String;
      final keywords = List<String>.from(item['keywords'] ?? []);

      if (normalized.contains(key) || keywords.any((k) => normalized.contains(k))) {
        return key;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.category != null ? 'Edit Category' : 'New Category',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Card
            _buildPreviewCard(),
            const SizedBox(height: 30),

            _buildSectionTitle("Category Name"),
            _buildCard([
              TextField(
                controller: nameCtrl,
                onChanged: (v) {
                  // AUTO-SUGGEST ICON: If user hasn't manually picked one, or we find a strong match
                  final suggestedIconKey = _getSuggestedIconKey(v);
                  if (suggestedIconKey != null) {
                    setState(() => selectedIcon = suggestedIconKey);
                  } else {
                    setState(() {});
                  }
                },
                decoration: const InputDecoration(
                  hintText: "e.g. Groceries",
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.edit_outlined, color: Color(0xFF4B0082)),
                ),
              ),
            ]),

            const SizedBox(height: 25),
            Row(
              children: [
                _buildSectionTitle("Select Icon"),
                const Spacer(),
                if (selectedIcon.isNotEmpty)
                  Text(
                    selectedIcon.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selectedColor,
                      letterSpacing: 1.2,
                    ),
                  ),
              ],
            ),
            _buildCard([
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: availableIcons.length,
                itemBuilder: (context, index) {
                  final item = availableIcons[index];
                  final iconData = item['icon'] as IconData;
                  final iconName = item['name'].toString().toLowerCase();
                  final isSelected = selectedIcon == iconName;

                  return GestureDetector(
                    onTap: () => setState(() => selectedIcon = iconName),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? selectedColor.withOpacity(0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected ? selectedColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        iconData,
                        color: isSelected ? selectedColor : Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ]),

            const SizedBox(height: 25),
            _buildSectionTitle("Select Color"),
            _buildCard([
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableColors.length,
                  itemBuilder: (context, index) {
                    final color = availableColors[index];
                    final isSelected = selectedColor.value == color.value;

                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: color.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  },
                ),
              ),
            ]),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a category name")),
                    );
                    return;
                  }

                  final db = await DatabaseHelper.instance.database;
                  final category = Category(
                    id: widget.category?.id ?? 0,
                    name: nameCtrl.text.trim(),
                    limitAmount: widget.category?.limitAmount ?? 0.0,
                    icon: selectedIcon,
                    color: selectedColor.value.toString(),
                    transactions: widget.category?.transactions ?? [],
                  );

                  if (widget.category != null) {
                    await CategoryLs(db).updateCategory(category);
                  } else {
                    await CategoryLs(db).insertCategory(category);
                  }

                  ref.refresh(categoriesProvider);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                child: Text(
                  widget.category != null ? "UPDATE CATEGORY" : "CREATE CATEGORY",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    IconData previewIcon = Icons.category;
    for (var item in availableIcons) {
      if (item['name'].toString().toLowerCase() == selectedIcon) {
        previewIcon = item['icon'] as IconData;
        break;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [selectedColor.withOpacity(0.8), selectedColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: selectedColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(previewIcon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameCtrl.text.isEmpty ? "Category Name" : nameCtrl.text,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Previewing your new category",
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
}