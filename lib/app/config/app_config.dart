/// Configuración de ejecución, inyectada con `--dart-define`.
///
/// `SUPABASE_ANON_KEY` acepta tanto la anon key clásica como la publishable key.
///
/// Ejemplos:
/// ```
/// flutter run -d chrome                                   # base local
/// flutter run -d chrome \
///   --dart-define=BACKEND=supabase \
///   --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
class AppConfig {
  const AppConfig({
    this.backend = 'local',
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
    backend: String.fromEnvironment('BACKEND', defaultValue: 'local'),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String backend;
  final String supabaseUrl;
  final String supabaseAnonKey;

  /// Solo se usa Supabase si se pidió explícitamente **y** hay credenciales;
  /// de lo contrario la app cae a la base local en vez de fallar.
  bool get useSupabase =>
      backend == 'supabase' &&
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty;
}
