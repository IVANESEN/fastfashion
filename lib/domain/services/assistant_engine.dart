import '../entities/garment.dart';
import '../entities/garment_category.dart';
import '../entities/garment_color.dart';
import '../entities/garment_style.dart';
import '../entities/occasion.dart';
import '../entities/outfit.dart';
import '../entities/weather_snapshot.dart';
import 'outfit_engine.dart';

/// Lo que el asistente entendió de la conversación hasta ahora.
///
/// Se hereda entre turnos: después de "camisa azul con pantalón blanco", el
/// chip "Algo más formal" conserva los colores y solo cambia el estilo.
class AssistantConstraints {
  const AssistantConstraints({
    this.colors = const {},
    this.nameHints = const {},
    this.looseColor,
    this.style,
    this.occasion,
    this.rain = false,
    this.hot = false,
    this.cold = false,
    this.avoidRecent = false,
  });

  final Map<GarmentCategory, GarmentColor> colors;

  /// Palabras del nombre de la prenda pedidas (p. ej. "oxford", "mocasines").
  final Map<GarmentCategory, String> nameHints;

  /// Color mencionado sin decir a qué prenda pertenece ("algo azul").
  final GarmentColor? looseColor;
  final GarmentStyle? style;
  final Occasion? occasion;
  final bool rain;
  final bool hot;
  final bool cold;
  final bool avoidRecent;

  bool get isEmpty =>
      colors.isEmpty &&
      nameHints.isEmpty &&
      looseColor == null &&
      style == null &&
      occasion == null &&
      !rain &&
      !hot &&
      !cold &&
      !avoidRecent;

  /// [newer] manda; lo que no menciona se hereda de este.
  AssistantConstraints merge(AssistantConstraints newer) {
    return AssistantConstraints(
      colors: {...colors, ...newer.colors},
      nameHints: {...nameHints, ...newer.nameHints},
      looseColor: newer.looseColor ?? looseColor,
      style: newer.style ?? style,
      occasion: newer.occasion ?? occasion,
      rain: rain || newer.rain,
      hot: hot || newer.hot,
      cold: cold || newer.cold,
      avoidRecent: avoidRecent || newer.avoidRecent,
    );
  }
}

class AssistantReply {
  const AssistantReply({
    required this.text,
    this.options = const [],
    this.constraints = const AssistantConstraints(),
  });

  final String text;

  /// Hasta dos combinaciones (opción A "sugerida" y opción B).
  final List<OutfitProposal> options;
  final AssistantConstraints constraints;
}

/// Asistente de outfits **que solo busca en el clóset del usuario**.
///
/// Interpreta español natural con un léxico controlado (colores, prendas,
/// estilos, clima) y delega la búsqueda en [OutfitEngine]. Es una estrategia
/// intercambiable: se puede reemplazar por un LLM manteniendo esta interfaz
/// (`respond`) sin tocar la UI.
class AssistantEngine {
  const AssistantEngine({this.engine = const OutfitEngine()});

  final OutfitEngine engine;

  // ---- Léxico (tokens ya normalizados: minúsculas y sin acentos) ----------

