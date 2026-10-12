import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Destino de la barra inferior.
class FfNavItem {
  const FfNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Barra inferior del diseño: Hoy · Clóset · [+] · Asistente · Alertas.
///
/// [items] debe tener 4 elementos; el botón central de agregar se coloca
/// entre el segundo y el tercero.
class FfBottomNav extends StatelessWidget {
  const FfBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
    required this.onAdd,
    super.key,
  }) : assert(items.length == 4, 'La barra espera exactamente 4 destinos');

  final List<FfNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  static const _barHeight = 68.0;
  static const _fabSize = 56.0;
  static const _lift = 16.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    Widget item(int i) => Expanded(
      child: _NavButton(
        item: items[i],
        selected: i == currentIndex,
        onTap: () => onSelect(i),
      ),
    );

    return Semantics(
      container: true,
      label: 'Navegación principal',
      child: SizedBox(
        height: _barHeight + _lift + bottomInset,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _barHeight + bottomInset,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, bottomInset),
                  child: Row(
                    children: [
                      item(0),
                      item(1),
                      const Spacer(),
                      item(2),
                      item(3),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Agregar prenda',
                  excludeSemantics: true,
                  child: Material(
                    color: AppColors.primary,
                    elevation: 6,
                    shadowColor: AppColors.primary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onAdd,
                      child: const SizedBox.square(
                        dimension: _fabSize,
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final FfNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.wineMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.activeIcon : item.icon,
              size: 25,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Lato',
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
