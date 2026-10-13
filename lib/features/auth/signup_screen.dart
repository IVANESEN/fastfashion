import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/validation/validators.dart';
import '../../core/widgets/ff_button.dart';
import '../../core/widgets/ff_icon_button.dart';
import '../../core/widgets/ff_link_prompt.dart';
import '../../core/widgets/ff_text_field.dart';
import 'auth_controller.dart';
import 'auth_form_scaffold.dart';

/// Crear cuenta. Al terminar, el router lleva al clóset vacío.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();
    auth.clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    await auth.signUp(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return AuthFormScaffold(
      title: 'Crea tu clóset',
      subtitle: 'Tarda menos de un minuto. Después subes tu ropa y listo.',
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
                  controller: _name,
                  label: 'Nombre',
                  hint: 'Cómo te llamas',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.givenName],
                  validator: Validators.name,
                ),
                const SizedBox(height: 16),
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
                  hint: 'Mínimo ${Validators.minPasswordLength} caracteres',
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: Validators.password,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        FfButton(
          label: 'Crear mi clóset',
          loading: auth.busy,
          height: 56,
          onPressed: _submit,
        ),
        const SizedBox(height: 20),
        FfLinkPrompt(
          prompt: '¿Ya tienes cuenta?',
          action: 'Inicia sesión',
          onTap: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