  static const _colorWords = <String, GarmentColor>{
    'azul': GarmentPalette.blue,
    'azules': GarmentPalette.blue,
    'celeste': GarmentPalette.blue,
    'marino': GarmentPalette.navy,
    'negro': GarmentPalette.black,
    'negra': GarmentPalette.black,
    'negros': GarmentPalette.black,
    'negras': GarmentPalette.black,
    'blanco': GarmentPalette.white,
    'blanca': GarmentPalette.white,
    'blancos': GarmentPalette.white,
    'blancas': GarmentPalette.white,
    'beige': GarmentPalette.beige,
    'crema': GarmentPalette.beige,
    'arena': GarmentPalette.beige,
    'khaki': GarmentPalette.beige,
    'caqui': GarmentPalette.beige,
    'gris': GarmentPalette.gray,
    'grises': GarmentPalette.gray,
    'cafe': GarmentPalette.brown,
    'cafes': GarmentPalette.brown,
    'marron': GarmentPalette.brown,
    'lila': GarmentPalette.lilac,
    'morado': GarmentPalette.lilac,
    'morada': GarmentPalette.lilac,
    'violeta': GarmentPalette.lilac,
    'rojo': GarmentPalette.red,
    'roja': GarmentPalette.red,
    'rojos': GarmentPalette.red,
    'rojas': GarmentPalette.red,
    'borgona': GarmentPalette.burgundy,
    'vino': GarmentPalette.burgundy,
    'guinda': GarmentPalette.burgundy,
    'rosa': GarmentPalette.pink,
    'rosado': GarmentPalette.pink,
    'rosada': GarmentPalette.pink,
    'naranja': GarmentPalette.orange,
    'anaranjado': GarmentPalette.orange,
    'amarillo': GarmentPalette.yellow,
    'amarilla': GarmentPalette.yellow,
    'verde': GarmentPalette.green,
    'verdes': GarmentPalette.green,
    'oliva': GarmentPalette.olive,
    'camel': GarmentPalette.camel,
  };

  static const _categoryWords = <String, GarmentCategory>{
    'camisa': GarmentCategory.top,
    'camisas': GarmentCategory.top,
    'camiseta': GarmentCategory.top,
    'camisetas': GarmentCategory.top,
    'blusa': GarmentCategory.top,
    'blusas': GarmentCategory.top,
    'playera': GarmentCategory.top,
    'polo': GarmentCategory.top,
    'polos': GarmentCategory.top,
    'top': GarmentCategory.top,
    'oxford': GarmentCategory.top,
    'pantalon': GarmentCategory.bottom,
    'pantalones': GarmentCategory.bottom,
    'jean': GarmentCategory.bottom,
    'jeans': GarmentCategory.bottom,
    'chino': GarmentCategory.bottom,
    'chinos': GarmentCategory.bottom,
    'short': GarmentCategory.bottom,
    'shorts': GarmentCategory.bottom,
    'jogger': GarmentCategory.bottom,
    'joggers': GarmentCategory.bottom,
    'falda': GarmentCategory.bottom,
    'bermuda': GarmentCategory.bottom,
    'zapato': GarmentCategory.shoes,
    'zapatos': GarmentCategory.shoes,
    'tenis': GarmentCategory.shoes,
    'mocasin': GarmentCategory.shoes,
    'mocasines': GarmentCategory.shoes,
    'sandalia': GarmentCategory.shoes,
    'sandalias': GarmentCategory.shoes,
    'calzado': GarmentCategory.shoes,
    'bota': GarmentCategory.shoes,
    'botas': GarmentCategory.shoes,
    'zapatillas': GarmentCategory.shoes,
    'chaqueta': GarmentCategory.jacket,
    'chaquetas': GarmentCategory.jacket,
    'abrigo': GarmentCategory.jacket,
    'saco': GarmentCategory.jacket,
    'blazer': GarmentCategory.jacket,
    'chamarra': GarmentCategory.jacket,
    'sueter': GarmentCategory.jacket,
    'cardigan': GarmentCategory.jacket,
    'impermeable': GarmentCategory.jacket,
  };

  static const _styleWords = <String, GarmentStyle>{
    'formal': GarmentStyle.formal,
    'formales': GarmentStyle.formal,
    'elegante': GarmentStyle.formal,
    'elegantes': GarmentStyle.formal,
    'casual': GarmentStyle.casual,
    'informal': GarmentStyle.casual,
    'relajado': GarmentStyle.casual,
    'deportivo': GarmentStyle.sporty,
    'deportiva': GarmentStyle.sporty,
    'deportivos': GarmentStyle.sporty,
    'deporte': GarmentStyle.sporty,
    'gym': GarmentStyle.sporty,
    'gimnasio': GarmentStyle.sporty,
    'correr': GarmentStyle.sporty,
    'entrenar': GarmentStyle.sporty,
  };

