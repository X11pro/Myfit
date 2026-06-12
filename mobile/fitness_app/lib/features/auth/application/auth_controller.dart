import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/app_state.dart';

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

class AuthController {
  AuthController(this._ref);

  final Ref _ref;

  Future<void> signInAnonymouslyForPrototype() async {
    final notifier = _ref.read(appStateProvider.notifier);
    notifier.setLoading(true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    notifier.setAuthenticated(true);
    notifier.setLoading(false);
  }

  void signOut() {
    final notifier = _ref.read(appStateProvider.notifier);
    notifier.reset();
  }
}
