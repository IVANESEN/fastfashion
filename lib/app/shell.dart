import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/ff_bottom_nav.dart';
import 'routes.dart';

/// Marco de las cuatro pestañas con la barra inferior del diseño.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _items = <FfNavItem>[
    FfNavItem(
      label: 'Hoy',
      icon: Icons.wb_sunny_outlined,
      activeIcon: Icons.wb_sunny_rounded,
    ),
    FfNavItem(
      label: 'Clóset',
      icon: Icons.checkroom_outlined,
      activeIcon: Icons.checkroom_rounded,
    ),
    FfNavItem(
      label: 'Asistente',
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome_rounded,
    ),
    FfNavItem(
      label: 'Alertas',
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Con el teclado abierto (chat, búsqueda) la barra solo estorba.
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: keyboardOpen
          ? null
          : FfBottomNav(
              items: _items,
              currentIndex: navigationShell.currentIndex,
              onSelect: (i) => navigationShell.goBranch(
                i,
                // Volver a tocar la pestaña activa regresa a su raíz.
                initialLocation: i == navigationShell.currentIndex,
              ),
              onAdd: () => context.push(AppRoutes.addGarment),
            ),
    );
  }
}