  static const _occasionWords = <String, Occasion>{
    'clases': Occasion.classes,
    'clase': Occasion.classes,
    'universidad': Occasion.classes,
    'trabajo': Occasion.work,
    'oficina': Occasion.work,
    'reunion': Occasion.work,
    'entrevista': Occasion.work,
    'salida': Occasion.outing,
    'salir': Occasion.outing,
    'fiesta': Occasion.outing,
    'cita': Occasion.outing,
    'cena': Occasion.outing,
    'gym': Occasion.sport,
    'gimnasio': Occasion.sport,
    'entrenar': Occasion.sport,
    'correr': Occasion.sport,
  };

  static const _rainWords = {
    'lluvia',
    'llueve',
    'lloviendo',
    'lluvioso',
    'lluviosa',
    'mojado',
    'paraguas',
    'aguacero',
  };
  static const _hotWords = {
    'calor',
    'caluroso',
    'caliente',
    'fresco',
    'ligero',
  };
  static const _coldWords = {'frio', 'helado', 'fresquito', 'abrigado'};
  static const _greetingWords = {'hola', 'buenas', 'buenos', 'hey', 'saludos'};
  static const _shoppingWords = {
    'comprar',
    'compra',
    'tienda',
    'precio',
    'precios',
    'ofertas',
  };
  static const _fillers = {
    'de',
    'color',
    'en',
    'un',
    'una',
    'el',
    'la',
    'mi',
    'mis',
    'tono',
    'los',
    'las',
    'otro',
    'otra',
  };

  // ---- API ------------------------------------------------------------------

  AssistantReply respond(
    String message, {
    required List<Garment> closet,
    required DateTime now,
    WeatherSnapshot? weather,
    AssistantConstraints previous = const AssistantConstraints(),
    int seed = 0,
  }) {
    final tokens = _tokenize(message);

    if (tokens.any(_shoppingWords.contains)) {
      return AssistantReply(
        text:
            'Solo busco dentro de tu clóset: no recomiendo compras. '
            'Dime qué quieres usar y armo la combinación con lo que ya tienes.',
        constraints: previous,
      );
    }

    final parsed = _parse(tokens, closet);
    final isGreetingOnly =
        parsed.isEmpty && tokens.isNotEmpty && tokens.every(_isChatter);
    if (isGreetingOnly) {
      return AssistantReply(
        text:
            '¡Hola! Cuéntame qué quieres usar hoy, por ejemplo '
            '«camisa azul con pantalón blanco», y lo busco en tu clóset.',
        constraints: previous,
      );
    }

    final hasTops = closet.any((g) => g.category == GarmentCategory.top);
    final hasBottoms = closet.any((g) => g.category == GarmentCategory.bottom);
    if (!hasTops || !hasBottoms) {
      final falta = [
        if (!hasTops) 'una camisa',
        if (!hasBottoms) 'un pantalón',
      ].join(' y ');
      return AssistantReply(
        text:
            'Aún no tengo suficientes prendas para combinar: necesito al '
            'menos $falta en tu clóset.',
        constraints: previous,
      );
    }

    final merged = previous.merge(parsed);

    // Colores pedidos que no existen en el clóset: se avisan y se relajan.
    final missing = <String>[];
    final colors = Map<GarmentCategory, GarmentColor>.of(merged.colors);
    for (final entry in merged.colors.entries) {
      final has = closet.any(
        (g) => g.category == entry.key && g.color.name == entry.value.name,
      );
      if (!has) {
        missing.add('${_noun(entry.key)} ${entry.value.name.toLowerCase()}');
        colors.remove(entry.key);
      }
    }
    final hints = Map<GarmentCategory, String>.of(merged.nameHints);
    hints.removeWhere(
      (cat, hint) =>
          !closet.any((g) => g.category == cat && _norm(g.name).contains(hint)),
    );

    final request = _buildRequest(
      now: now,
      weather: weather,
      merged: merged,
      colors: colors,
      hints: hints,
      seed: seed,
    );

    final loose = merged.looseColor;
    var proposals = engine.suggest(
      closet,
      request,
      limit: loose == null ? 2 : 40,
    );
    var looseMissing = false;
    if (loose != null) {
      final withColor = proposals
          .where((p) => p.garments.any((g) => g.color.name == loose.name))
          .toList();
      if (withColor.isEmpty) {
        looseMissing = true;
        proposals = proposals.take(2).toList();
      } else {
        proposals = withColor.take(2).toList();
      }
    }
    if (looseMissing) {
      missing.add('prenda ${loose!.name.toLowerCase()}');
    }

    if (proposals.isEmpty) {
      return AssistantReply(
        text:
            'No pude armar una combinación con esas condiciones. '
            'Prueba pidiéndome algo más general.',
        constraints: merged,
      );
    }

    return AssistantReply(
      text: _compose(proposals, missing, request, weather),
      options: proposals,
      constraints: merged,
    );
  }

