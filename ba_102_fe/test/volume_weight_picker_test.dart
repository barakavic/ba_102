import 'package:ba_102_fe/features/shopping/presentation/widgets/shopping_list_details_widget/volume_weight_picker_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParsedMetricMeasurement Parser', () {
    test('parses empty or null string as default volume with ml', () {
      final parsedNull = ParsedMetricMeasurement.parse(null);
      expect(parsedNull.type, MetricMeasurementType.volume);
      expect(parsedNull.unit, 'ml');
      expect(parsedNull.amount, isNull);

      final parsedEmpty = ParsedMetricMeasurement.parse('');
      expect(parsedEmpty.type, MetricMeasurementType.volume);
      expect(parsedEmpty.unit, 'ml');
      expect(parsedEmpty.amount, isNull);
    });

    test('parses weight units correctly (g and kg)', () {
      final grams = ParsedMetricMeasurement.parse('500g');
      expect(grams.type, MetricMeasurementType.weight);
      expect(grams.amount, 500);
      expect(grams.unit, 'g');

      final kgs = ParsedMetricMeasurement.parse('2.5 kg');
      expect(kgs.type, MetricMeasurementType.weight);
      expect(kgs.amount, 2.5);
      expect(kgs.unit, 'kg');
    });

    test('parses volume units correctly (ml and L)', () {
      final ml = ParsedMetricMeasurement.parse('750ml');
      expect(ml.type, MetricMeasurementType.volume);
      expect(ml.amount, 750);
      expect(ml.unit, 'ml');

      final litres = ParsedMetricMeasurement.parse('1.5 L');
      expect(litres.type, MetricMeasurementType.volume);
      expect(litres.amount, 1.5);
      expect(litres.unit, 'L');
    });

    test('converts imperial units if present to metric equivalents', () {
      final gal = ParsedMetricMeasurement.parse('1 gal');
      expect(gal.type, MetricMeasurementType.volume);
      expect(gal.unit, 'L');
      expect(gal.amount, closeTo(3.79, 0.05));

      final lb = ParsedMetricMeasurement.parse('2 lbs');
      expect(lb.type, MetricMeasurementType.weight);
      expect(lb.unit, 'g');
      expect(lb.amount, closeTo(907, 2));
    });
  });
}

