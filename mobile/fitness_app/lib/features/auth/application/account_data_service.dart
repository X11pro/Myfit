import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final accountDataServiceProvider = Provider<AccountDataService>((ref) {
  return const AccountDataService();
});

class AccountDataService {
  const AccountDataService();

  Future<Map<String, dynamic>> exportMyData() async {
    final response = await Supabase.instance.client.functions.invoke(
      'user-data-manage',
      body: const {'action': 'export'},
    );

    final payload = _map(response.data);
    final error = payload['error']?.toString().trim();
    if (error != null && error.isNotEmpty) {
      throw StateError(error);
    }

    return _map(payload['data']);
  }

  Future<void> deleteMyData() async {
    final response = await Supabase.instance.client.functions.invoke(
      'user-data-manage',
      body: const {'action': 'delete'},
    );

    final payload = _map(response.data);
    final error = payload['error']?.toString().trim();
    if (error != null && error.isNotEmpty) {
      throw StateError(error);
    }
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is String) {
      return _map(jsonDecode(value));
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    throw const FormatException('Invalid account data response.');
  }
}
