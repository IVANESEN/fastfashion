/// Cuenta de demostración que se crea en la base local.
///
/// Solo existe con `BACKEND=local`; con Supabase no se crea ninguna cuenta.
abstract final class DemoAccount {
  static const email = 'ana@fastfashion.app';
  static const password = 'fastfashion';
  static const name = 'Ana Martínez';
}
