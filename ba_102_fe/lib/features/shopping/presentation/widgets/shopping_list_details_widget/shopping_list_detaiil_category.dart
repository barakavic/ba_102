import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CategoryItemDraft {
  final String id;
  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  bool isBought;
  bool isSelected;

  CategoryItemDraft({
    required this.id,
    String name = '',
    double quantity = 1,
    double price = 0,
    this.isBought = false,
    this.isSelected = false,
  })  : nameController = TextEditingController(text: name),
        quantityController = TextEditingController(
          text: quantity <= 1
              ? '1'
              : (quantity == quantity.toInt()
                  ? quantity.toInt().toString()
                  : quantity.toString()),
        ),
        priceController = TextEditingController(
          text: price > 0
              ? (price == price.toInt()
                  ? price.toInt().toString()
                  : price.toString())
              : '',
        );

  String get name => nameController.text.trim();

  
  double get quantity {
    final parsed = double.tryParse(quantityController.text.trim());
    if (parsed == null || parsed < 1) return 1.0;
    return parsed;
  }

  double get price =>
      double.tryParse(priceController.text.trim().replaceAll(',', '')) ?? 0;
  double get total => quantity * price;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  }
}

class CategoryDraft {
  final String id;
  final TextEditingController nameController;
  final Color color;
  final List<CategoryItemDraft> items;
  bool isSuggested;
  bool isCollapsed;

  CategoryDraft({
    required this.id,
    String name = '',
    required this.color,
    List<CategoryItemDraft>? items,
    this.isSuggested = true,
    this.isCollapsed = false,
  })  : nameController = TextEditingController(text: name),
        items = items ?? [];

