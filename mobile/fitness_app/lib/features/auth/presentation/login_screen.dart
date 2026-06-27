import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  String? _submittedEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final controller = ref.read(authControllerProvider);
    final isConfigured = AppEnv.hasSupabaseConfig;
    final isBusy = appState.isLoading;
    final strings = stringsFor(ref);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Myfit',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 12),
              Text(
                strings.welcomeTagline,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                isConfigured
                    ? strings.loginDescription
                    : strings.loginMissingConfig,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                enabled: isConfigured && !isBusy,
                decoration: InputDecoration(
                  labelText: strings.emailLabel,
                  hintText: strings.emailHint,
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  enabled: !isBusy,
                  decoration: InputDecoration(
                    labelText: strings.accessCodeLabel,
                    hintText: strings.accessCodeHint,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: !isConfigured || isBusy
                      ? null
                      : () async {
                          if (_codeSent) {
                            await _verifyCode(controller);
                            return;
                          }

                          await _sendCode(controller);
                        },
                  child: Text(_codeSent
                      ? strings.verifyCodeButton
                      : strings.receiveAccessCodeButton),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () {
                            setState(() {
                              _codeSent = false;
                              _codeController.clear();
                            });
                          },
                    child: Text(strings.changeEmailButton),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode(AuthController controller) async {
    final strings = stringsFor(ref);
    final email = _emailController.text.trim();

    if (!_looksLikeEmail(email)) {
      _showMessage(strings.invalidEmailMessage);
      return;
    }

    try {
      await controller.sendSignInCode(email);

      if (!mounted) {
        return;
      }

      setState(() {
        _codeSent = true;
        _submittedEmail = email;
      });
      _showMessage(strings.codeSentMessage);
    } catch (error) {
      _showMessage(strings.sendCodeErrorMessage(error));
    }
  }

  Future<void> _verifyCode(AuthController controller) async {
    final strings = stringsFor(ref);
    final email = _submittedEmail ?? _emailController.text.trim();
    final token = _codeController.text.trim();

    if (!_looksLikeEmail(email)) {
      _showMessage(strings.staleEmailMessage);
      return;
    }

    if (token.length != 6) {
      _showMessage(strings.invalidAccessCodeMessage);
      return;
    }

    try {
      await controller.verifySignInCode(email: email, token: token);
    } catch (error) {
      _showMessage(strings.verifyCodeErrorMessage(error));
    }
  }

  bool _looksLikeEmail(String value) {
    return value.contains('@') && value.contains('.');
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
