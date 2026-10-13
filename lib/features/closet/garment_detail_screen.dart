import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/format/dates.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/ff_button.dart';
import '../../core/widgets/ff_icon_button.dart';
import '../../domain/entities/garment.dart';
import 'closet_controller.dart';
import 'garment_draft.dart';
import 'garment_form_widgets.dart';
import 'photo_picker.dart';

/// Detalle y edición de una prenda, con estadísticas de uso y eliminación.
class GarmentDetailScreen extends StatelessWidget {
  const GarmentDetailScreen({required this.garmentId, super.key});

  final String garmentId;

  @override
  Widget build(BuildContext context) {
    final closet = context.watch<ClosetController>();
    final garment = closet.byId(garmentId);

    if (garment == null) {
      return Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(4),
            child: FfIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'Volver al clóset',
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.closet),
            ),
          ),
        ),
        body: closet.loading || !closet.loaded
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No encontramos la prenda',
                message: 'Puede que ya la hayas eliminado.',
                actionLabel: 'Ir a mi clóset',
                onAction: () => context.go(AppRoutes.closet),
              ),
      );
    }
    // La clave por id evita reutilizar el borrador de otra prenda.
    return _DetailBody(key: ValueKey(garment.id), garment: garment);
  }
}

class _DetailBody extends StatefulWidget {
  const _DetailBody({required this.garment, super.key});

  final Garment garment;

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  late final GarmentDraft _draft = GarmentDraft(initial: widget.garment);
  bool _saving = false;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.closet);
    }
  }

  Future<void> _save() async {
    final name = _draft.name.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ponle un nombre a la prenda.')),
      );
      return;
    }
    setState(() => _saving = true);
    final closet = context.read<ClosetController>();
    final removedPhoto =
        widget.garment.hasPhoto &&
        _draft.photoBytes == null &&
        !_draft.hasPhoto;
    final updated = widget.garment.copyWith(
      name: name,
      category: _draft.category,
      style: _draft.style,
      color: _draft.color,
      clearImage: removedPhoto,
    );
    final saved = await closet.update(updated, imageBytes: _draft.photoBytes);
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(closet.error ?? 'No pudimos guardar los cambios.'),
        ),
      );
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Cambios guardados.')));
    _back();
  }

  Future<void> _delete() async {
    final closet = context.read<ClosetController>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar esta prenda?'),
        content: Text(
          '«${widget.garment.name}» saldrá de tu clóset y de las '
          'combinaciones sugeridas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await closet.delete(widget.garment);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Eliminaste «${widget.garment.name}».')),
      );
      _back();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(closet.error ?? 'No pudimos eliminarla.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final picker = context.read<PhotoPicker>();
    final horizontal = MediaQuery.sizeOf(context).width < 360 ? 16.0 : 20.0;
    final g = widget.garment;
    final now = DateTime.now();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 8),
              child: Row(
                children: [
                  FfIconButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'Volver al clóset',
                    onPressed: _back,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: const Text(
                        'Detalle de prenda',
                        style: AppText.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  FfIconButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Eliminar prenda',
                    foreground: AppColors.error,
                    onPressed: _delete,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _draft,
                builder: (context, _) => SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GarmentPhotoPanel(
                            draft: _draft,
                            onPickPhoto: () =>
                                pickPhotoInto(context, _draft, picker),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _Stat(
                                  label: 'Veces usada',
                                  value: '${g.wearCount}',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Stat(
                                  label: 'Último uso',
                                  value: g.lastWornAt == null
                                      ? 'Sin usar'
                                      : EsDates.relative(g.lastWornAt!, now),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GarmentFields(draft: _draft),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            ListenableBuilder(
              listenable: _draft,
              builder: (context, _) => Padding(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: FfButton(
                      label: 'Guardar cambios',
                      height: 56,
                      loading: _saving,
                      onPressed: _draft.dirty ? _save : null,
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title,
          ),
        ],
      ),
    );
  }
}
