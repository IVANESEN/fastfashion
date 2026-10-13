import 'package:fastfashion/core/widgets/ff_icon_button.dart';
import 'package:fastfashion/domain/entities/garment_category.dart';
import 'package:fastfashion/domain/entities/garment_style.dart';
import 'package:fastfashion/domain/entities/occasion.dart';
import 'package:fastfashion/features/today/today_controller.dart';
import 'package:fastfashion/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/harness.dart';

Widget _screen() => Scaffold(body: TodayScreen(clock: () => kTestNow));

void main() {
  group('TodayController', () {
    test('genera una propuesta completa y rápida', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      expect(app.today.status, TodayStatus.ready);
      final o = app.today.current!;
      expect(o.top.category, GarmentCategory.top);
      expect(o.bottom.category, GarmentCategory.bottom);
      expect(app.today.generatedIn.inSeconds, lessThan(5));
      expect(app.today.optionCount, greaterThan(1));
    });

    test('"Otra opción" cambia la propuesta y recicla al agotar', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      final first = app.today.current!.signature;
      app.today.next();
      expect(app.today.current!.signature, isNot(first));
      for (var i = 0; i < 12; i++) {
        app.today.next();
      }
      expect(app.today.current, isNotNull);
    });

    test('cambiar de ocasión ajusta el estilo', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      app.today.setOccasion(Occasion.work);
      expect(app.today.current!.style, GarmentStyle.formal);
      expect(app.today.current!.top.style, GarmentStyle.formal);
      app.today.setOccasion(Occasion.sport);
      expect(app.today.current!.top.style, GarmentStyle.sporty);
    });

    test('con lluvia propone calzado deportivo', () async {
      final app = await TestApp.demo(weather: FakeWeatherRepository.rainy());
      addTearDown(app.dispose);
      expect(app.today.current!.shoes!.style, GarmentStyle.sporty);
      expect(app.today.current!.title, 'Listo para la lluvia');
    });

    test('usar el outfit lo guarda y suma usos', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      final outfit = app.today.current!;
      expect(app.today.usedToday, isFalse);

      expect(await app.today.useCurrent(), isTrue);
      expect(app.today.usedToday, isTrue);
      for (final g in outfit.garments) {
        final fresh = app.closet.byId(g.id)!;
        expect(fresh.wearCount, 1);
        expect(fresh.lastWornAt, isNotNull);
      }
    });

    test('al reabrir la app recupera el outfit elegido hoy', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      final chosen = app.today.current!.signature;
      await app.today.useCurrent();

      final reopened = TodayController(
        closet: app.closet,
        weather: app.weather,
        outfits: app.backend.outfits,
        garments: app.backend.garments,
        auth: app.auth,
        clock: () => kTestNow,
      );
      addTearDown(reopened.dispose);
      await settle();
      expect(reopened.current!.signature, chosen);
      expect(reopened.usedToday, isTrue);
    });

    test('sin prendas pide agregar y se recupera con ejemplos', () async {
      final app = await TestApp.empty();
      addTearDown(app.dispose);
      expect(app.today.status, TodayStatus.needsGarments);
      await app.closet.addSamples();
      await settle();
      expect(app.today.status, TodayStatus.ready);
    });
  });

  group('TodayScreen', () {
    testWidgets('muestra saludo, clima y outfit', (tester) async {
      final app = await TestApp.demo(weather: FakeWeatherRepository.rainy());
      addTearDown(app.dispose);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();

      expect(find.text('VIERNES 9 DE OCTUBRE'), findsOneWidget);
      expect(find.text('Hola, Ana'), findsOneWidget);
      expect(find.text('San Salvador · 29°C'), findsOneWidget);
      expect(
        find.textContaining('Lluvia probable a las 4 p.m.'),
        findsOneWidget,
      );
      expect(find.text('Listo para la lluvia'), findsOneWidget);
      expect(find.text('Usar este outfit'), findsOneWidget);
    });

    testWidgets('"Usar este outfit" confirma y bloquea el botón', (
      tester,
    ) async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();

      await tester.ensureVisible(find.text('Usar este outfit'));
      await tester.pump();
      await tester.tap(find.text('Usar este outfit'));
      await tester.pumpAndSettle();
      expect(find.text('Outfit de hoy guardado'), findsOneWidget);
      expect(find.text('¡Listo! Este es tu outfit de hoy.'), findsOneWidget);
    });

    testWidgets('"Otra opción" cambia el contador de opciones', (tester) async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();
      final total = app.today.optionCount;
      expect(find.text('Opción 1 de $total'), findsOneWidget);

      await tester.ensureVisible(find.text('Otra opción'));
      await tester.pump();
      await tester.tap(find.text('Otra opción'));
      await tester.pump();
      expect(find.text('Opción 2 de $total'), findsOneWidget);
    });

    testWidgets('perfil: el avatar navega a /profile', (tester) async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();
      await tester.tap(find.byType(InitialAvatar));
      await tester.pumpAndSettle();
      expect(find.text('ruta:/profile'), findsOneWidget);
    });

    for (final size in kPhoneSizes) {
      for (final scale in const [1.0, 1.4]) {
        testWidgets(
          'sin overflow ${size.width.toInt()}×${size.height.toInt()} ×$scale',
          (tester) async {
            final app = await TestApp.demo(
              weather: FakeWeatherRepository.rainy(),
            );
            addTearDown(app.dispose);
            await pumpScreen(
              tester,
              _screen(),
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
  });
}
