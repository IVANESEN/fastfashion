import 'package:fastfashion/domain/entities/garment.dart';
import 'package:fastfashion/domain/entities/garment_category.dart';
import 'package:fastfashion/domain/entities/garment_color.dart';
import 'package:fastfashion/domain/entities/garment_style.dart';
import 'package:fastfashion/domain/entities/reminder_settings.dart';
import 'package:fastfashion/domain/entities/weather_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GarmentPalette.nearest', () {
    test('reconoce colores cercanos a la paleta', () {
      expect(GarmentPalette.nearest(0xFF3A70D5).name, 'Azul');
      expect(GarmentPalette.nearest(0xFF111111).name, 'Negro');
      expect(GarmentPalette.nearest(0xFFFAFAFA).name, 'Blanco');
      expect(GarmentPalette.nearest(0xFFD2B88F).name, 'Beige');
    });
  });

  group('Garment', () {
    test('ida y vuelta fila ↔ entidad', () {
      final garment = Garment(
        id: 'g1',
        userId: 'u1',
        name: 'Camisa oxford',
        category: GarmentCategory.top,
        style: GarmentStyle.formal,
        color: GarmentPalette.blue,
        createdAt: DateTime.utc(2026, 10, 9, 12),
        wearCount: 3,
        lastWornAt: DateTime.utc(2026, 10, 8, 7),
      );
      final copy = Garment.fromRow(garment.toRow());
      expect(copy.id, 'g1');
      expect(copy.category, GarmentCategory.top);
      expect(copy.style, GarmentStyle.formal);
      expect(copy.color, GarmentPalette.blue);
      expect(copy.wearCount, 3);
      expect(copy.lastWornAt, isNotNull);
    });

    test('wornWithin respeta la ventana de días', () {
      final now = DateTime(2026, 10, 9, 8);
      final g = Garment(
        id: 'g',
        userId: 'u',
        name: 'x',
        category: GarmentCategory.top,
        style: GarmentStyle.casual,
        color: GarmentPalette.black,
        createdAt: now,
        lastWornAt: now.subtract(const Duration(days: 3)),
      );
      expect(g.wornWithin(7, now), isTrue);
      expect(g.wornWithin(2, now), isFalse);
    });
  });

  group('ReminderSettings.nextFire', () {
    const base = ReminderSettings(userId: 'u'); // 6:30, lunes a viernes

    test('hoy si aún no pasa la hora', () {
      // Lunes 12 oct 2026, 5:00
      final next = base.nextFire(DateTime(2026, 10, 12, 5));
      expect(next, DateTime(2026, 10, 12, 6, 30));
    });

    test('salta el fin de semana', () {
      // Viernes 9 oct 2026, 8:00 → próximo lunes 12
      final next = base.nextFire(DateTime(2026, 10, 9, 8));
      expect(next, DateTime(2026, 10, 12, 6, 30));
    });

    test('sin aviso diario o sin días no hay próximo', () {
      expect(base.copyWith(dailyOutfit: false).nextFire(DateTime(2026, 10, 12)), isNull);
      expect(
        base.copyWith(days: List.filled(7, false)).nextFire(DateTime(2026, 10, 12)),
        isNull,
      );
    });
  });

  group('WeatherSnapshot', () {
    test('consejo menciona la hora de lluvia', () {
      final w = WeatherSnapshot(
        cityName: 'San Salvador',
        temperatureC: 29,
        rainProbability: 70,
        rainExpectedAt: DateTime(2026, 10, 9, 16),
        fetchedAt: DateTime(2026, 10, 9, 8),
      );
      expect(w.isRainLikely, isTrue);
      expect(w.advice, contains('4 p.m.'));
    });
  });
}
