# Arquitectura

FastFashion sigue una **arquitectura por capas** con dependencias que apuntan hacia el dominio:

```
 presentation (features/*, core/widgets, app/)  ──►  domain  ◄──  data (local, supabase, weather)
        Widgets + ViewModels (ChangeNotifier)        entidades,         implementa los contratos
                                                     contratos,         del dominio
                                                     servicios puros
```

## Estructura

```
lib/
├── main.dart                     arranque: elige backend por --dart-define
├── app/                          composición: DI, router, shell, config
├── core/                         tema, layout responsivo, widgets del sistema de diseño
├── domain/
│   ├── entities/                 Garment, OutfitProposal, ReminderSettings, UserProfile…
│   ├── repositories/             contratos (interfaces) — lo único que ve la UI
│   └── services/                 OutfitEngine, AssistantEngine, SmartAlerts, color_detector
├── data/
│   ├── datasource/               DatabaseClient / FileStorage (forma PostgREST)
│   ├── local/                    LocalDatabase persistente + auth local
│   ├── supabase/                 SupabaseDatabaseClient + Auth + Storage
│   ├── repositories/             Db*Repository (sirven a cualquier DatabaseClient)
│   ├── weather/                  Open-Meteo
│   └── app_backend.dart          Abstract Factory: local ↔ supabase
└── features/                     auth, closet, today, assistant, reminders, profile
                                  (pantalla + controlador por funcionalidad)
supabase/schema.sql               tablas, trigger, RLS, bucket
```

## Patrones de diseño aplicados

| Patrón | Dónde | Para qué |
|---|---|---|
| **Repository** | `domain/repositories` + `data/repositories` | La UI no sabe si los datos vienen del navegador o de Supabase. |
| **Abstract Factory** | `AppBackend.create` | Una sola decisión (`BACKEND`) arma todo el conjunto de repositorios. |
| **Adapter** | `LocalDatabase`, `SupabaseDatabaseClient` | Ambos adaptan su proveedor al contrato `DatabaseClient`. |
| **MVVM / Observer** | `*Controller extends ChangeNotifier` + `Provider` | Estado fuera de los widgets, UI declarativa y testeable. |
| **Dependency Injection** | `AppProviders` | Los controladores reciben interfaces; ningún widget crea servicios. |
| **Strategy** | `PhotoPicker`, `ColorDetectorFn`, `WeatherRepository`, `AssistantEngine` | Reemplazables (p. ej. LLM, visión) sin tocar la UI. |
| **Facade** | `TodayController` | Orquesta clóset + clima + motor + historial en una API simple. |
| **Guard / Redirect** | `createRouter` | Rutas públicas/privadas según la sesión. |

## Decisiones clave

- **Un solo contrato de datos.** `DatabaseClient` imita `select/insert/update/upsert/delete` con filtros de
  igualdad. Los repositorios (`DbGarmentRepository`…) se escriben una vez y funcionan con ambos backends;
  las columnas del esquema SQL coinciden 1:1 con `toRow()` de cada entidad.
- **Dominio puro.** Entidades y motores no importan Flutter (los colores se guardan como ARGB `int`), por lo
  que se prueban con `dart test` sin emulador.
- **Motor explicable.** `OutfitEngine` puntúa estilo, armonía de matiz, clima/lluvia, ocasión y recencia, y
  devuelve los *motivos* que se muestran al usuario.
- **Responsivo de verdad.** Sin alturas fijas: listas desplazables, cuadrícula con `SliverLayoutBuilder`,
  controles que se apilan en pantallas angostas o con texto grande, y `AppFrame` que centra la app en
  una columna en escritorio.
- **Accesibilidad.** Objetivos táctiles ≥ 44 px, `Semantics` en controles personalizados, etiqueta visible en
  campos, regiones en vivo para avisos y errores, contraste AA en la paleta.

## Pruebas

| Tipo | Ubicación | Qué cubre |
|---|---|---|
| Unitarias de dominio | `test/domain` | Entidades, motores, detección de color. |
| Capa de datos | `test/data` | `LocalDatabase`, auth local, repositorios, Open-Meteo. |
| Widgets por pantalla | `test/features` | Comportamiento + *overflow* a 320–430 px × 1.4× texto. |
| Flujo completo | `test/app` | Router, guardas, pestañas y navegación (320–1280 px). |
