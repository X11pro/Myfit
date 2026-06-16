import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
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
                'Nutricion, entrenamiento y balance energetico en una sola app.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              Text(
                isConfigured
                    ? 'Ingresa tu email para recibir un codigo de acceso y continuar con tu perfil.'
                    : 'Faltan `SUPABASE_URL` y `SUPABASE_ANON_KEY`. La autenticacion real no esta disponible hasta configurar esas variables.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                enabled: isConfigured && !isBusy,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'tu@email.com',
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  enabled: !isBusy,
                  decoration: const InputDecoration(
                    labelText: 'Codigo de acceso',
                    hintText: '6 digitos',
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
                      ? 'Verificar codigo'
                      : 'Recibir codigo de acceso'),
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
                    child: const Text('Cambiar email'),
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
    final email = _emailController.text.trim();

    if (!_looksLikeEmail(email)) {
      _showMessage('Ingresa un email valido.');
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
      _showMessage('Te enviamos un codigo por email.');
    } catch (error) {
      _showMessage('No se pudo enviar el codigo: $error');
    }
  }

  Future<void> _verifyCode(AuthController controller) async {
    final email = _submittedEmail ?? _emailController.text.trim();
    final token = _codeController.text.trim();

    if (!_looksLikeEmail(email)) {
      _showMessage('El email ya no es valido. Vuelve a intentarlo.');
      return;
    }

    if (token.length != 6) {
      _showMessage('Ingresa el codigo de 6 digitos.');
      return;
    }

    try {
      await controller.verifySignInCode(email: email, token: token);
    } catch (error) {
      _showMessage('No se pudo verificar el codigo: $error');
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
