import 'package:fastfashion/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/harness.dart';

void main() {
  testWidgets('muestra datos de la cuenta y la base local', (tester) async {
    final app = await TestApp.demo();
    addTearDown(app.dispose);
    await pumpScreen(tester, const ProfileScreen(), providers: app.providers);
    await tester.pump();

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Ana Martínez'), findsWidgets);
    expect(find.text('ana@fastfashion.app'), findsOneWidget);
    expect(find.text('Base de datos local (demo)'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('FastFashion 1.0.0'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('FastFashion 1.0.0'), findsOneWidget);
  });

  testWidgets('editar el nombre lo guarda', (tester) async {
    final app = await TestApp.demo();
    addTearDown(app.dispose);
    await pumpScreen(tester, const ProfileScreen(), providers: app.providers);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Ana María');
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar nombre'));
    await tester.pump();
    await tester.tap(find.text('Guardar nombre'));
    await tester.pumpAndSettle();
    expect(app.auth.user!.displayName, 'Ana María');
  });

  testWidgets('nombre vacío muestra el error', (tester) async {
    final app = await TestApp.demo();
    addTearDown(app.dispose);
    await pumpScreen(tester, const ProfileScreen(), providers: app.providers);
    await tester.pump();
    await tester.enterText(find.byType(TextField), ' ');
    await tester.pump();
    await tester.ensureVisible(find.text('Guardar nombre'));
    await tester.pump();
    await tester.tap(find.text('Guardar nombre'));
    await tester.pump();
    expect(find.text('Dinos cómo te llamas.'), findsOneWidget);
  });

  testWidgets('cambiar de ciudad actualiza el perfil y el clima', (
    tester,
  ) async {
    final app = await TestApp.demo();
    addTearDown(app.dispose);
    await pumpScreen(tester, const ProfileScreen(), providers: app.providers);
    await tester.pump();
    final callsBefore = app.weatherRepo.calls;

    await tester.ensureVisible(find.text('Ciudad').last);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.location_on_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Santa Ana'));
    await tester.pumpAndSettle();

    expect(app.auth.user!.city.name, 'Santa Ana');
    expect(app.weather.city.name, 'Santa Ana');
    expect(app.weatherRepo.calls, greaterThan(callsBefore));
  });

  testWidgets('cerrar sesión pide confirmación', (tester) async {
    final app = await TestApp.demo();
    addTearDown(app.dispose);
    await pumpScreen(tester, const ProfileScreen(), providers: app.providers);
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(app.auth.isSignedIn, isTrue);

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión').last);
    await tester.pumpAndSettle();
    expect(app.auth.isSignedIn, isFalse);
  });

  for (final size in kPhoneSizes) {
    for (final scale in const [1.0, 1.4]) {
      testWidgets(
        'sin overflow ${size.width.toInt()}×${size.height.toInt()} ×$scale',
        (tester) async {
          final app = await TestApp.demo();
          addTearDown(app.dispose);
          await pumpScreen(
            tester,
            const ProfileScreen(),
            providers: app.providers,
            size: size,
            textScale: scale,
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
