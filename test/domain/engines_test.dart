import 'dart:typed_data';

import 'package:fastfashion/domain/entities/garment.dart';
import 'package:fastfashion/domain/entities/garment_category.dart';
import 'package:fastfashion/domain/entities/garment_color.dart';
import 'package:fastfashion/domain/entities/garment_style.dart';
import 'package:fastfashion/domain/entities/occasion.dart';
import 'package:fastfashion/domain/entities/weather_snapshot.dart';
import 'package:fastfashion/domain/services/assistant_engine.dart';
import 'package:fastfashion/domain/services/color_detector.dart';
import 'package:fastfashion/domain/services/outfit_engine.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 10, 12, 8);

var _n = 0;
Garment g(
  String name,
  GarmentCategory cat,
  GarmentStyle style,
  GarmentColor color, {
  DateTime? worn,
  int wears = 0,
}) {
  _n++;
  return Garment(
    id: 'g$_n',
    userId: 'u',
    name: name,
    category: cat,
    style: style,
    color: color,
    createdAt: _now,
    lastWornAt: worn,
    wearCount: wears,
  );
}

List<Garment> closet() {
  _n = 0;
  return [
    g(
      'Camisa oxford azul',
      GarmentCategory.top,
      GarmentStyle.casual,
      GarmentPalette.blue,
    ),
    g(
      'Polo negro',
      GarmentCategory.top,
      GarmentStyle.formal,
      GarmentPalette.black,
    ),
    g(
      'Blusa lila',
      GarmentCategory.top,
      GarmentStyle.casual,
      GarmentPalette.lilac,
    ),
    g(
      'Chino beige',
      GarmentCategory.bottom,
      GarmentStyle.casual,
      GarmentPalette.beige,
    ),
    g(
      'Jeans oscuro',
      GarmentCategory.bottom,
      GarmentStyle.casual,
      GarmentPalette.navy,
    ),
    g(
      'Pantalón blanco',
      GarmentCategory.bottom,
      GarmentStyle.casual,
      GarmentPalette.white,
    ),
    g(
      'Pantalón de vestir negro',
      GarmentCategory.bottom,
      GarmentStyle.formal,
      GarmentPalette.black,
    ),
    g(
      'Tenis blancos',
      GarmentCategory.shoes,
      GarmentStyle.sporty,
      GarmentPalette.white,
    ),
    g(
      'Mocasines café',
      GarmentCategory.shoes,
      GarmentStyle.formal,
      GarmentPalette.brown,
    ),
    g(
      'Sandalias camel',
      GarmentCategory.shoes,
      GarmentStyle.casual,
      GarmentPalette.camel,
    ),
    g(
      'Chaqueta de mezclilla',
      GarmentCategory.jacket,
      GarmentStyle.casual,
      GarmentPalette.blue,
    ),
  ];
}

WeatherSnapshot weather({double t = 24, int rain = 0}) => WeatherSnapshot(
  cityName: 'San Salvador',
  temperatureC: t,
  rainProbability: rain,
  rainExpectedAt: rain >= 50 ? DateTime(2026, 10, 12, 16) : null,
  fetchedAt: _now,
);

