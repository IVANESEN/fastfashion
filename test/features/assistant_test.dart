import 'package:fastfashion/domain/entities/garment_category.dart';
import 'package:fastfashion/features/assistant/assistant_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/harness.dart';

Widget _screen() => const Scaffold(body: AssistantScreen());

void main() {
  group('AssistantController', () {
    test('responde con combinaciones del clóset', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      final a = app.assistant;
      expect(a.messages.single.fromUser, isFalse);

      await a.send('Hoy quiero usar una camisa azul con un pantalón blanco');
      expect(a.messages.length, 3);
      final reply = a.messages.last;
      expect(reply.options, isNotEmpty);
      expect(reply.options.first.top.color.name, 'Azul');
      expect(reply.options.first.bottom.color.name, 'Blanco');
    });

    test('mantiene el contexto en el siguiente mensaje', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await app.assistant.send('camisa azul con pantalón blanco');
      await app.assistant.send('Algo más formal');
      final reply = app.assistant.messages.last;
      expect(reply.options.first.top.color.name, 'Azul');
    });

    test('usar una opción la fija como outfit de hoy', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await app.assistant.send('algo casual');
      final pick = app.assistant.messages.last.options.first;
      expect(await app.assistant.use(pick), isTrue);
      expect(app.today.usedToday, isTrue);
      expect(app.today.current!.signature, pick.signature);
    });

    test('ignora mensajes vacíos y reset reinicia', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await app.assistant.send('   ');
      expect(app.assistant.messages.length, 1);
      await app.assistant.send('hola');
      expect(app.assistant.messages.length, 3);
      app.assistant.reset();
      expect(app.assistant.messages.length, 1);
    });

    test('con clóset vacío explica qué falta', () async {
      final app = await TestApp.empty();
      addTearDown(app.dispose);
      await app.assistant.send('un outfit para hoy');
      final reply = app.assistant.messages.last;
      expect(reply.options, isEmpty);
      expect(reply.text, contains('camisa'));
    });
  });

  group('AssistantScreen', () {
    testWidgets('conversación completa con tarjetas y botón Usar', (
      tester,
    ) async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();

      expect(find.text('Asistente'), findsOneWidget);
      expect(find.text('Solo busca en tu clóset'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        'camisa azul con pantalón blanco',
      );
      await tester.tap(find.bySemanticsLabel('Enviar'));
      await tester.pumpAndSettle();

      expect(find.text('camisa azul con pantalón blanco'), findsOneWidget);
      expect(find.text('Opción A'), findsOneWidget);
      expect(find.text('Sugerida'), findsOneWidget);

      await tester.ensureVisible(find.text('Usar').first);
      await tester.pump();
      await tester.tap(find.text('Usar').first);
      await tester.pumpAndSettle();
      expect(app.today.usedToday, isTrue);
      expect(find.text('ruta:/today'), findsOneWidget);
    });

    testWidgets('los atajos envían el mensaje', (tester) async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      await pumpScreen(tester, _screen(), providers: app.providers);
      await tester.pump();

      await tester.ensureVisible(find.text('Para la lluvia'));
      await tester.pump();
      await tester.tap(find.text('Para la lluvia'));
      await tester.pumpAndSettle();
      final texts = app.assistant.messages.map((m) => m.text);
      expect(texts, contains('Para la lluvia'));
      final reply = app.assistant.messages.last;
      expect(reply.options.first.shoes?.category, GarmentCategory.shoes);
    });

    for (final size in kPhoneSizes) {
      for (final scale in const [1.0, 1.4]) {
        testWidgets(
          'sin overflow ${size.width.toInt()}×${size.height.toInt()} ×$scale',
          (tester) async {
            final app = await TestApp.demo();
            addTearDown(app.dispose);
            await app.assistant.send('camisa azul con pantalón blanco');
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
