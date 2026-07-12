import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/barcode_food_lookup_result.dart';

final barcodeLookupServiceProvider = Provider<BarcodeLookupService>((ref) {
  return const BarcodeLookupService();
});

class BarcodeLookupService {
  const BarcodeLookupService();

  Future<BarcodeFoodLookupResult?> lookup(String barcode) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'food-barcode-lookup',
        body: {
          'barcode': barcode,
        },
      );

      final payload = _responseMap(response.data);
      final errorMessage = payload['error']?.toString();
      if (errorMessage != null && errorMessage.trim().isNotEmpty) {
        throw BarcodeLookupException(errorMessage);
      }

      final food = payload['food'];
      if (food == null) {
        return null;
      }

      return parseFood(
        food,
        cached: payload['cached'] == true,
      );
    } on FunctionException catch (error) {
      throw BarcodeLookupException(_messageFromFunctionException(error));
    }
  }

  BarcodeFoodLookupResult parseFood(Object? value, {bool cached = false}) {
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
      cached: cached,
      caloriesPer100g: _asDouble(food['caloriesPer100g']),
      proteinPer100g: _asDouble(food['proteinPer100g']),
      carbsPer100g: _asDouble(food['carbsPer100g']),
      fatPer100g: _asDouble(food['fatPer100g']),
      sugarPer100g: _asDouble(food['sugarPer100g']),
      fiberPer100g: _asDouble(food['fiberPer100g']),
      confidence: _asDouble(food['confidence']),
      nutritionQualityScore: _asDouble(food['nutritionQualityScore']),
      nutritionQualityReason: _asTrimmedString(food['nutritionQualityReason']),
    );
  }

  Map<String, dynamic> _responseMap(Object? data) {
    if (data is String) {
      final decoded = jsonDecode(data);
      return _responseMap(decoded);
    }

    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException('Invalid function response.');
  }

  String _messageFromFunctionException(FunctionException error) {
    final details = error.details;
    if (details == null) {
      return error.reasonPhrase?.trim().isNotEmpty == true
          ? error.reasonPhrase!.trim()
          : 'Barcode lookup failed.';
    }

    try {
      final payload = _responseMap(details);
      final message = payload['error']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }
    } catch (_) {
      final text = details.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return error.reasonPhrase?.trim().isNotEmpty == true
        ? error.reasonPhrase!.trim()
        : 'Barcode lookup failed.';
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

class BarcodeLookupException implements Exception {
  const BarcodeLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
