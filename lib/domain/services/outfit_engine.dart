import '../entities/garment.dart';
import '../entities/garment_category.dart';
import '../entities/garment_style.dart';
import '../entities/occasion.dart';
import '../entities/outfit.dart';
import '../entities/weather_snapshot.dart';

/// Filtro duro por tipo de prenda (p. ej. "camisa azul").
typedef GarmentFilter = bool Function(Garment garment);

/// Parámetros de una búsqueda de outfits.
class OutfitRequest {
  const OutfitRequest({
    required this.now,
    this.occasion = Occasion.classes,
    this.weather,
    this.style,
    this.avoidRecent = false,
    this.forceRain = false,
    this.filters = const {},
    this.exclude = const {},
    this.seed = 0,
  });

  final DateTime now;
  final Occasion occasion;
  final WeatherSnapshot? weather;

  /// Estilo preferido; si es nulo se usa el de la [occasion].
  final GarmentStyle? style;

  /// "Sin repetir esta semana": penaliza fuerte lo usado en los últimos 7 días.
  final bool avoidRecent;

  /// Trata el día como lluvioso aunque el pronóstico no lo diga.
  final bool forceRain;

  /// Restricciones duras por categoría.
  final Map<GarmentCategory, GarmentFilter> filters;

  /// Firmas ([OutfitProposal.signature]) que no deben repetirse.
  final Set<String> exclude;

  /// Cambia el desempate entre combinaciones similares ("Otra opción").
  final int seed;

  GarmentStyle get targetStyle => style ?? occasion.preferredStyle;

  bool get rainy => forceRain || (weather?.isRainLikely ?? false);
  bool get hot => weather?.isHot ?? false;
  bool get cold => weather?.isCold ?? false;
}

/// Motor determinista de combinaciones.
///
/// Arma `camisa × pantalón × zapatos (× chaqueta)` con prendas del clóset del
/// usuario y las ordena por un puntaje explicable (estilo, armonía de color,
/// clima, ocasión y recencia de uso). No inventa prendas: solo combina lo que
/// ya existe.
class OutfitEngine {
  const OutfitEngine();

  /// Tamaño máximo por categoría antes de combinar (acota el producto).
  static const _maxPerSlot = 14;

  List<OutfitProposal> suggest(
    List<Garment> closet,
    OutfitRequest request, {
    int limit = 5,
  }) {
    final tops = _slot(closet, GarmentCategory.top, request);
    final bottoms = _slot(closet, GarmentCategory.bottom, request);
    if (tops.isEmpty || bottoms.isEmpty) return const [];

    final shoes = _slot(closet, GarmentCategory.shoes, request);
    final jackets = _slot(closet, GarmentCategory.jacket, request);

    final jacketRequested = request.filters.containsKey(GarmentCategory.jacket);
    final jacketRequired =
        jackets.isNotEmpty && (request.cold || jacketRequested);
    final jacketOptional =
        jackets.isNotEmpty && request.rainy && !request.hot && !jacketRequired;
    final jacketOptions = <Garment?>[
      if (!jacketRequired) null,
      if (jacketRequired || jacketOptional) ...jackets,
    ];
    final shoeOptions = <Garment?>[
      ...shoes.isEmpty ? [null] : shoes,
    ];

    final candidates = <_Scored>[];
    for (final top in tops) {
      for (final bottom in bottoms) {
        for (final shoe in shoeOptions) {
          for (final jacket in jacketOptions) {
            final scored = _score(top, bottom, shoe, jacket, request);
            if (request.exclude.contains(scored.proposal.signature)) continue;
            candidates.add(scored);
          }
        }
      }
    }
    if (candidates.isEmpty) return const [];

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return _diversify(candidates, limit);
  }

  /// Prendas de una categoría que pasan el filtro, mejores primero y acotadas.
  List<Garment> _slot(
    List<Garment> closet,
    GarmentCategory category,
    OutfitRequest r,
  ) {
    final filter = r.filters[category];
    final items = closet
        .where((g) => g.category == category && (filter?.call(g) ?? true))
        .toList();
    if (items.length <= _maxPerSlot) return items;
    items.sort((a, b) => _itemScore(b, r).compareTo(_itemScore(a, r)));
    return items.sublist(0, _maxPerSlot);
  }

  double _itemScore(Garment g, OutfitRequest r) {
    return _styleAffinity(g.style, r.targetStyle) + _recency(g, r);
  }

  static double _styleAffinity(GarmentStyle item, GarmentStyle target) {
    if (item == target) return 2;
    if (item == GarmentStyle.casual || target == GarmentStyle.casual) {
      return 0.5;
    }
    return -2; // formal ↔ deportivo
  }

  static double _recency(Garment g, OutfitRequest r) {
    var score = 0.0;
    if (g.wornWithin(2, r.now)) {
      score -= r.avoidRecent ? 4 : 1.2;
    } else if (g.wornWithin(7, r.now)) {
      score -= r.avoidRecent ? 4 : 0.5;
    }
    // Empuje suave a rotar lo que menos se usa.
    score -= 0.08 * g.wearCount.clamp(0, 25);
    return score;
  }

