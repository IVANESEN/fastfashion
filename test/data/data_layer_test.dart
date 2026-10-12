import 'dart:typed_data';

import 'package:fastfashion/core/errors/app_failure.dart';
import 'package:fastfashion/data/app_backend.dart';
import 'package:fastfashion/data/local/key_value_store.dart';
import 'package:fastfashion/data/local/local_auth_repository.dart';
import 'package:fastfashion/data/local/local_database.dart';
import 'package:fastfashion/data/repositories/db_garment_repository.dart';
import 'package:fastfashion/data/repositories/db_outfit_repository.dart';
import 'package:fastfashion/data/repositories/db_reminder_repository.dart';
import 'package:fastfashion/data/weather/open_meteo_weather_repository.dart';
import 'package:fastfashion/domain/entities/garment_category.dart';
import 'package:fastfashion/domain/entities/garment_color.dart';
import 'package:fastfashion/domain/entities/garment_style.dart';
import 'package:fastfashion/domain/entities/occasion.dart';
import 'package:fastfashion/domain/entities/outfit.dart';
import 'package:fastfashion/domain/entities/reminder_settings.dart';
import 'package:fastfashion/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryKeyValueStore store;
  late LocalDatabase db;

  setUp(() {
    store = MemoryKeyValueStore();
    db = LocalDatabase(store);
  });

  group('LocalDatabase', () {
    test('insert/select/update/delete con filtros', () async {
      await db.insert('t', {'id': 'a', 'n': 1, 'k': 'x'});
      await db.insert('t', {'id': 'b', 'n': 2, 'k': 'x'});
      await db.insert('t', {'id': 'c', 'n': 3, 'k': 'y'});

      final xs = await db.select(
        't',
        where: {'k': 'x'},
        orderBy: 'n',
        descending: true,
      );
      expect(xs.map((r) => r['id']), ['b', 'a']);

      final updated = await db.update(
        't',
        where: {'id': 'a'},
        values: {'n': 10},
      );
      expect(updated!['n'], 10);

      await db.delete('t', where: {'k': 'x'});
      expect((await db.select('t')).length, 1);
    });

    test('persiste entre instancias (mismo almacén)', () async {
      await db.insert('t', {'id': 'a', 'v': 'hola'});
      final reopened = LocalDatabase(store);
      final row = await reopened.selectOne('t', where: {'id': 'a'});
      expect(row!['v'], 'hola');
    });

    test('upsert actualiza cuando coincide la clave de conflicto', () async {
      await db.upsert(
        't',
        {'id': '1', 'u': 'u1', 'd': '2026-10-12', 'v': 1},
        onConflict: ['u', 'd'],
      );
      await db.upsert(
        't',
        {'id': '2', 'u': 'u1', 'd': '2026-10-12', 'v': 2},
        onConflict: ['u', 'd'],
      );
      final rows = await db.select('t');
      expect(rows.length, 1);
      expect(rows.first['v'], 2);
    });

    test('select devuelve copias (mutar no altera la base)', () async {
      await db.insert('t', {'id': 'a', 'v': 1});
      final row = (await db.select('t')).first;
      row['v'] = 99;
      expect((await db.selectOne('t', where: {'id': 'a'}))!['v'], 1);
    });
  });

  group('Auth local', () {
    late LocalAuthRepository auth;
    setUp(() => auth = LocalAuthRepository(db: db, store: store));

    test('registro, cierre y nuevo inicio de sesión', () async {
      final user = await auth.signUp(
        email: 'Maria@Correo.com ',
        password: 'secreto1',
        displayName: 'María López',
      );
      expect(user.email, 'maria@correo.com');
      expect(auth.currentUser, isNotNull);

      await auth.signOut();
      expect(auth.currentUser, isNull);

      final again = await auth.signIn(
        email: 'maria@correo.com',
        password: 'secreto1',
      );
      expect(again.id, user.id);
    });

    test('rechaza correo duplicado y contraseña incorrecta', () async {
      await auth.signUp(
        email: 'a@b.co',
        password: 'secreto1',
        displayName: 'Ana',
      );
      expect(
        () => auth.signUp(
          email: 'a@b.co',
          password: 'otraclave',
          displayName: 'Ana 2',
        ),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        () => auth.signIn(email: 'a@b.co', password: 'mala-clave'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('valida correo, contraseña corta y nombre', () async {
      expect(
        () => auth.signUp(
          email: 'no-es-correo',
          password: 'secreto1',
          displayName: 'Ana',
        ),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => auth.signUp(email: 'a@b.co', password: '123', displayName: 'Ana'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('restoreSession recupera al usuario tras reabrir', () async {
      final user = await auth.signUp(
        email: 'a@b.co',
        password: 'secreto1',
        displayName: 'Ana',
      );
      final reopened = LocalAuthRepository(db: db, store: store);
      final restored = await reopened.restoreSession();
      expect(restored?.id, user.id);
    });

    test('updateProfile cambia nombre y ciudad', () async {
      await auth.signUp(
        email: 'a@b.co',
        password: 'secreto1',
        displayName: 'Ana',
      );
      final next = await auth.updateProfile(
        displayName: 'Ana María',
        city: City.supported[1],
      );
      expect(next.displayName, 'Ana María');
      expect(next.city.name, 'Santa Ana');
    });

    test('ensureDemoAccount es idempotente y no inicia sesión', () async {
      expect(await auth.ensureDemoAccount(), isNotNull);
      expect(await auth.ensureDemoAccount(), isNull);
      expect(auth.currentUser, isNull);
      final user = await auth.signIn(
        email: DemoAccount.email,
        password: DemoAccount.password,
      );
      expect(user.displayName, DemoAccount.name);
    });
  });

  group('DbGarmentRepository', () {
    late DbGarmentRepository repo;
    final now = DateTime(2026, 10, 12, 8);
    setUp(() {
      repo = DbGarmentRepository(db: db, storage: db, clock: () => now);
    });

    test('crea con foto, lista, edita y elimina', () async {
      final g = await repo.create(
        userId: 'u1',
        name: '  Camisa oxford ',
        category: GarmentCategory.top,
        style: GarmentStyle.formal,
        color: GarmentPalette.blue,
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );
      expect(g.name, 'Camisa oxford');
      expect(g.hasPhoto, isTrue);
      expect(g.imageUrl, startsWith('data:image/jpeg;base64,'));

      expect((await repo.list('u1')).length, 1);
      expect(await repo.list('otro'), isEmpty);

      final edited = await repo.update(g.copyWith(name: 'Camisa azul'));
      expect(edited.name, 'Camisa azul');
      expect(edited.hasPhoto, isTrue);

      await repo.delete(edited);
      expect(await repo.list('u1'), isEmpty);
    });

    test('rechaza nombre vacío', () {
      expect(
        () => repo.create(
          userId: 'u1',
          name: '   ',
          category: GarmentCategory.top,
          style: GarmentStyle.casual,
          color: GarmentPalette.black,
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('markWorn suma usos y fija la fecha', () async {
      final g = await repo.create(
        userId: 'u1',
        name: 'Polo',
        category: GarmentCategory.top,
        style: GarmentStyle.casual,
        color: GarmentPalette.black,
      );
      await repo.markWorn('u1', [g.id], now);
      await repo.markWorn('u1', [g.id], now);
      final after = (await repo.find('u1', g.id))!;
      expect(after.wearCount, 2);
      expect(after.wornWithin(1, now), isTrue);
    });

    test('addSamples crea el clóset de ejemplo', () async {
      final count = await repo.addSamples('u1');
      expect(count, greaterThanOrEqualTo(10));
      final all = await repo.list('u1');
      expect(
        all.map((g) => g.category).toSet(),
        GarmentCategory.values.toSet(),
      );
    });
  });

  group('Outfits y recordatorios', () {
    test('un solo outfit por día: guardar de nuevo lo reemplaza', () async {
      final garments = DbGarmentRepository(db: db, storage: db);
      final outfits = DbOutfitRepository(db: db);
      await garments.addSamples('u1');
      final all = await garments.list('u1');
      final top = all.firstWhere((g) => g.category == GarmentCategory.top);
      final bottom = all.firstWhere(
        (g) => g.category == GarmentCategory.bottom,
      );
      final shoes = all.firstWhere((g) => g.category == GarmentCategory.shoes);

      OutfitProposal proposal(String title) => OutfitProposal(
        top: top,
        bottom: bottom,
        shoes: shoes,
        title: title,
        occasion: Occasion.classes,
        style: GarmentStyle.casual,
      );

      await outfits.saveForDate(
        userId: 'u1',
        date: '2026-10-12',
        proposal: proposal('A'),
      );
      await outfits.saveForDate(
        userId: 'u1',
        date: '2026-10-12',
        proposal: proposal('B'),
      );

      final today = await outfits.forDate('u1', '2026-10-12');
      expect(today!.title, 'B');
      expect((await outfits.history('u1')).length, 1);
    });

    test('recordatorios: valores por defecto y guardado', () async {
      final repo = DbReminderRepository(db: db);
      final defaults = await repo.load('u1');
      expect(defaults.hour, 6);
      expect(defaults.minute, 30);

      final saved = await repo.save(
        defaults.copyWith(hour: 7, minute: 15, smartAlerts: true),
      );
      expect(saved.hour, 7);
      final again = await repo.load('u1');
      expect(again.smartAlerts, isTrue);
      expect(again.days, const ReminderSettings(userId: 'u1').days);
    });
  });

  group('Open-Meteo', () {
    const body = '''
{
  "current": {"time": "2026-10-12T10:00", "temperature_2m": 29.4},
  "hourly": {
    "time": ["2026-10-12T08:00","2026-10-12T09:00","2026-10-12T10:00","2026-10-12T15:00","2026-10-12T16:00"],
    "precipitation_probability": [90, 80, 10, 40, 70]
  }
}''';

    test('ignora horas pasadas y detecta la primera lluvia', () {
      final w = OpenMeteoWeatherRepository.parse(
        City.sanSalvador,
        body,
        fetchedAt: DateTime(2026, 10, 12, 10),
      );
      expect(w.temperatureC, 29.4);
      expect(w.rainProbability, 70);
      expect(w.rainExpectedAt, DateTime(2026, 10, 12, 16));
      expect(w.isRainLikely, isTrue);
      expect(w.isHot, isTrue);
    });
  });

  group('AppBackend.inMemory', () {
    test('arranca con cuenta demo y clóset de ejemplo', () async {
      final backend = await AppBackend.inMemory();
      expect(backend.isLocal, isTrue);
      final user = await backend.auth.signIn(
        email: DemoAccount.email,
        password: DemoAccount.password,
      );
      final garments = await backend.garments.list(user.id);
      expect(garments, isNotEmpty);
    });
  });
}