  // ---- Interpretación ---------------------------------------------------------

  static bool _isChatter(String t) =>
      _greetingWords.contains(t) ||
      const {
        'quiero',
        'dame',
        'algo',
        'que',
        'me',
        'puedo',
        'ayuda',
        'por',
        'favor',
        'gracias',
        'ok',
      }.contains(t);

  static String _norm(String s) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    final b = StringBuffer();
    for (final rune in s.toLowerCase().runes) {
      final ch = String.fromCharCode(rune);
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString();
  }

  static List<String> _tokenize(String message) {
    return _norm(message)
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  AssistantConstraints _parse(List<String> tokens, List<Garment> closet) {
    final colors = <GarmentCategory, GarmentColor>{};
    final hints = <GarmentCategory, String>{};
    GarmentColor? loose;
    GarmentStyle? style;
    Occasion? occasion;
    var rain = false, hot = false, cold = false, avoidRecent = false;

    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];

      // "azul marino" es un solo color.
      GarmentColor? color = _colorWords[t];
      if (t == 'azul' && i + 1 < tokens.length && tokens[i + 1] == 'marino') {
        color = GarmentPalette.navy;
        tokens[i + 1] = '_'; // consume el token
      }
      if (t == '_') continue;

      if (color != null) {
        final cat = _nearestCategory(tokens, i);
        if (cat != null) {
          colors[cat] = color;
        } else {
          loose = color;
        }
        continue;
      }

      final cat = _categoryWords[t];
      if (cat != null) {
        // La palabra sirve de pista de nombre solo si alguna prenda la tiene.
        final inName = closet.any(
          (g) => g.category == cat && _norm(g.name).contains(t),
        );
        if (inName) hints[cat] = t;
      }

      style ??= _styleWords[t];
      occasion ??= _occasionWords[t];
      if (_rainWords.contains(t)) rain = true;
      if (_hotWords.contains(t)) hot = true;
      if (_coldWords.contains(t)) cold = true;
    }

    final joined = tokens.join(' ');
    if (joined.contains('sin repetir') ||
        joined.contains('no repetir') ||
        joined.contains('que no repita') ||
        joined.contains('algo nuevo')) {
      avoidRecent = true;
    }
    if (joined.contains('mas formal')) style = GarmentStyle.formal;
    if (joined.contains('mas casual')) style = GarmentStyle.casual;
    if (joined.contains('mas deportivo')) style = GarmentStyle.sporty;

