import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'reminders_controller.dart';

/// Revisa cada 20 s si toca el aviso diario y, si es así, muestra un banner
/// con acceso directo al outfit.
///
/// Es un aviso **dentro de la app**: un navegador no puede disparar avisos con
/// la pestaña cerrada sin un servidor de notificaciones push.
class ReminderWatcher extends StatefulWidget {
  const ReminderWatcher({
    required this.child,
    required this.onOpenToday,
    required this.messengerKey,
    this.interval = const Duration(seconds: 20),
    super.key,
  });

  final Widget child;
  final VoidCallback onOpenToday;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Duration interval;

  @override
  State<ReminderWatcher> createState() => _ReminderWatcherState();
}

class _ReminderWatcherState extends State<ReminderWatcher> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => _check());
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted) return;
    final reminders = context.read<RemindersController>();
    if (!reminders.takeDue()) return;
    final messenger = widget.messengerKey.currentState;
    messenger?.showSnackBar(
      SnackBar(
        content: const Text('Tu outfit de hoy está listo.'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(label: 'Verlo', onPressed: widget.onOpenToday),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
