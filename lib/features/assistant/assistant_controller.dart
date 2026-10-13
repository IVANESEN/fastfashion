import 'package:flutter/foundation.dart';

import '../../domain/entities/outfit.dart';
import '../../domain/services/assistant_engine.dart';
import '../auth/auth_controller.dart';
import '../closet/closet_controller.dart';
import '../today/today_controller.dart';
import '../today/weather_controller.dart';

/// Un mensaje de la conversación, con las combinaciones que propone el
/// asistente (si las hay).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    this.options = const [],
  });

  final int id;
  final bool fromUser;
  final String text;
  final List<OutfitProposal> options;
}

/// ViewModel del asistente. La conversación vive solo mientras la sesión.
class AssistantController extends ChangeNotifier {
  AssistantController({
    required this.closet,
    required this.weather,
    required this.today,
    required this._auth,
    this.engine = const AssistantEngine(),
    this.replyDelay = const Duration(milliseconds: 380),
    this._clock = DateTime.now,
  }) {
    _auth.addListener(_onAuthChanged);
    _userId = _auth.user?.id;
    _greet();
  }

  /// Atajos que se muestran sobre el campo de texto.
  static const quickReplies = <String>[
    'Algo más formal',
    'Para la lluvia',
    'Sin repetir esta semana',
  ];

  final ClosetController closet;
  final WeatherController weather;
  final TodayController today;
  final AssistantEngine engine;

  /// Pausa breve antes de responder (indicador "escribiendo…").
  final Duration replyDelay;

  final AuthController _auth;
  final DateTime Function() _clock;

  final List<ChatMessage> _messages = [];
  AssistantConstraints _constraints = const AssistantConstraints();
  String? _userId;
  bool _thinking = false;
  int _nextId = 0;
  int _seed = 0;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get thinking => _thinking;

  void _greet() {
    _messages.add(
      ChatMessage(
        id: _nextId++,
        fromUser: false,
        text:
            'Hola, soy tu asistente. Solo busco dentro de tu clóset: dime '
            'qué quieres usar y armo la combinación. Por ejemplo: «camisa '
            'azul con pantalón blanco».',
      ),
    );
  }

  Future<void> send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _thinking) return;

    _messages.add(ChatMessage(id: _nextId++, fromUser: true, text: text));
    _thinking = true;
    notifyListeners();

    if (replyDelay > Duration.zero) {
      await Future<void>.delayed(replyDelay);
    }

    final reply = engine.respond(
      text,
      closet: closet.garments,
      now: _clock(),
      weather: weather.snapshot,
      previous: _constraints,
      seed: _seed++,
    );
    _constraints = reply.constraints;
    _messages.add(
      ChatMessage(
        id: _nextId++,
        fromUser: false,
        text: reply.text,
        options: reply.options,
      ),
    );
    _thinking = false;
    notifyListeners();
  }

  /// Marca la combinación elegida como el outfit de hoy.
  Future<bool> use(OutfitProposal proposal) => today.adopt(proposal);

  void reset() {
    _messages.clear();
    _constraints = const AssistantConstraints();
    _seed = 0;
    _thinking = false;
    _greet();
    notifyListeners();
  }

  void _onAuthChanged() {
    final next = _auth.user?.id;
    if (next == _userId) return;
    _userId = next;
    reset();
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