    return AssistantConstraints(
      colors: colors,
      nameHints: hints,
      looseColor: loose,
      style: style,
      occasion: occasion,
      rain: rain,
      hot: hot,
      cold: cold,
      avoidRecent: avoidRecent,
    );
  }

  /// Categoría a la que describe el color en [index]: la más cercana hacia
  /// atrás ("camisa azul") o, si no hay, hacia adelante ("azul camisa").
  static GarmentCategory? _nearestCategory(List<String> tokens, int index) {
    for (var j = index - 1, steps = 0; j >= 0 && steps < 4; j--) {
      final t = tokens[j];
      if (_categoryWords.containsKey(t)) return _categoryWords[t];
      if (!_fillers.contains(t)) break;
      steps++;
    }
    for (var j = index + 1, steps = 0; j < tokens.length && steps < 3; j++) {
      final t = tokens[j];
      if (_categoryWords.containsKey(t)) return _categoryWords[t];
      if (!_fillers.contains(t)) break;
      steps++;
    }
    return null;
  }

  OutfitRequest _buildRequest({
    required DateTime now,
    required WeatherSnapshot? weather,
    required AssistantConstraints merged,
    required Map<GarmentCategory, GarmentColor> colors,
    required Map<GarmentCategory, String> hints,
    required int seed,
  }) {
    // Si pidió calor/frío, simulamos ese clima sobre el real.
    var effective = weather;
    if (merged.hot || merged.cold) {
      effective = WeatherSnapshot(
        cityName: weather?.cityName ?? '',
        temperatureC: merged.hot ? 30 : 12,
        rainProbability: weather?.rainProbability ?? 0,
        rainExpectedAt: weather?.rainExpectedAt,
        fetchedAt: weather?.fetchedAt ?? now,
      );
    }

    final filters = <GarmentCategory, GarmentFilter>{};
    for (final cat in GarmentCategory.values) {
      final color = colors[cat];
      final hint = hints[cat];
      if (color == null && hint == null) continue;
      filters[cat] = (g) =>
          (color == null || g.color.name == color.name) &&
          (hint == null || _norm(g.name).contains(hint));
    }

    return OutfitRequest(
      now: now,
      occasion: merged.occasion ?? Occasion.classes,
      weather: effective,
      style: merged.style,
      avoidRecent: merged.avoidRecent,
      forceRain: merged.rain,
      filters: filters,
      seed: seed,
    );
  }

  // ---- Redacción ------------------------------------------------------------

  static String _noun(GarmentCategory c) => switch (c) {
    GarmentCategory.top => 'camisa',
    GarmentCategory.bottom => 'pantalón',
    GarmentCategory.shoes => 'zapatos',
    GarmentCategory.jacket => 'chaqueta',
  };

  String _compose(
    List<OutfitProposal> options,
    List<String> missing,
    OutfitRequest request,
    WeatherSnapshot? weather,
  ) {
    final parts = <String>[];
    if (missing.isNotEmpty) {
      parts.add(
        'No encontré ${_join(missing)} en tu clóset, así que armé '
        'opciones con lo más parecido.',
      );
    } else {
      final n = options.length;
      parts.add(
        n == 1
            ? 'Encontré 1 combinación en tu clóset.'
            : 'Encontré $n combinaciones en tu clóset.',
      );
    }

    final reason = options.first.reasons.isEmpty
        ? null
        : options.first.reasons.first;
    final rainAt = weather?.rainExpectedAt;
    if (request.rainy) {
      final cause = rainAt != null
          ? 'Como llueve a las ${_hour12(rainAt)}'
          : 'Como se espera lluvia';
      parts.add(
        reason != null
            ? '$cause, te sugiero la primera: ${_lowerFirst(reason)}.'
            : '$cause, te sugiero la primera.',
      );
    } else if (reason != null) {
      parts.add('Te sugiero la primera: ${_lowerFirst(reason)}.');
    }
    return parts.join(' ');
  }

  /// "ningún pantalón blanco ni ninguna prenda lila".
  static String _join(List<String> items) {
    return items
        .map((i) => i.startsWith('prenda ') ? 'ninguna $i' : 'ningún $i')
        .join(' ni ');
  }

  static String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  static String _hour12(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h ${t.hour < 12 ? 'a.m.' : 'p.m.'}';
  }
}
