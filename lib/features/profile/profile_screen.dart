import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/validation/validators.dart';
import '../../core/widgets/ff_button.dart';
import '../../core/widgets/ff_icon_button.dart';
import '../../data/app_backend.dart';
import '../../domain/entities/user_profile.dart';
import '../auth/auth_controller.dart';
import '../closet/closet_controller.dart';

/// Perfil: datos de la cuenta, ciudad (para el clima) y cierre de sesión.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _name = TextEditingController(
    text: context.read<AuthController>().user?.displayName ?? '',
  );
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.today);
    }
  }

  Future<void> _saveName() async {
    final auth = context.read<AuthController>();
    final error = Validators.name(_name.text);
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }
    setState(() => _nameError = null);
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await auth.updateProfile(displayName: _name.text);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Nombre actualizado.' : (auth.error ?? 'Error.')),
      ),
    );
  }

  Future<void> _pickCity() async {
    final auth = context.read<AuthController>();
    final current = auth.user?.city;
    final picked = await showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('¿En qué ciudad estás?', style: AppText.h2),
            ),
            for (final c in City.supported)
              ListTile(
                minTileHeight: 52,
                title: Text(c.name),
                trailing: c.name == current?.name
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked.name == current?.name) return;
    final ok = await auth.updateProfile(city: picked);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Ahora usamos el clima de ${picked.name}.'
              : (auth.error ?? 'No pudimos cambiar la ciudad.'),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text('Tu clóset queda guardado en tu cuenta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true) await auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final closet = context.watch<ClosetController>();
    final backend = context.read<AppBackend>();
    final user = auth.user;
    final pad = context.pagePadding;

    if (user == null) return const SizedBox.shrink();

    final changed = _name.text.trim() != user.displayName;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 32),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Row(
                  children: [
                    FfIconButton(
                      icon: Icons.arrow_back_rounded,
                      label: 'Volver',
                      onPressed: _back,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: const Text('Perfil', style: AppText.h2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.blush,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.initial,
                      style: AppText.h1.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName,
                  textAlign: TextAlign.center,
                  style: AppText.h2,
                ),
                Text(
                  user.email,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Prendas',
                        value: '${closet.garments.length}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Stat(
                        label: 'Prendas usadas',
                        value:
                            '${closet.garments.where((g) => g.wearCount > 0).length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const SectionLabel('Nombre'),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() => _nameError = null),
                  style: AppText.body,
                  decoration: InputDecoration(errorText: _nameError),
                ),
                const SizedBox(height: 12),
                FfButton(
                  label: 'Guardar nombre',
                  height: 48,
                  loading: auth.busy,
                  onPressed: changed ? _saveName : null,
                ),
                const SizedBox(height: 24),
                const SectionLabel('Clima'),
                const SizedBox(height: 8),
                _Tile(
                  icon: Icons.location_on_outlined,
                  title: 'Ciudad',
                  subtitle: user.city.name,
                  onTap: _pickCity,
                ),
                const SizedBox(height: 24),
                const SectionLabel('Mi clóset'),
                const SizedBox(height: 8),
                _Tile(
                  icon: Icons.add_photo_alternate_outlined,
                  title: 'Cargar prendas de ejemplo',
                  subtitle: 'Agrega un clóset de muestra para probar la app',
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final n = await closet.addSamples();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          n > 0
                              ? 'Agregamos $n prendas de ejemplo.'
                              : 'No pudimos agregar las prendas.',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const SectionLabel('Acerca de'),
                const SizedBox(height: 8),
                _Tile(
                  icon: backend.isLocal
                      ? Icons.storage_outlined
                      : Icons.cloud_done_outlined,
                  title: backend.isLocal
                      ? 'Base de datos local (demo)'
                      : 'Base de datos Supabase',
                  subtitle: backend.isLocal
                      ? 'Tus datos viven en este navegador. Para conectarla a '
                            'Supabase compila con BACKEND=supabase.'
                      : 'Tus datos están sincronizados en la nube.',
                ),
                const SizedBox(height: 28),
                FfButton(
                  label: 'Cerrar sesión',
                  style: FfButtonStyle.outline,
                  icon: Icons.logout_rounded,
                  onPressed: _signOut,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'FastFashion 1.0.0',
                    style: AppText.caption.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
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

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 2),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.label.copyWith(fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.caption),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.wine,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
