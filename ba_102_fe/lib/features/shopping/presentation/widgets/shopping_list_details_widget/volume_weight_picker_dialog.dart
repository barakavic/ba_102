import 'package:flutter/material.dart';

enum MetricMeasurementType { volume, weight }

class ParsedMetricMeasurement {
  final MetricMeasurementType type;
  final double? amount;
  final String unit; // 'ml', 'L', 'g', 'kg'

  const ParsedMetricMeasurement({
    required this.type,
    this.amount,
    required this.unit,
  });

  static ParsedMetricMeasurement parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const ParsedMetricMeasurement(
        type: MetricMeasurementType.volume,
        amount: null,
        unit: 'ml',
      );
    }

    final trimmed = raw.trim().toLowerCase();

    // Regex to match numeric part and unit part
    final match = RegExp(r'^([\d.,]+)\s*([a-zA-Z\s]+)?$').firstMatch(trimmed);
    double? amount;
    String unitStr = '';

    if (match != null) {
      final numStr = match.group(1)?.replaceAll(',', '') ?? '';
      amount = double.tryParse(numStr);
      unitStr = match.group(2)?.trim() ?? '';
    } else {
      unitStr = trimmed;
    }

    // Weight detection
    if (unitStr == 'kg' ||
        unitStr == 'kgs' ||
        unitStr.contains('kilo') ||
        unitStr == 'g' ||
        unitStr == 'gm' ||
        unitStr == 'gms' ||
        unitStr == 'gram' ||
        unitStr == 'grams' ||
        unitStr == 'lb' ||
        unitStr == 'lbs' ||
        unitStr.contains('pound') ||
        unitStr == 'oz') {
      // Imperial conversions if present
      if ((unitStr == 'lb' || unitStr == 'lbs' || unitStr.contains('pound')) &&
          amount != null) {
        final inGrams = amount * 453.592;
        if (inGrams >= 1000) {
          return ParsedMetricMeasurement(
            type: MetricMeasurementType.weight,
            amount: double.parse((inGrams / 1000).toStringAsFixed(2)),
            unit: 'kg',
          );
        } else {
          return ParsedMetricMeasurement(
            type: MetricMeasurementType.weight,
            amount: inGrams.roundToDouble(),
            unit: 'g',
          );
        }
      }

      if (unitStr == 'oz' && amount != null) {
        final inGrams = amount * 28.3495;
        return ParsedMetricMeasurement(
          type: MetricMeasurementType.weight,
          amount: inGrams.roundToDouble(),
          unit: 'g',
        );
      }

      final isKg = unitStr == 'kg' || unitStr == 'kgs' || unitStr.contains('kilo');
      return ParsedMetricMeasurement(
        type: MetricMeasurementType.weight,
        amount: amount,
        unit: isKg ? 'kg' : 'g',
      );
    }

    // Volume detection (ml, L, gal, etc.)
    if (unitStr == 'gal' || unitStr.contains('gallon')) {
      if (amount != null) {
        final inLitres = amount * 3.78541;
        return ParsedMetricMeasurement(
          type: MetricMeasurementType.volume,
          amount: double.parse(inLitres.toStringAsFixed(2)),
          unit: 'L',
        );
      }
    }

    if (unitStr == 'fl oz' || unitStr == 'floz') {
      if (amount != null) {
        final inMl = amount * 29.5735;
        return ParsedMetricMeasurement(
          type: MetricMeasurementType.volume,
          amount: inMl.roundToDouble(),
          unit: 'ml',
        );
      }
    }

    final isLitre = unitStr == 'l' ||
        unitStr == 'ltr' ||
        unitStr == 'liter' ||
        unitStr == 'liters' ||
        unitStr == 'litre' ||
        unitStr == 'litres';

    return ParsedMetricMeasurement(
      type: MetricMeasurementType.volume,
      amount: amount,
      unit: isLitre ? 'L' : 'ml',
    );
  }
}

class VolumeWeightPickerDialog extends StatefulWidget {
  final String? initialValue;
  final Color accentColor;
  final ValueChanged<String?> onApply;

  const VolumeWeightPickerDialog({
    super.key,
    this.initialValue,
    required this.accentColor,
    required this.onApply,
  });

  @override
  State<VolumeWeightPickerDialog> createState() =>
      _VolumeWeightPickerDialogState();
}

class _VolumeWeightPickerDialogState extends State<VolumeWeightPickerDialog> {
  late MetricMeasurementType _type;
  late String _unit;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final parsed = ParsedMetricMeasurement.parse(widget.initialValue);
    _type = parsed.type;
    _unit = parsed.unit;

