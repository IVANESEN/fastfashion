import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ff_button.dart';
import '../../core/widgets/ff_icon_button.dart';
import 'closet_controller.dart';
import 'garment_draft.dart';
import 'garment_form_widgets.dart';
import 'photo_picker.dart';

/// 04 · Agregar prenda: foto → detección de color → datos → guardar.
class AddGarmentScreen extends StatefulWidget {
  const AddGarmentScreen({this.colorDetector, super.key});

  /// Detector de color; por defecto analiza los píxeles de la foto.
  final ColorDetectorFn? colorDetector;

  @override
  State<AddGarmentScreen> createState() => _AddGarmentScreenState();
}

class _AddGarmentScreenState extends State<AddGarmentScreen> {
  late final GarmentDraft _draft = GarmentDraft(detector: widget.colorDetector);
  bool _saving = false;
  String? _nameError;

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
    if (name.isEmpty) {
      setState(() => _nameError = 'Ponle un nombre a la prenda.');
      return;
    }
    setState(() {
      _saving = true;
      _nameError = null;
    });
    final closet = context.read<ClosetController>();
    final saved = await closet.add(
      name: name,
      category: _draft.category,
      style: _draft.style,
      color: _draft.color,
      imageBytes: _draft.photoBytes,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.of(context);
    if (saved == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(closet.error ?? 'No pudimos guardar la prenda.'),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('«${saved.name}» ya está en tu clóset.')),
    );
    context.go(AppRoutes.closet);
  }

  @override
  Widget build(BuildContext context) {
    final picker = context.read<PhotoPicker>();
    final horizontal = MediaQuery.sizeOf(context).width < 360 ? 16.0 : 20.0;
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
                        'Nueva prenda',
                        style: AppText.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
                          const SizedBox(height: 20),
                          GarmentFields(draft: _draft),
                          if (_nameError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _nameError!,
                                style: AppText.caption.copyWith(
                                  color: const Color(0xFFB3261E),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: FfButton(
                    label: 'Guardar en mi clóset',
                    height: 56,
                    loading: _saving,
                    onPressed: _save,
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
