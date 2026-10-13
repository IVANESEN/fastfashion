import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/color_dot.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ff_chip.dart';
import '../../core/widgets/ff_icon_button.dart';
import '../../domain/entities/garment_category.dart';
import '../../domain/entities/garment_style.dart';
import 'closet_controller.dart';
import 'garment_card.dart';

/// 03 · Mi clóset: búsqueda, filtros por categoría/estilo/color y cuadrícula.
class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  final _search = TextEditingController();
  late final ClosetController _closet = context.read<ClosetController>();

  @override
  void initState() {
    super.initState();
    _search.text = _closet.query;
    _closet.addListener(_syncSearch);
  }

  /// Si los filtros se limpian desde otro lugar, vacía el cuadro de búsqueda.
  void _syncSearch() {
    if (_closet.query != _search.text) _search.text = _closet.query;
  }

  @override
  void dispose() {
    _closet.removeListener(_syncSearch);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closet = context.watch<ClosetController>();
    final pad = context.pagePadding;
    final items = closet.filtered;
    final total = closet.garments.length;

    final header = <Widget>[
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: const Text('Mi clóset', style: AppText.h1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              closet.hasFilters && total > 0
                  ? '${items.length} de $total prendas'
                  : '$total ${total == 1 ? 'prenda' : 'prendas'}',
              style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _SearchField(
        controller: _search,
        onChanged: closet.setQuery,
        onClear: () => closet.setQuery(''),
      ),
      const SizedBox(height: 14),
      _HorizontalChips(
        children: [
          FfChip(
            label: 'Todo',
            selected: closet.category == null,
            onTap: () => closet.setCategory(null),
          ),
          for (final c in GarmentCategory.values)
            FfChip(
              label: c.plural,
              selected: closet.category == c,
              onTap: () => closet.setCategory(c),
            ),
        ],
      ),
      const SizedBox(height: 10),
      _HorizontalChips(
        children: [
          FfChip(
            label: 'Todos',
            outlined: true,
            height: 36,
            selected: closet.style == null,
            onTap: () => closet.setStyle(null),
          ),
          for (final s in GarmentStyle.values)
            FfChip(
              label: s.label,
              outlined: true,
              height: 36,
              selected: closet.style == s,
              onTap: () => closet.setStyle(s),
            ),
        ],
      ),
      if (closet.availableColors.isNotEmpty) ...[
        const SizedBox(height: 14),
        _HorizontalChips(
          spacing: 6,
          children: [
            for (final c in closet.availableColors)
              ColorDot(
                color: c,
                selected: closet.colorName == c.name,
                onTap: () => closet.toggleColor(c.name),
              ),
          ],
        ),
      ],
      const SizedBox(height: 16),
    ];

    final Widget body;
    if (!closet.loaded && closet.loading) {
      body = const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (closet.error != null && total == 0) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'No pudimos cargar tu clóset',
          message: closet.error!,
          actionLabel: 'Reintentar',
          onAction: closet.load,
        ),
      );
    } else if (total == 0) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.checkroom_outlined,
          title: 'Tu clóset está vacío',
          message:
              'Sube tu primera prenda con una foto y empezamos a armar '
              'outfits con lo que tienes.',
          actionLabel: 'Agregar mi primera prenda',
          onAction: () => context.push(AppRoutes.addGarment),
          secondaryLabel: 'Cargar prendas de ejemplo',
          onSecondary: () async {
            final n = await closet.addSamples();
            if (!context.mounted || n == 0) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Agregamos $n prendas de ejemplo.')),
            );
          },
        ),
      );
    } else if (items.isEmpty) {
      body = SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Sin resultados',
          message: 'Ninguna prenda coincide con esos filtros.',
          actionLabel: 'Quitar filtros',
          onAction: closet.clearFilters,
        ),
      );
    } else {
      body = SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final cols = context.closetColumns(width);
          const gap = 12.0;
          final tile = (width - gap * (cols - 1)) / cols;
          final scale = MediaQuery.textScalerOf(context)
              .scale(1)
              .clamp(1.0, 1.6);
          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: gap,
              crossAxisSpacing: gap,
              mainAxisExtent: tile * 0.92 + 64 * scale,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final g = items[i];
              return GarmentCard(
                garment: g,
                alt: (i ~/ cols + i % cols).isOdd,
                onTap: () => context.push(AppRoutes.garment(g.id)),
              );
            }, childCount: items.length),
          );
        },
      );
    }

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: closet.load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: pad),
              sliver: SliverList.list(children: header),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
              sliver: body,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppText.body,
      decoration: InputDecoration(
        hintText: 'Busca por color, prenda o estilo',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.wine),
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? const SizedBox.shrink()
              : FfIconButton(
                  icon: Icons.close_rounded,
                  label: 'Borrar búsqueda',
                  background: Colors.transparent,
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _HorizontalChips extends StatelessWidget {
  const _HorizontalChips({required this.children, this.spacing = 8});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            children[i],
          ],
        ],
      ),
    );
  }
}
