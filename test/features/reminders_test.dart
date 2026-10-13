import 'package:fastfashion/domain/entities/garment.dart';
import 'package:fastfashion/domain/entities/garment_category.dart';
import 'package:fastfashion/domain/entities/garment_style.dart';
import 'package:fastfashion/domain/entities/outfit.dart';
import 'package:fastfashion/domain/entities/reminder_settings.dart';
import 'package:fastfashion/domain/services/smart_alerts.dart';
import 'package:fastfashion/features/reminders/reminders_screen.dart';
import 'package:fastfashion/features/today/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/harness.dart';

Widget _screen() => const Scaffold(body: RemindersScreen());

void main() {
  group('RemindersController', () {
    test('valores de fábrica: 6:30 a. m., lunes a viernes', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      final s = app.reminders.settings;
      expect((s.hour, s.minute), (6, 30));
      expect(s.days, [true, true, true, true, true, false, false]);
      expect(s.dailyOutfit, isTrue);
      expect(s.smartAlerts, isFalse);
    });

    test('cambios se guardan y sobreviven a recargar', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await app.reminders.setTime(7, 15);
      await app.reminders.toggleDay(5); // sábado
      await app.reminders.setSmartAlerts(true);

      await app.reminders.load();
      final s = app.reminders.settings;
      expect((s.hour, s.minute), (7, 15));
      expect(s.days[5], isTrue);
      expect(s.smartAlerts, isTrue);
    });

    test(
      'próximo aviso salta al lunes desde el viernes por la mañana',
      () async {
        final app = await TestApp.demo();
        addTearDown(app.dispose);
        // kTestNow = viernes 9 oct 8:00 → ya pasó 6:30 → lunes 12 oct.
        expect(app.reminders.nextFire, DateTime(2026, 10, 12, 6, 30));
        await app.reminders.setDailyOutfit(false);
        expect(app.reminders.nextFire, isNull);
      },
    );

    test('takeDue avisa una vez por día y respeta días y ventana', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      final r = app.reminders;
      expect(r.takeDue(DateTime(2026, 10, 9, 6, 29)), isFalse); // antes
      expect(r.takeDue(DateTime(2026, 10, 9, 6, 30)), isTrue); // a la hora
      expect(r.takeDue(DateTime(2026, 10, 9, 6, 31)), isFalse); // ya avisó
      expect(r.takeDue(DateTime(2026, 10, 10, 6, 30)), isFalse); // sábado off
      expect(r.takeDue(DateTime(2026, 10, 12, 12, 0)), isFalse); // muy tarde
      expect(r.takeDue(DateTime(2026, 10, 12, 8, 0)), isTrue); // abre tarde
    });
  });

  group('SmartAlerts', () {
    test('lluvia + mocasines → aviso de clima', () async {
      final app = await TestApp.demo(weather: FakeWeatherRepository.rainy());
      addTearDown(app.dispose);
      final closet = app.closet.garments;
      final loafers = closet.firstWhere((g) => g.name.contains('Mocasines'));
      // Propuesta con mocasines (cuero) bajo lluvia.
      final withLoafers = _swapShoes(app.today.current!, loafers);
      final alerts = SmartAlerts.evaluate(
        now: kTestNow,
        settings: const ReminderSettings(userId: 'u'),
        weather: FakeWeatherRepository.rainy(),
        chosen: withLoafers,
        closet: closet,
      );
      expect(alerts.single.kind, AlertKind.weather);
      expect(alerts.single.message, contains('4 p.m.'));
      expect(alerts.single.message, contains('mocasines café'));
    });

    test('desactivar el interruptor silencia el aviso', () async {
      final app = await TestApp.demo(weather: FakeWeatherRepository.rainy());
      addTearDown(app.dispose);
      final loafers = app.closet.garments.firstWhere(
        (g) => g.name.contains('Mocasines'),
      );
      final alerts = SmartAlerts.evaluate(
        now: kTestNow,
        settings: const ReminderSettings(userId: 'u', weatherChange: false),
        weather: FakeWeatherRepository.rainy(),
        chosen: _swapShoes(app.today.current!, loafers),
        closet: app.closet.garments,
      );
      expect(alerts, isEmpty);
    });

    test('tarde + clóset deportivo → sugiere look deportivo', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      final chosen = app.today.current!;
      expect(chosen.style, isNot(GarmentStyle.sporty));
      final evening = DateTime(2026, 10, 9, 17);
      final alerts = SmartAlerts.evaluate(
        now: evening,
        settings: const ReminderSettings(userId: 'u', smartAlerts: true),
        weather: FakeWeatherRepository.mild(),
        chosen: chosen,
        closet: app.closet.garments,
      );
      expect(alerts.single.kind, AlertKind.smart);
      // De mañana no avisa.
      final morning = SmartAlerts.evaluate(
        now: kTestNow,
        settings: const ReminderSettings(userId: 'u', smartAlerts: true),
        weather: FakeWeatherRepository.mild(),
        chosen: chosen,
        closet: app.closet.garments,
      );
      expect(morning, isEmpty);
    });

    test('sin outfit elegido no hay avisos', () {
      final alerts = SmartAlerts.evaluate(
        now: kTestNow,
        settings: const ReminderSettings(userId: 'u', smartAlerts: true),
        weather: FakeWeatherRepository.rainy(),
        chosen: null,
        closet: const [],
      );
      expect(alerts, isEmpty);
    });
  });

  group('RemindersScreen', () {
    testWidgets('muestra hora, días y próximo aviso', (tester) async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();

      expect(find.text('Recordatorios'), findsOneWidget);
      expect(find.text('6:30'), findsOneWidget);
      expect(find.text('a.m.'), findsOneWidget);
      expect(find.textContaining('lunes 12 oct, 6:30 a.m.'), findsOneWidget);
    });

    testWidgets('interruptores y días persisten', (tester) async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Avisos inteligentes'));
      await tester.pumpAndSettle();
      expect(app.reminders.settings.smartAlerts, isTrue);

      await tester.tap(find.bySemanticsLabel('Sábado'));
      await tester.pumpAndSettle();
      expect(app.reminders.settings.days[5], isTrue);
    });

    testWidgets('Editar abre el selector de hora y guarda', (tester) async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();

      await tester.tap(find.bySemanticsLabel('Editar hora'));
      await tester.pumpAndSettle();
      expect(find.text('Hora de tu outfit'), findsOneWidget);
      await tester.tap(find.text('ACEPTAR'));
      await tester.pumpAndSettle();
      expect(app.reminders.settings.hour, 6);
    });

    testWidgets('sin días activos explica cómo reactivar', (tester) async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await app.reminders.setDailyOutfit(false);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();
      expect(
        find.textContaining('No tienes avisos programados'),
        findsOneWidget,
      );
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

  group('Aviso en la pantalla Hoy', () {
    testWidgets('lluvia con calzado no apto muestra el banner', (tester) async {
      final app = await TestApp.demo(weather: FakeWeatherRepository.rainy());
      addTearDown(app.dispose);
      await app.reminders.setSmartAlerts(false);
      // Elegimos un outfit con mocasines.
      final loafers = app.closet.garments.firstWhere(
        (g) => g.name.contains('Mocasines'),
      );
      await app.today.adopt(_swapShoes(app.today.current!, loafers));
      await app.today.useCurrent();

      await pumpScreen(
        tester,
        Scaffold(body: TodayScreen(clock: () => kTestNow)),
        providers: app.providers,
      );
      await tester.pump();
      expect(find.textContaining('Va a llover a las 4 p.m.'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Cerrar aviso'));
      await tester.pump();
      expect(find.textContaining('Va a llover'), findsNothing);
    });
  });
}

OutfitProposal _swapShoes(OutfitProposal p, Garment shoes) {
  assert(shoes.category == GarmentCategory.shoes);
  return OutfitProposal(
    top: p.top,
    bottom: p.bottom,
    shoes: shoes,
    jacket: p.jacket,
    title: p.title,
    occasion: p.occasion,
    style: p.style,
  );
}
