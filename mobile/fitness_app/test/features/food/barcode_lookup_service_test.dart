import 'package:fitness_app/features/food/application/barcode_lookup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BarcodeLookupService();

  test('parseFood maps normalized barcode lookup payload', () {
    final result = service.parseFood({
      'name': 'Greek Yogurt',
      'brand': 'Demo Brand',
      'source': 'open_food_facts',
      'sourceId': '1234567890123',
      'caloriesPer100g': 97,
      'proteinPer100g': 10.2,
      'carbsPer100g': 3.8,
      'fatPer100g': 4.1,
      'sugarPer100g': 3.2,
      'fiberPer100g': 0,
      'confidence': 0.94,
    });

    expect(result.name, 'Greek Yogurt');
    expect(result.brand, 'Demo Brand');
    expect(result.source, 'open_food_facts');
    expect(result.sourceId, '1234567890123');
    expect(result.caloriesPer100g, 97);
    expect(result.proteinPer100g, 10.2);
    expect(result.confidence, 0.94);
  });

  test('parseFood throws on missing product name', () {
    expect(
      () => service.parseFood({
        'brand': 'Missing Name',
      }),
      throwsFormatException,
    );
  });
}
