import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/routes.dart';
import '../../core/layout/responsive.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/ff_button.dart';
import '../../core/widgets/ff_chip.dart';
import '../../core/widgets/ff_icon_button.dart';
import '../../core/widgets/garment_illustration.dart';
import '../../domain/entities/garment.dart';
import '../../domain/entities/outfit.dart';
import 'assistant_controller.dart';

/// 05 · Asistente: conversación que arma outfits solo con el clóset.
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final AssistantController _assistant = context
      .read<AssistantController>();
  int _seen = 0;

  @override
  void initState() {
    super.initState();
    _assistant.addListener(_onChanged);
    _seen = _assistant.messages.length;
  }

  @override
  void dispose() {
    _assistant.removeListener(_onChanged);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged() {
    final count = _assistant.messages.length + (_assistant.thinking ? 1 : 0);
    if (count == _seen) return;
    _seen = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? text]) async {
    final value = text ?? _input.text;
    if (value.trim().isEmpty) return;
    _input.clear();
    await _assistant.send(value);
  }

  Future<void> _use(OutfitProposal proposal) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final ok = await _assistant.use(proposal);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('¡Listo! Este es tu outfit de hoy.')),
      );
      router.go(AppRoutes.today);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('No pudimos guardar el outfit.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final assistant = context.watch<AssistantController>();
    final pad = context.pagePadding;
    final messages = assistant.messages;

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 12, pad, 8),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            header: true,
                            child: const Text('Asistente', style: AppText.h2),
                          ),
                          Text(
                            'Solo busca en tu clóset',
                            style: AppText.caption.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    FfIconButton(
                      icon: Icons.refresh_rounded,
                      label: 'Nueva conversación',
                      onPressed: assistant.reset,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(pad, 8, pad, 8),
                  itemCount: messages.length + (assistant.thinking ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == messages.length) return const _TypingBubble();
                    return _MessageView(message: messages[i], onUse: _use);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 4, pad, 0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final q in AssistantController.quickReplies) ...[
                        FfChip(
                          label: q,
                          outlined: true,
                          onTap: assistant.thinking ? null : () => _send(q),
                          selected: false,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(pad, 10, pad, 12),
                child: _InputBar(
                  controller: _input,
                  enabled: !assistant.thinking,
                  onSend: _send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final Future<void> Function([String? text]) onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: AppText.body,
              decoration: const InputDecoration(
                hintText: 'Pídele un outfit…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          FfIconButton(
            icon: Icons.send_rounded,
            label: 'Enviar',
            background: AppColors.primary,
            foreground: AppColors.white,
            onPressed: enabled ? () => onSend() : null,
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.message, required this.onUse});

  final ChatMessage message;
  final Future<void> Function(OutfitProposal) onUse;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromUser;
    final maxBubble = MediaQuery.sizeOf(context).width * (mine ? 0.78 : 0.86);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxBubble),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: mine ? AppColors.ink : AppColors.blush,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(22),
          topRight: const Radius.circular(22),
          bottomLeft: Radius.circular(mine ? 22 : 6),
          bottomRight: Radius.circular(mine ? 6 : 22),
        ),
      ),
      child: Text(
        message.text,
        style: AppText.body.copyWith(
          color: mine ? AppColors.white : AppColors.ink,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: mine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Semantics(
            label: mine ? 'Tú: ${message.text}' : 'Asistente: ${message.text}',
            excludeSemantics: true,
            child: bubble,
          ),
          if (message.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            _OptionCards(options: message.options, onUse: onUse),
          ],
        ],
      ),
    );
  }
}

class _OptionCards extends StatelessWidget {
  const _OptionCards({required this.options, required this.onUse});

  final List<OutfitProposal> options;
  final Future<void> Function(OutfitProposal) onUse;

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (var i = 0; i < options.length; i++)
        _OptionCard(
          label: 'Opción ${String.fromCharCode(65 + i)}',
          suggested: i == 0,
          proposal: options[i],
          onUse: () => onUse(options[i]),
        ),
    ];
    if (cards.length == 1) return cards.first;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 10),
          Expanded(child: cards[1]),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.suggested,
    required this.proposal,
    required this.onUse,
  });

  final String label;
  final bool suggested;
  final OutfitProposal proposal;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final names = proposal.garments.map((g) => g.name).join(' · ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: suggested ? AppColors.primary : AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: suggested ? AppColors.primary : AppColors.wine,
                    ),
                  ),
                ),
                if (suggested)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Sugerida',
                      style: TextStyle(
                        fontFamily: 'Lato',
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 92,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final g in proposal.garments)
                  Flexible(child: _MiniGarment(garment: g)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            names,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 10),
          FfButton(
            label: 'Usar',
            height: 44,
            style: suggested ? FfButtonStyle.primary : FfButtonStyle.tonal,
            onPressed: onUse,
          ),
        ],
      ),
    );
  }
}

class _MiniGarment extends StatelessWidget {
  const _MiniGarment({required this.garment});

  final Garment garment;

  @override
  Widget build(BuildContext context) {
    // Camisa y chaqueta un poco más grandes que pantalón y zapatos.
    final size = switch (garment.category.name) {
      'top' || 'jacket' => 52.0,
      'bottom' => 66.0,
      _ => 38.0,
    };
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: GarmentIllustration(
        category: garment.category,
        color: Color(garment.color.value),
        size: size,
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: 'El asistente está escribiendo',
        excludeSemantics: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.blush,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Text('•••', style: TextStyle(color: AppColors.wine)),
        ),
      ),
    );
  }
}
