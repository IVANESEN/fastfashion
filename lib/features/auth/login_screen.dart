import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/validation/validators.dart';
import '../../core/widgets/ff_button.dart';
import '../../core/widgets/ff_icon_button.dart';
import '../../core/widgets/ff_link_prompt.dart';
import '../../core/widgets/ff_text_field.dart';
import '../../domain/entities/demo_account.dart';
import 'auth_controller.dart';
import 'auth_form_scaffold.dart';

/// Iniciar sesión. Tras el éxito, el router detecta la sesión y redirige.
class LoginScreen extends StatefulWidget {
  const LoginScreen({this.showDemoShortcut = true, super.key});

  /// Atajo "Entrar con la cuenta demo" (solo tiene sentido con base local).
  final bool showDemoShortcut;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    auth.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await auth.signIn(_email.text, _password.text);
  }

  Future<void> _demo() async {
    _email.text = DemoAccount.email;
    _password.text = DemoAccount.password;
    await _submit();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return AuthFormScaffold(
      title: 'Qué bueno verte de nuevo',
      subtitle: 'Entra para ver tu outfit de hoy.',
      error: auth.error,
      leading: FfIconButton(
        icon: Icons.arrow_back_rounded,
        label: 'Volver a la bienvenida',
        onPressed: () => context.go(AppRoutes.welcome),
      ),
      children: [
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FfTextField(
                  controller: _email,
                  label: 'Correo',
                  hint: 'tucorreo@ejemplo.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                ),
                const SizedBox(height: 16),
                FfTextField(
                  controller: _password,
                  label: 'Contraseña',
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: Validators.password,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FfButton(
          label: 'Iniciar sesión',
          loading: auth.busy,
          height: 56,
          onPressed: _submit,
        ),
        if (widget.showDemoShortcut) ...[
          const SizedBox(height: 12),
          FfButton(
            label: 'Entrar con la cuenta demo',
            style: FfButtonStyle.tonal,
            onPressed: auth.busy ? null : _demo,
          ),
        ],
        const SizedBox(height: 20),
        FfLinkPrompt(
          prompt: '¿Aún no tienes cuenta?',
          action: 'Crear mi clóset',
          onTap: () => context.go(AppRoutes.signup),
        ),
      ],
    );
  }
}
