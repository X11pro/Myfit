import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/barcode_food_lookup_result.dart';

final barcodeLookupServiceProvider = Provider<BarcodeLookupService>((ref) {
  return const BarcodeLookupService();
});

class BarcodeLookupService {
  const BarcodeLookupService();

  Future<BarcodeFoodLookupResult?> lookup(String barcode) async {
    final response = await Supabase.instance.client.functions.invoke(
      'food-barcode-lookup',
      body: {
        'barcode': barcode,
      },
    );

    final payload = _responseMap(response.data);
    final errorMessage = payload['error']?.toString();
    if (errorMessage != null && errorMessage.trim().isNotEmpty) {
      throw StateError(errorMessage);
    }

    final food = payload['food'];
    if (food == null) {
      return null;
    }

    return parseFood(food);
  }

  BarcodeFoodLookupResult parseFood(Object? value) {
    final food = _responseMap(value);
    final name = food['name']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw const FormatException('Invalid barcode food response.');
    }

    return BarcodeFoodLookupResult(
      name: name,
      brand: _asTrimmedString(food['brand']),
      source: _asTrimmedString(food['source']),
      sourceId: _asTrimmedString(food['sourceId']),
      caloriesPer100g: _asDouble(food['caloriesPer100g']),
      proteinPer100g: _asDouble(food['proteinPer100g']),
      carbsPer100g: _asDouble(food['carbsPer100g']),
      fatPer100g: _asDouble(food['fatPer100g']),
      sugarPer100g: _asDouble(food['sugarPer100g']),
      fiberPer100g: _asDouble(food['fiberPer100g']),
      confidence: _asDouble(food['confidence']),
    );
  }

  Map<String, dynamic> _responseMap(Object? data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException('Invalid function response.');
  }

  String? _asTrimmedString(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    return null;
  }

  double? _asDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }
}
