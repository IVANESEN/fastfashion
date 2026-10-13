import 'package:fastfashion/data/app_backend.dart';
import 'package:fastfashion/features/auth/auth_controller.dart';
import 'package:fastfashion/features/auth/login_screen.dart';
import 'package:fastfashion/features/auth/signup_screen.dart';
import 'package:fastfashion/features/auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../helpers/harness.dart';

void main() {
  late AppBackend backend;
  late AuthController auth;

  setUp(() async {
    backend = await AppBackend.inMemory();
    auth = AuthController(backend.auth);
  });

  tearDown(() => auth.dispose());

  List<SingleChildWidget> providers() => [
    ChangeNotifierProvider<AuthController>.value(value: auth),
  ];

  testWidgets('Bienvenida muestra la propuesta y navega a crear cuenta', (
    tester,
  ) async {
    await pumpScreen(tester, const WelcomeScreen());
    expect(find.text('Deja de pensar qué ponerte.'), findsOneWidget);

    await tester.ensureVisible(find.text('Crear mi clóset'));
    await tester.tap(find.text('Crear mi clóset'));
    await tester.pumpAndSettle();
    expect(find.text('ruta:/signup'), findsOneWidget);
  });

  testWidgets('Bienvenida lleva a iniciar sesión', (tester) async {
    await pumpScreen(tester, const WelcomeScreen());
    await tester.ensureVisible(find.text('Ya tengo cuenta'));
    await tester.tap(find.text('Ya tengo cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('ruta:/login'), findsOneWidget);
  });

  testWidgets('Login valida campos vacíos', (tester) async {
    await pumpScreen(tester, const LoginScreen(), providers: providers());
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.text('Escribe tu correo.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
    expect(auth.isSignedIn, isFalse);
  });

  testWidgets('Login con credenciales malas muestra el error', (tester) async {
    await pumpScreen(tester, const LoginScreen(), providers: providers());
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'nadie@correo.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secreto123');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
    expect(auth.isSignedIn, isFalse);
  });

  testWidgets('Login con la cuenta demo inicia sesión', (tester) async {
    await pumpScreen(tester, const LoginScreen(), providers: providers());
    await tester.tap(find.text('Entrar con la cuenta demo'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isTrue);
    expect(auth.user!.firstName, 'Ana');
  });

  testWidgets('Registro crea la cuenta e inicia sesión', (tester) async {
    await pumpScreen(tester, const SignUpScreen(), providers: providers());
    await tester.enterText(find.byType(TextFormField).at(0), 'Luis Pérez');
    await tester.enterText(find.byType(TextFormField).at(1), 'luis@correo.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'clave-segura');
    await tester.tap(find.text('Crear mi clóset'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isTrue);
    expect(auth.user!.displayName, 'Luis Pérez');
  });

  testWidgets('Registro rechaza contraseñas cortas', (tester) async {
    await pumpScreen(tester, const SignUpScreen(), providers: providers());
    await tester.enterText(find.byType(TextFormField).at(0), 'Luis');
    await tester.enterText(find.byType(TextFormField).at(1), 'luis@correo.com');
    await tester.enterText(find.byType(TextFormField).at(2), '123');
    await tester.tap(find.text('Crear mi clóset'));
    await tester.pump();
    expect(find.text('Usa al menos 6 caracteres.'), findsOneWidget);
    expect(auth.isSignedIn, isFalse);
  });

  for (final size in kPhoneSizes) {
    for (final scale in const [1.0, 1.4]) {
      testWidgets(
        'pantallas de acceso sin overflow ${size.width.toInt()}×${size.height.toInt()} ×$scale',
        (tester) async {
          for (final screen in const [
            WelcomeScreen(),
            LoginScreen(),
            SignUpScreen(),
          ]) {
            await pumpScreen(
              tester,
              screen,
              providers: providers(),
              size: size,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
}
