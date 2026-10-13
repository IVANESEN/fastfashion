import 'dart:convert';
import 'dart:typed_data';

import 'package:fastfashion/domain/entities/garment_category.dart';
import 'package:fastfashion/domain/entities/garment_color.dart';
import 'package:fastfashion/domain/services/color_detector.dart';
import 'package:fastfashion/features/closet/add_garment_screen.dart';
import 'package:fastfashion/features/closet/closet_screen.dart';
import 'package:fastfashion/features/closet/garment_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fakes.dart';
import '../helpers/harness.dart';

/// PNG válido de 1×1 px.
final Uint8List _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  group('ClosetController', () {
    test('filtra por categoría, estilo, color y texto', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      final c = app.closet;
      final total = c.garments.length;
      expect(total, greaterThanOrEqualTo(10));

      c.setCategory(GarmentCategory.shoes);
      expect(
        c.filtered.every((g) => g.category == GarmentCategory.shoes),
        isTrue,
      );

      c.clearFilters();
      c.setQuery('azul');
      expect(c.filtered, isNotEmpty);
      expect(
        c.filtered.every(
          (g) =>
              g.color.name.contains('Azul') ||
              g.name.toLowerCase().contains('azul'),
        ),
        isTrue,
      );

      c.clearFilters();
      c.setQuery('CAMISA oxfórd'); // sin acentos ni mayúsculas
      expect(c.filtered.map((g) => g.name), contains('Camisa oxford azul'));

      c.clearFilters();
      c.toggleColor('Negro');
      expect(c.filtered.every((g) => g.color.name == 'Negro'), isTrue);
      c.toggleColor('Negro');
      expect(c.filtered.length, total);
    });

    test('al cerrar sesión se vacía el clóset', () async {
      final app = await TestApp.demo();
      addTearDown(app.dispose);
      expect(app.closet.garments, isNotEmpty);
      await app.auth.signOut();
      await pumpEventQueue();
      expect(app.closet.garments, isEmpty);
    });
  });

  testWidgets('Clóset lista prendas y filtra por categoría', (tester) async {
    final app = await TestApp.demo();
    addTearDown(app.dispose);
    await pumpScreen(
      tester,
      const Scaffold(body: ClosetScreen()),
      providers: app.providers,
    );
    await tester.pump();

    expect(find.text('Mi clóset'), findsOneWidget);
    expect(find.text('${app.closet.garments.length} prendas'), findsOneWidget);

    await tester.ensureVisible(find.text('Zapatos').first);
    await tester.tap(find.text('Zapatos').first);
    await tester.pump();
    final shoes = app.closet.garments
        .where((g) => g.category == GarmentCategory.shoes)
        .length;
    expect(app.closet.filtered.length, shoes);
    expect(find.text('Tenis blancos'), findsOneWidget);
    expect(find.text('Camisa oxford azul'), findsNothing);
  });

  testWidgets('Clóset sin resultados ofrece quitar filtros', (tester) async {
    final app = await TestApp.demo();
    addTearDown(app.dispose);
    await pumpScreen(
      tester,
      const Scaffold(body: ClosetScreen()),
      providers: app.providers,
    );
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.text('Sin resultados'), findsOneWidget);
    await tester.tap(find.text('Quitar filtros'));
    await tester.pump();
    expect(find.text('Sin resultados'), findsNothing);
  });

  testWidgets('Clóset vacío permite cargar prendas de ejemplo', (tester) async {
    final app = await TestApp.empty();
    addTearDown(app.dispose);
    await pumpScreen(
      tester,
      const Scaffold(body: ClosetScreen()),
      providers: app.providers,
    );
    expect(find.text('Tu clóset está vacío'), findsOneWidget);

    await tester.tap(find.text('Cargar prendas de ejemplo'));
    await tester.pumpAndSettle();
    expect(app.closet.garments, isNotEmpty);
    expect(find.text('Tu clóset está vacío'), findsNothing);
  });

  testWidgets('Agregar prenda: foto → color detectado → guardar', (
    tester,
  ) async {
    final app = await TestApp.empty();
    addTearDown(app.dispose);
    app.picker.result = _tinyPng;

    await pumpScreen(
      tester,
      AddGarmentScreen(
        colorDetector: (_) async =>
            const ColorDetection(GarmentPalette.green, 0.9),
      ),
      providers: app.providers,
    );

    // Elegir foto desde la galería.
    await tester.tap(find.bySemanticsLabel('Tomar o elegir foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();

    expect(find.text('Color detectado: verde'), findsOneWidget);
    expect(find.text('Verde'), findsOneWidget); // color principal

    await tester.tap(find.text('Pantalón'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'Pantalón verde');

    await tester.tap(find.text('Guardar en mi clóset'));
    await tester.pumpAndSettle();

    expect(app.closet.garments.length, 1);
    final saved = app.closet.garments.single;
    expect(saved.name, 'Pantalón verde');
    expect(saved.category, GarmentCategory.bottom);
    expect(saved.hasPhoto, isTrue);
    expect(find.text('ruta:/closet'), findsOneWidget);
  });

  testWidgets('Agregar prenda: nombre vacío no guarda', (tester) async {
    final app = await TestApp.empty();
    addTearDown(app.dispose);
    await pumpScreen(
      tester,
      const AddGarmentScreen(),
      providers: app.providers,
    );
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Guardar en mi clóset'));
    await tester.pump();
    expect(find.text('Ponle un nombre a la prenda.'), findsOneWidget);
    expect(app.closet.garments, isEmpty);
  });

  testWidgets('Detalle: editar nombre y guardar', (tester) async {
    final app = await TestApp.demo();
    addTearDown(app.dispose);
    final g = app.closet.garments.first;
    await pumpScreen(
      tester,
      GarmentDetailScreen(garmentId: g.id),
      providers: app.providers,
    );

    expect(find.text('Detalle de prenda'), findsOneWidget);
    final saveButton = find.text('Guardar cambios');
    await tester.enterText(find.byType(TextField), 'Nombre nuevo');
    await tester.pump();
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(app.closet.byId(g.id)!.name, 'Nombre nuevo');
  });

  testWidgets('Detalle: eliminar pide confirmación', (tester) async {
    final app = await TestApp.demo();
    addTearDown(app.dispose);
    final g = app.closet.garments.first;
    final before = app.closet.garments.length;
    await pumpScreen(
      tester,
      GarmentDetailScreen(garmentId: g.id),
      providers: app.providers,
    );

    await tester.tap(find.bySemanticsLabel('Eliminar prenda'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar esta prenda?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(app.closet.garments.length, before);

    await tester.tap(find.bySemanticsLabel('Eliminar prenda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(app.closet.garments.length, before - 1);
  });

  for (final size in kPhoneSizes) {
    for (final scale in const [1.0, 1.4]) {
      testWidgets(
        'clóset sin overflow ${size.width.toInt()}×${size.height.toInt()} ×$scale',
        (tester) async {
          final app = await TestApp.demo();
          addTearDown(app.dispose);
          for (final screen in <Widget>[
            const Scaffold(body: ClosetScreen()),
            const AddGarmentScreen(),
            GarmentDetailScreen(garmentId: app.closet.garments.first.id),
          ]) {
            await pumpScreen(
              tester,
              screen,
              providers: app.providers,
              size: size,
              textScale: scale,
            );
            await tester.pump();
            expect(
              tester.takeException(),
              isNull,
              reason: '${screen.runtimeType}',
            );
          }
        },
      );
    }
  }
}