  String get name => nameController.text.trim();
  double get total => items.fold(0.0, (sum, item) => sum + item.total);

  
  Set<String> get duplicateItemIds {
    final counts = <String, int>{};
    for (final item in items) {
      final key = item.name.toLowerCase();
      if (key.isNotEmpty) {
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
    final dupes = <String>{};
    for (final item in items) {
      final key = item.name.toLowerCase();
      if (key.isNotEmpty && (counts[key] ?? 0) > 1) {
        dupes.add(item.id);
      }
    }
    return dupes;
  }

  void dispose() {
    nameController.dispose();
    for (final item in items) {
      item.dispose();
    }
  }
}

class DashedCircleQuestionMark extends StatelessWidget {
  final Color color;
  final double size;

  const DashedCircleQuestionMark({
    super.key,
    required this.color,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DashedCirclePainter(color: color),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            '?',
            style: TextStyle(
              color: color,
              fontSize: size * 0.65,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    const int dashCount = 8;
    const double dashAngle = (2 * math.pi) / (dashCount * 2);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * 2 * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

class ShoppingListDetailCategory extends StatelessWidget {
  final CategoryDraft category;
  final bool isEditMode;
  final bool hasDuplicateCategoryName;
  final VoidCallback onAddItem;
  final ValueChanged<CategoryItemDraft> onToggleItem;
  final VoidCallback onItemChanged;
  final VoidCallback onToggleCollapse;
  final VoidCallback? onDeleteSelectedItems;

  const ShoppingListDetailCategory({
    super.key,
    required this.category,
    this.isEditMode = true,
    this.hasDuplicateCategoryName = false,
    required this.onAddItem,
    required this.onToggleItem,
    required this.onItemChanged,
    required this.onToggleCollapse,
    this.onDeleteSelectedItems,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat('#,###');
    final color = category.color;
    final duplicateIds = category.duplicateItemIds;
    final selectedCount =
        category.items.where((item) => item.isSelected).length;

    
    final displayedItems = category.isCollapsed && category.items.length > 4
        ? category.items.take(4).toList()
        : category.items;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDuplicateCategoryName
              ? theme.colorScheme.error
              : color.withValues(alpha: 0.35),
          width: hasDuplicateCategoryName ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            maxWidth: 170,
                          ),
                          child: isEditMode
                              ? TextField(
                                  controller: category.nameController,
                                  onChanged: (_) {
                                    if (category.isSuggested) {
                                      category.isSuggested = false;
                                    }
                                    onItemChanged();
                                  },
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: hasDuplicateCategoryName
                                        ? theme.colorScheme.error
                                        : color,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    hintText: 'Category Name',
                                    hintStyle: TextStyle(
                                      color: color.withValues(alpha: 0.5),
                                    ),
                                  ),
                                )
                              : Text(
                                  category.name.isEmpty
                                      ? 'Untitled Category'
                                      : category.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ),
                    ),
                    
                    if (category.isSuggested) ...[
                      const SizedBox(width: 5),
                      DashedCircleQuestionMark(color: color),
                    ],
                    if (hasDuplicateCategoryName) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(Duplicate)',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),

              
              if (isEditMode && selectedCount > 0 && onDeleteSelectedItems != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  tooltip: 'Delete selected ($selectedCount)',
                  padding: const EdgeInsets.only(right: 6),
                  constraints: const BoxConstraints(),
                  onPressed: onDeleteSelectedItems,
                ),

              
              Text(
                'KES ${currencyFormatter.format(category.total)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),

             
              IconButton(
                icon: Icon(
                  category.isCollapsed
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 22,
                ),
                color: color.withValues(alpha: 0.8),
                tooltip: category.isCollapsed
                    ? 'Expand category'
                    : 'Collapse category (max 4 items)',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onToggleCollapse,
              ),
              const SizedBox(width: 6),

              // Inert More Vert IconButton
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                color: color.withValues(alpha: 0.7),
                tooltip: 'Category options',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Inert for now
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          
          if (category.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No items yet. Tap + below to add.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            )
          else ...[
            Column(
              children: [
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: const [
                      SizedBox(width: 34), // Checkbox spacing
                      Expanded(
                        flex: 3,
                        child: _HeaderCell(label: 'Item'),
                      ),
                      SizedBox(width: 6),
                      SizedBox(
                        width: 40,
                        child: _HeaderCell(
                          label: 'Qty',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: _HeaderCell(label: 'Price'),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: _HeaderCell(
                          label: 'Total',
                          textAlign: TextAlign.right,
                        ),
                      ),
                      SizedBox(width: 32), // More vert spacing
                    ],
                  ),
                ),
                const Divider(height: 1),
                
                ...displayedItems.map(
                  (item) => _CategoryItemRow(
                    key: ValueKey(item.id),
                    item: item,
                    isEditMode: isEditMode,
                    isDuplicate: duplicateIds.contains(item.id),
                    accentColor: color,
                    onToggle: () => onToggleItem(item),
                    onChanged: onItemChanged,
                  ),
                ),
              ],
            ),

            
            if (category.isCollapsed && category.items.length > 4)
              InkWell(
                onTap: onToggleCollapse,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '+ ${category.items.length - 4} more items (tap to expand)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ),
          ],

          const SizedBox(height: 10),

          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'add-item-${category.id}',
                backgroundColor: color,
                foregroundColor: Colors.white,
                tooltip: 'Add item to ${category.name}',
                onPressed: onAddItem,
                child: const Icon(Icons.add, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryItemRow extends StatelessWidget {
  final CategoryItemDraft item;
  final bool isEditMode;
  final bool isDuplicate;
  final Color accentColor;
  final VoidCallback onToggle;
  final VoidCallback onChanged;

  const _CategoryItemRow({
    super.key,
    required this.item,
    required this.isEditMode,
    this.isDuplicate = false,
    required this.accentColor,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat('#,###');

    
    
    final isChecked = isEditMode ? item.isSelected : item.isBought;

    
    final textDecoration =
        (!isEditMode && item.isBought) ? TextDecoration.lineThrough : null;
    final textColor = (!isEditMode && item.isBought)
        ? theme.colorScheme.onSurface.withValues(alpha: 0.45)
        : (isDuplicate ? theme.colorScheme.error : theme.colorScheme.onSurface);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          
          SizedBox(
            width: 34,
            child: Transform.scale(
              scale: 0.85,
              child: Checkbox(
                value: isChecked,
                shape: const CircleBorder(),
                activeColor: accentColor,
                onChanged: (_) => onToggle(),
              ),
            ),
          ),

         
          Expanded(
            flex: 3,
            child: isEditMode
                ? TextField(
                    controller: item.nameController,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(
                      hintText: 'Item',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDuplicate
                              ? theme.colorScheme.error
                              : theme.colorScheme.outline.withValues(alpha: 0.4),
                          width: isDuplicate ? 1.5 : 1.0,
                        ),
                      ),
                      suffixIcon: isDuplicate
                          ? Tooltip(
                              message: 'Duplicate item name',
                              child: Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: theme.colorScheme.error,
                              ),
                            )
                          : null,
                    ),
                    style: TextStyle(
                      decoration: textDecoration,
                      color: textColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    textInputAction: TextInputAction.next,
                  )
                : Text(
                    item.name.isEmpty ? 'Untitled' : item.name,
                    style: TextStyle(
                      decoration: textDecoration,
                      color: textColor,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 6),

          
          SizedBox(
            width: 40,
            child: isEditMode
                ? TextField(
                    controller: item.quantityController,
                    textAlign: TextAlign.center,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) {
                      final parsed = double.tryParse(val.trim());
                      if (parsed != null && parsed < 1) {
                        
                        item.quantityController.text = '1';
                        item.quantityController.selection =
                            TextSelection.fromPosition(
                          const TextPosition(offset: 1),
                        );
                      }
                      onChanged();
                    },
                    decoration: const InputDecoration(
                      hintText: '1',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: UnderlineInputBorder(),
                    ),
                    style: TextStyle(
                      decoration: textDecoration,
                      color: textColor,
                      fontSize: 13,
                    ),
                    textInputAction: TextInputAction.next,
                  )
                : Text(
                    item.quantity.toInt().toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: textDecoration,
                      color: textColor,
                      fontSize: 13,
                    ),
                  ),
          ),
          const SizedBox(width: 6),

          
          Expanded(
            flex: 2,
            child: isEditMode
                ? TextField(
                    controller: item.priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      prefixText: 'KES ',
                      prefixStyle: TextStyle(fontSize: 11),
                      hintText: '0',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: UnderlineInputBorder(),
                    ),
                    style: TextStyle(
                      decoration: textDecoration,
                      color: textColor,
                      fontSize: 12,
                    ),
                    textInputAction: TextInputAction.done,
                  )
                : Text(
                    'KES ${currencyFormatter.format(item.price)}',
                    style: TextStyle(
                      decoration: textDecoration,
                      color: textColor,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          const SizedBox(width: 6),

          
          Expanded(
            flex: 2,
            child: Text(
              'KES ${currencyFormatter.format(item.total)}',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: textDecoration,
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              tooltip: 'More',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
              
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final TextAlign? textAlign;

  const _HeaderCell({required this.label, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.55),
          ),
    );
  }
}