    final initialAmountStr = parsed.amount != null
        ? (parsed.amount == parsed.amount!.toInt()
            ? parsed.amount!.toInt().toString()
            : parsed.amount.toString())
        : '';
    _amountController = TextEditingController(text: initialAmountStr);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onTypeChanged(MetricMeasurementType newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      // Set default unit for the new type
      _unit = newType == MetricMeasurementType.volume ? 'ml' : 'g';

      // Auto-adjust unit if current amount is >= 1000
      final amount = double.tryParse(_amountController.text.trim());
      if (amount != null && amount >= 1000) {
        _unit = newType == MetricMeasurementType.volume ? 'L' : 'kg';
        final promoted = amount / 1000;
        _amountController.text = _formatNum(promoted);
      }
    });
  }

  void _onUnitToggled(String newUnit) {
    if (_unit == newUnit) return;
    final currentAmount = double.tryParse(_amountController.text.trim());

    setState(() {
      if (currentAmount != null && currentAmount > 0) {
        // Direct conversion
        if (_type == MetricMeasurementType.volume) {
          if (_unit == 'ml' && newUnit == 'L') {
            _amountController.text = _formatNum(currentAmount / 1000);
          } else if (_unit == 'L' && newUnit == 'ml') {
            _amountController.text = _formatNum(currentAmount * 1000);
          }
        } else {
          if (_unit == 'g' && newUnit == 'kg') {
            _amountController.text = _formatNum(currentAmount / 1000);
          } else if (_unit == 'kg' && newUnit == 'g') {
            _amountController.text = _formatNum(currentAmount * 1000);
          }
        }
      }
      _unit = newUnit;
    });
  }

  String _formatNum(double val) {
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    // Limit decimal precision cleanly
    final s = val.toStringAsFixed(3);
    return s.replaceAll(RegExp(r'\.?0+$'), '');
  }

  /// Calculates the final formatted string with smart auto-promotion (e.g. 1000g -> 1 kg)
  String? _getFormattedResult() {
    final text = _amountController.text.trim();
    if (text.isEmpty) return null;

    final parsed = double.tryParse(text);
    if (parsed == null || parsed <= 0) return null;

    double finalAmount = parsed;
    String finalUnit = _unit;

    // Auto-promotion: >= 1000 in g -> kg; >= 1000 in ml -> L
    if (finalUnit == 'g' && finalAmount >= 1000) {
      finalAmount = finalAmount / 1000;
      finalUnit = 'kg';
    } else if (finalUnit == 'ml' && finalAmount >= 1000) {
      finalAmount = finalAmount / 1000;
      finalUnit = 'L';
    }

    return '${_formatNum(finalAmount)} $finalUnit';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.accentColor;
    final formattedResult = _getFormattedResult();
    final hasExistingValue =
        widget.initialValue != null && widget.initialValue!.trim().isNotEmpty;

    final currentAmount = double.tryParse(_amountController.text.trim());
    final isAutoPromoting = (_unit == 'g' || _unit == 'ml') &&
        currentAmount != null &&
        currentAmount >= 1000;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Title + Clear button
            Row(
              children: [
                Icon(
                  _type == MetricMeasurementType.volume
                      ? Icons.water_drop_outlined
                      : Icons.scale_outlined,
                  color: accentColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Volume / Weight',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
                if (hasExistingValue)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      widget.onApply(null);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Segmented Control: [ Volume ] | [ Weight ]
            SegmentedButton<MetricMeasurementType>(
              segments: const [
                ButtonSegment<MetricMeasurementType>(
                  value: MetricMeasurementType.volume,
                  icon: Icon(Icons.water_drop_outlined, size: 16),
                  label: Text('Volume'),
                ),
                ButtonSegment<MetricMeasurementType>(
                  value: MetricMeasurementType.weight,
                  icon: Icon(Icons.scale_outlined, size: 16),
                  label: Text('Weight'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) _onTypeChanged(set.first);
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                side: WidgetStateProperty.all(
                  BorderSide(color: accentColor.withValues(alpha: 0.3)),
                ),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return accentColor.withValues(alpha: 0.18);
                  }
                  return null;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return accentColor;
                  }
                  return theme.colorScheme.onSurface.withValues(alpha: 0.7);
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Input with Unit Toggle Pill
            Container(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Unit Toggle Pill: [ ml | L ] or [ g | kg ]
                  _buildUnitSelector(accentColor),
                ],
              ),
            ),

            // Live Preview & Auto-conversion Notice
            const SizedBox(height: 12),
            if (formattedResult != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 14, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      'Result: $formattedResult',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    if (isAutoPromoting) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(auto-converted)',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.55),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 18),

            // Dialog Actions: Cancel & Apply
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final result = _getFormattedResult();
                      widget.onApply(result);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitSelector(Color accentColor) {
    final units = _type == MetricMeasurementType.volume
        ? const ['ml', 'L']
        : const ['g', 'kg'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: units.map((u) {
          final isSelected = _unit == u;
          return InkWell(
            onTap: () => _onUnitToggled(u),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                u,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : accentColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