  _Scored _score(
    Garment top,
    Garment bottom,
    Garment? shoes,
    Garment? jacket,
    OutfitRequest r,
  ) {
    final reasons = <String>[];
    final items = [top, bottom, ?shoes, ?jacket];
    var score = 0.0;

    // 1) Estilo de cada prenda y cohesión del conjunto.
    for (final g in items) {
      score += _styleAffinity(g.style, r.targetStyle);
    }
    final styles = items.map((g) => g.style).toSet();
    if (styles.length == 1) {
      score += 1.5;
    } else if (styles.contains(GarmentStyle.formal) &&
        styles.contains(GarmentStyle.sporty)) {
      score -= 3;
    }

    // 2) Armonía de color.
    final harmony = _colorHarmony(top, bottom, shoes);
    score += harmony;
    if (harmony >= 1.5) reasons.add('Colores que combinan bien');

    // 3) Clima.
    if (r.rainy) {
      if (shoes != null) {
        final name = shoes.name.toLowerCase();
        if (name.contains('sandalia') || name.contains('chancla')) {
          score -= 3;
        } else if (shoes.style == GarmentStyle.sporty) {
          score += 1.5;
          reasons.add('Los ${_shoeNoun(shoes)} aguantan mejor el agua');
        } else if (shoes.color.name == 'Café' || shoes.color.name == 'Camel') {
          score -= 0.8; // cuero y gamuza sufren con la lluvia
        }
      }
      if (bottom.color.name == 'Blanco' || bottom.color.name == 'Beige') {
        score -= 0.8; // se mancha con salpicaduras
      }
      if (jacket != null) {
        score += 1.2;
        reasons.add('Llevas capa extra por la lluvia');
      }
    }
    if (r.hot) {
      if (top.color.name == 'Negro' || top.color.name == 'Azul marino') {
        score -= 0.6;
      }
      if (shoes != null && shoes.name.toLowerCase().contains('sandalia')) {
        score += 0.8;
      }
      reasons.add('Prendas ligeras para el calor');
    }
    if (r.cold && jacket != null) {
      score += 1.5;
      reasons.add('Incluye chaqueta por el frío');
    }

    // 4) Recencia.
    var rested = true;
    for (final g in items) {
      score += _recency(g, r);
      if (g.wornWithin(7, r.now)) rested = false;
    }
    if (rested && items.any((g) => g.lastWornAt != null)) {
      reasons.add('Prendas que no usas hace días');
    }

    // 5) Desempate determinista, cambia con `seed`.
    final signature = items.map((g) => g.id).join('|');
    score += (Object.hash(r.seed, signature) & 0xFF) / 255 * 0.6;

    final proposal = OutfitProposal(
      top: top,
      bottom: bottom,
      shoes: shoes,
      jacket: jacket,
      title: _title(r, items),
      occasion: r.occasion,
      style: r.targetStyle,
      score: score,
      reasons: reasons,
    );
    return _Scored(proposal, score);
  }

  static String _shoeNoun(Garment shoes) {
    final first = shoes.name.split(' ').first.toLowerCase();
    return first.isEmpty ? 'zapatos' : first;
  }

  /// Puntaje de armonía entre camisa, pantalón y zapatos.
  static double _colorHarmony(Garment top, Garment bottom, Garment? shoes) {
    var score = 0.0;
    final a = top.color;
    final b = bottom.color;

    if (a.name == b.name && !a.isNeutral) {
      score += 0.5; // monocromático
    } else if (a.isNeutral || b.isNeutral) {
      score += (a.isNeutral && b.isNeutral) ? 1.5 : 2;
    } else {
      final diff = _hueDistance(a.hue, b.hue);
      if (diff <= 40) {
        score += 1; // análogos
      } else if (diff >= 150) {
        score += 1.2; // complementarios
      } else {
        score -= 1.5; // chocan
      }
    }

    if (shoes != null) {
      if (shoes.color.isNeutral) {
        score += 1;
      } else if (shoes.color.name == a.name || shoes.color.name == b.name) {
        score += 0.5;
      } else {
        score -= 0.5;
      }
    }
    return score;
  }

  static double _hueDistance(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  static String _title(OutfitRequest r, List<Garment> items) {
    if (r.rainy) {
      return r.occasion == Occasion.work
          ? 'Oficina a prueba de lluvia'
          : 'Listo para la lluvia';
    }
    return switch (r.occasion) {
      Occasion.classes => r.hot ? 'Fresco para clases' : 'Cómodo para clases',
      Occasion.work => 'Listo para la oficina',
      Occasion.outing =>
        items.any((g) => !g.color.isNeutral)
            ? 'Ligero y con color'
            : 'Look para salir',
      Occasion.sport => 'Listo para entrenar',
    };
  }

  /// Elige hasta [limit] propuestas evitando que todas repitan las mismas
  /// prendas: cada coincidencia con una ya elegida resta puntaje.
  List<OutfitProposal> _diversify(List<_Scored> sorted, int limit) {
    final picked = <_Scored>[];
    final remaining = [...sorted];
    while (picked.length < limit && remaining.isNotEmpty) {
      _Scored? best;
      var bestValue = double.negativeInfinity;
      // Basta con mirar los mejores: el resto no puede superarlos.
      final window = remaining.length > 60 ? 60 : remaining.length;
      for (var i = 0; i < window; i++) {
        final c = remaining[i];
        var overlap = 0;
        for (final p in picked) {
          if (p.proposal.top.id == c.proposal.top.id) overlap++;
          if (p.proposal.bottom.id == c.proposal.bottom.id) overlap++;
        }
        final value = c.score - 1.2 * overlap;
        if (value > bestValue) {
          bestValue = value;
          best = c;
        }
      }
      picked.add(best!);
      remaining.remove(best);
    }
    return picked.map((c) => c.proposal).toList();
  }
}

class _Scored {
  const _Scored(this.proposal, this.score);

  final OutfitProposal proposal;
  final double score;
}
