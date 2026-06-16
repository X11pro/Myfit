import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_state.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  Future<void> sendSignInCode(String email) async {
    if (!AppEnv.hasSupabaseConfig) {
      throw StateError('Faltan SUPABASE_URL y SUPABASE_ANON_KEY.');
    }

    final notifier = _ref.read(appStateProvider.notifier);
    notifier.setLoading(true);

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
      notifier.setLoading(false);
    } catch (_) {
      notifier.setLoading(false);
      rethrow;
    }
  }

  Future<void> verifySignInCode({
    required String email,
    required String token,
  }) async {
    if (!AppEnv.hasSupabaseConfig) {
      throw StateError('Faltan SUPABASE_URL y SUPABASE_ANON_KEY.');
    }

    final notifier = _ref.read(appStateProvider.notifier);
    notifier.setLoading(true);

    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
    } catch (_) {
      notifier.setLoading(false);
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!AppEnv.hasSupabaseConfig) {
      _ref.read(appStateProvider.notifier).reset();
      return;
    }

    await Supabase.instance.client.auth.signOut();
  }
}
