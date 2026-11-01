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
  String? brand;
  DateTime? expiryDate;
  String? volume;

  CategoryItemDraft({
    required this.id,
    String name = '',
    double quantity = 1,
    double price = 0,
    this.isBought = false,
    this.isSelected = false,
    this.brand,
    this.expiryDate,
    this.volume,
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
  double? categoryBudget;

  CategoryDraft({
    required this.id,
    String name = '',
    required this.color,
    List<CategoryItemDraft>? items,
    this.isSuggested = true,
    this.isCollapsed = false,
    this.categoryBudget,
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
  final VoidCallback? onDeleteCategory;
  final VoidCallback? onEditCategory;
  final ValueChanged<double>? onSetBudget;

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
    this.onDeleteCategory,
    this.onEditCategory,
    this.onSetBudget,
  });


  void _showCategoryOptions(BuildContext context) {
    final color = category.color;
    final formatter = NumberFormat('#,###');
    final theme = Theme.of(context);
    final catName = category.name.isEmpty ? 'Category' : category.name;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.category_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            catName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (category.categoryBudget != null &&
                              category.categoryBudget! > 0)
                            Text(
                              'Budget: KES ${formatter.format(category.categoryBudget!)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              _OptionTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Set a budget',
                sub: (category.categoryBudget != null &&
                        category.categoryBudget! > 0)
                    ? 'KES ${formatter.format(category.categoryBudget!)} currently'
                    : 'No limit yet',
                iconColor: color,
                onTap: () {
                  Navigator.pop(ctx);
                  _showBudgetDialog(context);
                },
              ),
              _OptionTile(
                icon: Icons.edit_outlined,
                label: 'Rename / edit',
                iconColor: color,
                onTap: () {
                  Navigator.pop(ctx);
                  onEditCategory?.call();
                },
              ),
              _OptionTile(
                icon: Icons.delete_outline,
                label: 'Remove this category',
                iconColor: theme.colorScheme.error,
                labelColor: theme.colorScheme.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }


  void _showBudgetDialog(BuildContext context) {
    final color = category.color;
    final catName = category.name.isEmpty ? 'Category' : category.name;
    final controller = TextEditingController(
      text: (category.categoryBudget != null && category.categoryBudget! > 0)
          ? category.categoryBudget!.toStringAsFixed(0)
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Budget for $catName',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'How much do you want to spend here?',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: 'KES ',
                  prefixStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  hintText: '0',
                  filled: true,
                  fillColor: color.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: color, width: 1.5),
                  ),
                ),
                onSubmitted: (_) {
                  final value =
                      double.tryParse(controller.text.trim()) ?? 0;
                  onSetBudget?.call(value);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final value =
                            double.tryParse(controller.text.trim()) ?? 0;
                        onSetBudget?.call(value);
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: color,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Set'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final catName = category.name.isEmpty ? 'this category' : category.name;
    final itemCount = category.items.length;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline,
                    color: theme.colorScheme.error, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Remove "$catName"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                itemCount > 0
                    ? 'You\'ll lose all $itemCount item${itemCount == 1 ? '' : 's'} in here. Gone for good.'
                    : 'This category is empty, but it\'ll be gone for good.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keep it'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDeleteCategory?.call();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Remove'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormatter = NumberFormat('#,###');
    final color = category.color;
    final duplicateIds = category.duplicateItemIds;
    final selectedCount =
        category.items.where((item) => item.isSelected).length;

    final hasBudget =
        category.categoryBudget != null && category.categoryBudget! > 0;
    final isOverBudget = hasBudget && category.total > category.categoryBudget!;

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

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KES ${currencyFormatter.format(category.total)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  if (hasBudget)
                    Text(
                      '/ KES ${currencyFormatter.format(category.categoryBudget!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isOverBudget
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                ],
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

              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                color: color.withValues(alpha: 0.7),
                tooltip: 'Category options',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showCategoryOptions(context),
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
  final VoidCallback? onDeleteItem;
  final VoidCallback? onItemMetaChanged;
  final bool hasBrand;
  final bool hasExpiry;
  final bool hasVolume;

  const _CategoryItemRow({
    super.key,
    required this.item,
    required this.isEditMode,
    this.isDuplicate = false,
    required this.accentColor,
    required this.onToggle,
    required this.onChanged,
    this.onDeleteItem,
    this.onItemMetaChanged,
    this.hasBrand = false,
    this.hasExpiry = false,
    this.hasVolume = false,
  });

  void _showItemOptions(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('dd MMM yyyy');
    final itemName = item.name.isEmpty ? 'Item' : item.name;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shopping_basket_outlined,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        itemName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _OptionTile(
                icon: Icons.branding_watermark_outlined,
                label: 'Brand',
                sub: (item.brand != null && item.brand!.isNotEmpty)
                    ? item.brand!
                    : 'Not set',
                iconColor: accentColor,
                onTap: () {
                  Navigator.pop(ctx);
                  _showTextInputDialog(
                    context,
                    title: 'Brand',
                    hint: 'e.g. Brookside, Omo, Soko...',
                    icon: Icons.branding_watermark_outlined,
                    initialValue: item.brand ?? '',
                    onSet: (val) {
                      item.brand = val.trim().isEmpty ? null : val.trim();
                      onItemMetaChanged?.call();
                    },
                  );
                },
              ),
              _OptionTile(
                icon: Icons.event_outlined,
                label: 'Expiry Date',
                sub: item.expiryDate != null
                    ? DateFormat('dd MMM yyyy').format(item.expiryDate!)
                    : 'Not set',
                iconColor: accentColor,
                onTap: () {
                  Navigator.pop(ctx);
                  _showExpiryPicker(context);
                },
              ),
              _OptionTile(
                icon: Icons.straighten_outlined,
                label: 'Volume / Weight',
                sub: (item.volume != null && item.volume!.isNotEmpty)
                    ? item.volume!
                    : 'Not set',
                iconColor: accentColor,
                onTap: () {
                  Navigator.pop(ctx);
                  _showTextInputDialog(
                    context,
                    title: 'Volume / Weight',
                    hint: 'e.g. 500ml, 2kg, 250g...',
                    icon: Icons.straighten_outlined,
                    initialValue: item.volume ?? '',
                    onSet: (val) {
                      item.volume = val.trim().isEmpty ? null : val.trim();
                      onItemMetaChanged?.call();
                    },
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 16),
              ),
              _OptionTile(
                icon: Icons.delete_outline,
                label: 'Delete item',
                iconColor: theme.colorScheme.error,
                labelColor: theme.colorScheme.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showTextInputDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required IconData icon,
    required String initialValue,
    required ValueChanged<String> onSet,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accentColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: accentColor.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                ),
                onSubmitted: (_) {
                  onSet(controller.text);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        onSet(controller.text);
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Set'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExpiryPicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item.expiryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Select expiry date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: accentColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      item.expiryDate = picked;
      onItemMetaChanged?.call();
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final name = item.name.isEmpty ? 'this item' : '"${item.name}"';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline,
                    color: theme.colorScheme.error, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Remove $name?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'You can still undo by closing without saving.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Keep it'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onDeleteItem?.call();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Remove'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

    final hasExtras = hasBrand || hasExpiry || hasVolume;

    Widget row = Row(
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

        hasExtras
            ? SizedBox(
                width: 120,
                child: _buildNameCell(isEditMode, textDecoration, textColor, theme, isDuplicate),
              )
            : Expanded(
                flex: 3,
                child: _buildNameCell(isEditMode, textDecoration, textColor, theme, isDuplicate),
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

        hasExtras
            ? SizedBox(
                width: 80,
                child: _buildPriceCell(isEditMode, textDecoration, textColor, currencyFormatter),
              )
            : Expanded(
                flex: 2,
                child: _buildPriceCell(isEditMode, textDecoration, textColor, currencyFormatter),
              ),
        const SizedBox(width: 6),

        hasExtras
            ? SizedBox(
                width: 80,
                child: _buildTotalCell(textDecoration, textColor, currencyFormatter, theme),
              )
            : Expanded(
                flex: 2,
                child: _buildTotalCell(textDecoration, textColor, currencyFormatter, theme),
              ),

        if (hasBrand) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: Text(
              item.brand ?? '—',
              style: TextStyle(fontSize: 11, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        if (hasExpiry) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 90,
            child: Text(
              item.expiryDate != null
                  ? DateFormat('dd MMM').format(item.expiryDate!)
                  : '—',
              style: TextStyle(fontSize: 11, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        if (hasVolume) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 70,
            child: Text(
              item.volume ?? '—',
              style: TextStyle(fontSize: 11, color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        SizedBox(
          width: 32,
          child: IconButton(
            icon: const Icon(Icons.more_vert, size: 18),
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            tooltip: 'Item options',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showItemOptions(context),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: row,
    );
  }

  Widget _buildNameCell(bool editMode, TextDecoration? dec, Color col, ThemeData theme, bool isDup) {
    if (editMode) {
      return TextField(
        controller: item.nameController,
        onChanged: (_) => onChanged(),
        decoration: InputDecoration(
          hintText: 'Item',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: isDup
                  ? theme.colorScheme.error
                  : theme.colorScheme.outline.withValues(alpha: 0.4),
              width: isDup ? 1.5 : 1.0,
            ),
          ),
          suffixIcon: isDup
              ? Tooltip(
                  message: 'Duplicate item name',
                  child: Icon(Icons.warning_amber_rounded,
                      size: 16, color: theme.colorScheme.error),
                )
              : null,
        ),
        style: TextStyle(decoration: dec, color: col, fontSize: 13),
        maxLines: 1,
        textInputAction: TextInputAction.next,
      );
    }
    return Text(
      item.name.isEmpty ? 'Untitled' : item.name,
      style: TextStyle(decoration: dec, color: col, fontSize: 13),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceCell(bool editMode, TextDecoration? dec, Color col, NumberFormat fmt) {
    if (editMode) {
      return TextField(
        controller: item.priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => onChanged(),
        decoration: const InputDecoration(
          prefixText: 'KES ',
          prefixStyle: TextStyle(fontSize: 11),
          hintText: '0',
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 4),
          border: UnderlineInputBorder(),
        ),
        style: TextStyle(decoration: dec, color: col, fontSize: 12),
        textInputAction: TextInputAction.done,
      );
    }
    return Text(
      'KES ${fmt.format(item.price)}',
      style: TextStyle(decoration: dec, color: col, fontSize: 12),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildTotalCell(TextDecoration? dec, Color col, NumberFormat fmt, ThemeData theme) {
    return Text(
      'KES ${fmt.format(item.total)}',
      textAlign: TextAlign.right,
      style: theme.textTheme.bodyMedium?.copyWith(
        decoration: dec,
        color: col,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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


class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final Color iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.sub,
    required this.iconColor,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLabelColor = labelColor ?? theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: effectiveLabelColor,
                    ),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