void main() {
  const engine = OutfitEngine();

  group('OutfitEngine', () {
    test('sin camisas o pantalones no hay propuestas', () {
      final onlyShoes = closet()
          .where((x) => x.category == GarmentCategory.shoes)
          .toList();
      expect(engine.suggest(onlyShoes, OutfitRequest(now: _now)), isEmpty);
    });

    test('devuelve propuestas completas y distintas', () {
      final result = engine.suggest(
        closet(),
        OutfitRequest(now: _now),
        limit: 4,
      );
      expect(result.length, 4);
      expect(result.map((p) => p.signature).toSet().length, 4);
      for (final p in result) {
        expect(p.top.category, GarmentCategory.top);
        expect(p.bottom.category, GarmentCategory.bottom);
      }
    });

    test('ocasión de trabajo prefiere prendas formales', () {
      final p = engine
          .suggest(
            closet(),
            OutfitRequest(now: _now, occasion: Occasion.work),
            limit: 1,
          )
          .single;
      expect(p.top.style, GarmentStyle.formal);
      expect(p.bottom.style, GarmentStyle.formal);
      expect(p.title, 'Listo para la oficina');
    });

    test('con lluvia elige tenis (no sandalias ni cuero)', () {
      final p = engine
          .suggest(
            closet(),
            OutfitRequest(now: _now, weather: weather(rain: 80)),
            limit: 1,
          )
          .single;
      expect(p.shoes!.name, 'Tenis blancos');
      expect(p.title, 'Listo para la lluvia');
      expect(p.reasons.join(' '), contains('aguantan mejor el agua'));
    });

    test('con frío incluye chaqueta; con calor no', () {
      final cold = engine.suggest(
        closet(),
        OutfitRequest(now: _now, weather: weather(t: 12)),
        limit: 3,
      );
      expect(cold.every((p) => p.jacket != null), isTrue);

      final hot = engine.suggest(
        closet(),
        OutfitRequest(now: _now, weather: weather(t: 31)),
        limit: 3,
      );
      expect(hot.every((p) => p.jacket == null), isTrue);
    });

    test('"sin repetir" evita prendas usadas esta semana', () {
      final c = closet();
      final worn = c.first.copyWith(
        lastWornAt: _now.subtract(const Duration(days: 1)),
      );
      final all = [worn, ...c.skip(1)];
      final result = engine.suggest(
        all,
        OutfitRequest(now: _now, avoidRecent: true),
        limit: 3,
      );
      expect(result.every((p) => p.top.id != worn.id), isTrue);
    });

    test('filtros duros respetan color por categoría', () {
      final result = engine.suggest(
        closet(),
        OutfitRequest(
          now: _now,
          filters: {
            GarmentCategory.top: (x) => x.color.name == 'Azul',
            GarmentCategory.bottom: (x) => x.color.name == 'Blanco',
          },
        ),
        limit: 5,
      );
      expect(result, isNotEmpty);
      expect(result.every((p) => p.top.color.name == 'Azul'), isTrue);
      expect(result.every((p) => p.bottom.color.name == 'Blanco'), isTrue);
    });

    test('mismo seed produce el mismo resultado (determinista)', () {
      final a = engine.suggest(
        closet(),
        OutfitRequest(now: _now, seed: 1),
        limit: 1,
      );
      final b = engine.suggest(
        closet(),
        OutfitRequest(now: _now, seed: 1),
        limit: 1,
      );
      expect(a.single.signature, b.single.signature); // determinista
    });

    test('exclude impide repetir una combinación', () {
      final first = engine
          .suggest(closet(), OutfitRequest(now: _now), limit: 1)
          .single;
      final next = engine
          .suggest(
            closet(),
            OutfitRequest(now: _now, exclude: {first.signature}),
            limit: 1,
          )
          .single;
      expect(next.signature, isNot(first.signature));
    });
  });

  group('AssistantEngine', () {
    const assistant = AssistantEngine();

    AssistantReply ask(
      String msg, {
      List<Garment>? c,
      WeatherSnapshot? w,
      AssistantConstraints prev = const AssistantConstraints(),
    }) {
      return assistant.respond(
        msg,
        closet: c ?? closet(),
        now: _now,
        weather: w,
        previous: prev,
      );
    }

    test('camisa azul con pantalón blanco → ambas restricciones', () {
      final r = ask('Hoy quiero usar una camisa azul con un pantalón blanco');
      expect(r.options, isNotEmpty);
      expect(r.options.first.top.color.name, 'Azul');
      expect(r.options.first.bottom.color.name, 'Blanco');
      expect(r.text, contains('Encontré'));
    });

    test('color inexistente: avisa y propone lo más parecido', () {
      final r = ask('quiero un pantalón rojo');
      expect(r.options, isNotEmpty);
      expect(r.text, contains('No encontré ningún pantalón rojo'));
    });

    test('menciona la hora de lluvia cuando llueve', () {
      final r = ask('algo para la lluvia', w: weather(rain: 70));
      expect(r.text, contains('4 p.m.'));
      expect(r.options.first.shoes!.name, 'Tenis blancos');
    });

    test('chip "más formal" conserva colores previos y cambia estilo', () {
      final first = ask('camisa azul con pantalón blanco');
      final second = ask('Algo más formal', prev: first.constraints);
      expect(second.options, isNotEmpty);
      expect(second.options.first.top.color.name, 'Azul');
      expect(second.constraints.style, GarmentStyle.formal);
    });

    test('saludo y compras tienen respuestas de alcance', () {
      expect(ask('hola').options, isEmpty);
      expect(ask('hola').text, contains('clóset'));
      final shop = ask('dónde puedo comprar una camisa');
      expect(shop.options, isEmpty);
      expect(shop.text, contains('Solo busco dentro de tu clóset'));
    });

    test('azul marino es un color distinto de azul', () {
      final r = ask('jeans azul marino');
      expect(r.constraints.colors[GarmentCategory.bottom]?.name, 'Azul marino');
    });

    test('closet insuficiente pide más prendas', () {
      final shoesOnly = closet()
          .where((x) => x.category == GarmentCategory.shoes)
          .toList();
      final r = ask('un outfit', c: shoesOnly);
      expect(r.options, isEmpty);
      expect(r.text, contains('camisa'));
    });
  });

  group('detectDominantColor', () {
    Uint8List solid(int w, int h, int r, int gr, int b) {
      final out = Uint8List(w * h * 4);
      for (var i = 0; i < w * h; i++) {
        out[i * 4] = r;
        out[i * 4 + 1] = gr;
        out[i * 4 + 2] = b;
        out[i * 4 + 3] = 255;
      }
      return out;
    }

    void paintRect(
      Uint8List px,
      int w,
      int x0,
      int y0,
      int x1,
      int y1,
      int r,
      int gr,
      int b,
    ) {
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final i = (y * w + x) * 4;
          px[i] = r;
          px[i + 1] = gr;
          px[i + 2] = b;
        }
      }
    }

    test('prenda azul sobre fondo blanco → Azul (ignora el fondo)', () {
      const w = 64, h = 64;
      final px = solid(w, h, 250, 250, 250);
      paintRect(px, w, 16, 12, 48, 56, 59, 111, 216);
      final d = detectDominantColor(px, w, h)!;
      expect(d.color.name, 'Azul');
      expect(d.confidence, greaterThan(0.6));
    });

    test('prenda negra sobre fondo beige → Negro', () {
      const w = 64, h = 64;
      final px = solid(w, h, 217, 195, 160);
      paintRect(px, w, 14, 14, 50, 54, 30, 28, 36);
      expect(detectDominantColor(px, w, h)!.color.name, 'Negro');
    });

    test('camiseta blanca sobre fondo blanco → Blanco', () {
      const w = 64, h = 64;
      final px = solid(w, h, 244, 242, 240);
      paintRect(px, w, 16, 12, 48, 56, 240, 240, 240);
      expect(detectDominantColor(px, w, h)!.color.name, 'Blanco');
    });

    test('imagen vacía o tamaño inválido devuelve null', () {
      expect(detectDominantColor(Uint8List(0), 0, 0), isNull);
      expect(detectDominantColor(Uint8List(4), 10, 10), isNull);
    });
  });
}
