import 'package:fastfashion/core/layout/responsive.dart';
import 'package:fastfashion/core/theme/app_theme.dart';
import 'package:fastfashion/core/widgets/brand_wordmark.dart';
import 'package:fastfashion/core/widgets/color_dot.dart';
import 'package:fastfashion/core/widgets/empty_state.dart';
import 'package:fastfashion/core/widgets/ff_bottom_nav.dart';
import 'package:fastfashion/core/widgets/ff_button.dart';
import 'package:fastfashion/core/widgets/ff_chip.dart';
import 'package:fastfashion/core/widgets/ff_switch.dart';
import 'package:fastfashion/core/widgets/garment_illustration.dart';
import 'package:fastfashion/domain/entities/garment_category.dart';
import 'package:fastfashion/domain/entities/garment_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  builder: (context, c) => AppFrame(child: c!),
  home: Scaffold(
    body: SafeArea(child: SingleChildScrollView(child: child)),
  ),
);

Future<void> _setSize(WidgetTester tester, double w, double h) async {
  tester.view.physicalSize = Size(w, h);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final size in const [
    Size(320, 568),
    Size(390, 844),
    Size(430, 932),
    Size(1280, 800),
  ]) {
    testWidgets(
      'componentes se renderizan sin overflow en ${size.width.toInt()}×${size.height.toInt()}',
      (tester) async {
        await _setSize(tester, size.width, size.height);
        await tester.pumpWidget(
          _host(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandWordmark(size: 40),
                  const FfButton(
                    label: 'Guardar en mi clóset',
                    onPressed: null,
                  ),
                  FfButton(
                    label: 'Otra opción',
                    onPressed: () {},
                    style: FfButtonStyle.outline,
                    icon: Icons.refresh,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in GarmentCategory.values)
                        FfChip(
                          label: c.plural,
                          selected: c == GarmentCategory.top,
                          onTap: () {},
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      for (final c in GarmentPalette.quickFilter)
                        ColorDot(
                          color: c,
                          selected: c == GarmentPalette.blue,
                          onTap: () {},
                        ),
                    ],
                  ),
                  for (final cat in GarmentCategory.values)
                    GarmentIllustration(
                      category: cat,
                      color: const Color(0xFF3B6FD8),
                      size: 80,
                    ),
                  const EmptyState(
                    icon: Icons.checkroom_outlined,
                    title: 'Tu clóset está vacío',
                    message: 'Agrega tu primera prenda para recibir outfits.',
                    actionLabel: 'Agregar prenda',
                  ),
                ],
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('FfSwitch alterna y expone estado semántico', (tester) async {
    var value = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => FfSwitch(
            value: value,
            semanticLabel: 'Outfit del día',
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FfSwitch));
    await tester.pump();
    expect(value, isTrue);
  });

  testWidgets('FfChip invoca onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(FfChip(label: 'Casual', selected: false, onTap: () => taps++)),
    );
    await tester.tap(find.text('Casual'));
    expect(taps, 1);
  });

  testWidgets('FfBottomNav notifica destino y botón agregar', (tester) async {
    int? selected;
    var added = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          bottomNavigationBar: FfBottomNav(
            currentIndex: 0,
            onSelect: (i) => selected = i,
            onAdd: () => added++,
            items: const [
              FfNavItem(
                label: 'Hoy',
                icon: Icons.wb_sunny_outlined,
                activeIcon: Icons.wb_sunny,
              ),
              FfNavItem(
                label: 'Clóset',
                icon: Icons.checkroom_outlined,
                activeIcon: Icons.checkroom,
              ),
              FfNavItem(
                label: 'Asistente',
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome,
              ),
              FfNavItem(
                label: 'Alertas',
                icon: Icons.notifications_none,
                activeIcon: Icons.notifications,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Asistente'));
    expect(selected, 2);
    await tester.tap(find.bySemanticsLabel('Agregar prenda'));
    expect(added, 1);
  });
}
