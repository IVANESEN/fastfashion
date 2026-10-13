import 'package:fastfashion/app/app.dart';
import 'package:fastfashion/core/widgets/ff_icon_button.dart';
import 'package:fastfashion/data/app_backend.dart';
import 'package:fastfashion/domain/entities/demo_account.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';

Future<AppBackend> _backend({bool signedIn = false}) async {
  final backend = await AppBackend.inMemory(
    weather: FakeWeatherRepository(FakeWeatherRepository.mild()),
  );
  if (signedIn) {
    await backend.auth.signIn(
      email: DemoAccount.email,
      password: DemoAccount.password,
    );
  }
  return backend;
}

Future<void> _launch(
  WidgetTester tester,
  AppBackend backend, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    FastFashionApp(backend: backend, photoPicker: FakePhotoPicker()),
  );
  await tester.pumpAndSettle();
}

/// Desmonta la app para cancelar temporizadores (ReminderWatcher).
Future<void> _close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  testWidgets('arranque sin sesión: bienvenida → login demo → Hoy', (
    tester,
  ) async {
    final backend = await _backend();
    await _launch(tester, backend);

    expect(find.text('Deja de pensar qué ponerte.'), findsOneWidget);

    await tester.ensureVisible(find.text('Ya tengo cuenta'));
    await tester.pump();
    await tester.tap(find.text('Ya tengo cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Qué bueno verte de nuevo'), findsOneWidget);

    await tester.ensureVisible(find.text('Entrar con la cuenta demo'));
    await tester.pump();
    await tester.tap(find.text('Entrar con la cuenta demo'));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Clóset'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('con sesión guardada abre directo en Hoy', (tester) async {
    final backend = await _backend(signedIn: true);
    await _launch(tester, backend);
    expect(find.text('Hola, Ana'), findsOneWidget);
    expect(find.text('Deja de pensar qué ponerte.'), findsNothing);
    await _close(tester);
  });

  testWidgets('la barra inferior navega por las 4 pestañas', (tester) async {
    final backend = await _backend(signedIn: true);
    await _launch(tester, backend);

    await tester.tap(find.text('Clóset'));
    await tester.pumpAndSettle();
    expect(find.text('Mi clóset'), findsOneWidget);

    await tester.tap(find.text('Asistente'));
    await tester.pumpAndSettle();
    expect(find.text('Solo busca en tu clóset'), findsOneWidget);

    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();
    expect(find.text('Recordatorios'), findsOneWidget);

    await tester.tap(find.text('Hoy'));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('el botón + abre Agregar prenda sin barra inferior', (
    tester,
  ) async {
    final backend = await _backend(signedIn: true);
    await _launch(tester, backend);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nueva prenda'), findsOneWidget);
    expect(find.text('Asistente'), findsNothing); // sin barra inferior

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Hola, Ana'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('tocar una prenda abre su detalle', (tester) async {
    final backend = await _backend(signedIn: true);
    await _launch(tester, backend);

    await tester.tap(find.text('Clóset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camisa oxford azul'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de prenda'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('perfil → cerrar sesión regresa a la bienvenida', (tester) async {
    final backend = await _backend(signedIn: true);
    await _launch(tester, backend);

    await tester.tap(find.byType(InitialAvatar));
    await tester.pumpAndSettle();
    expect(find.text('Perfil'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();

    expect(find.text('Deja de pensar qué ponerte.'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('rutas privadas sin sesión redirigen a la bienvenida', (
    tester,
  ) async {
    final backend = await _backend();
    await _launch(tester, backend);
    // Sin sesión no hay barra inferior ni pantallas privadas.
    expect(find.text('Alertas'), findsNothing);
    expect(find.text('Hola, Ana'), findsNothing);
    await _close(tester);
  });

  for (final size in const [Size(320, 568), Size(430, 932), Size(1280, 800)]) {
    testWidgets(
      'app completa sin errores en ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        final backend = await _backend(signedIn: true);
        await _launch(tester, backend, size: size);
        expect(tester.takeException(), isNull);
        for (final tab in const ['Clóset', 'Asistente', 'Alertas', 'Hoy']) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tab);
        }
        await _close(tester);
      },
    );
  }
}
