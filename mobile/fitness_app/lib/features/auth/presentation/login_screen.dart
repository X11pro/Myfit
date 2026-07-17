import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_env.dart';
import '../application/account_data_service.dart';
import '../../../shared/app_language.dart';
import '../../../shared/app_state.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen(
      {super.key, this.initialEmail = '', this.startInCodeMode = false});

  final String initialEmail;
  final bool startInCodeMode;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _codeSent = false;
  String? _submittedEmail;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail;
    _submittedEmail =
        widget.initialEmail.trim().isEmpty ? null : widget.initialEmail.trim();
    _codeSent = widget.startInCodeMode;
  }

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
    final isAuthenticated = appState.isAuthenticated;
    final strings = stringsFor(ref);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Myfit',
        strings: strings,
        backPath: _codeSent ? '/auth' : '/splash',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            children: [
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
              if (isAuthenticated) ...[
                Text(
                  strings.signedInDescription(appState.authEmail),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => context.go(
                      appState.isOnboardingComplete
                          ? '/dashboard'
                          : '/onboarding',
                    ),
                    child: Text(strings.openProfileOrDashboardButton),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () async {
                            try {
                              await controller.signOut();
                            } catch (error) {
                              _showMessage(
                                  strings.verifyCodeErrorMessage(error));
                            }
                          },
                    child: Text(strings.signOutButton),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isBusy ? null : () => _exportMyData(strings),
                    child: Text(strings.exportMyDataButton),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => _confirmDeleteMyData(strings, controller),
                    child: Text(strings.deleteMyDataButton),
                  ),
                ),
              ] else ...[
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
                  enabled: isConfigured && !_codeSent && !isBusy,
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
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !isBusy,
                    decoration: InputDecoration(
                      labelText: strings.accessCodeLabel,
                      hintText: strings.accessCodeHint,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(
                      appState.isOnboardingComplete
                          ? '/dashboard'
                          : '/onboarding',
                    ),
                    child: Text(strings.continueGuest),
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isBusy ? null : () => context.go('/auth'),
                      child: Text(strings.changeEmailButton),
                    ),
                  ),
                ],
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

      _submittedEmail = email;
      _showMessage(strings.codeSentMessage);
      if (!mounted) {
        return;
      }

      context.go('/auth/verify?email=${Uri.encodeComponent(email)}');
    } catch (error) {
      _showMessage(strings.sendCodeErrorMessage(error));
    }
  }

  Future<void> _verifyCode(AuthController controller) async {
    final strings = stringsFor(ref);
    final email = _submittedEmail ?? _emailController.text.trim();
    final token = _codeController.text.replaceAll(RegExp(r'\D'), '');

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

  Future<void> _exportMyData(AppStrings strings) async {
    try {
      final payload = await ref.read(accountDataServiceProvider).exportMyData();
      final text = const JsonEncoder.withIndent('  ').convert(payload);
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(strings.exportMyDataButton),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText('${strings.exportReadyMessage}\n\n$text'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(strings.cancelButton),
            ),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                await Clipboard.setData(ClipboardData(text: text));
                if (!mounted || !navigator.mounted) {
                  return;
                }
                navigator.pop();
                _showMessage(strings.dataCopiedMessage);
              },
              child: Text(strings.copyExportButton),
            ),
          ],
        ),
      );
    } catch (error) {
      _showMessage(error.toString());
    }
  }

  Future<void> _confirmDeleteMyData(
    AppStrings strings,
    AuthController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.deleteMyDataButton),
        content: Text(strings.deleteMyDataWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.deleteMyDataConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref.read(accountDataServiceProvider).deleteMyData();
      await controller.clearLocalSyncedData();
      await controller.signOut();
      if (!mounted) {
        return;
      }
      _showMessage(strings.dataDeletedMessage);
      context.go('/splash');
    } catch (error) {
      _showMessage(error.toString());
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
