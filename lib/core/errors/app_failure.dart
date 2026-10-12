/// Errores de dominio con mensaje listo para mostrar al usuario (español).
///
/// Las capas de datos traducen errores técnicos (HTTP, Supabase, storage)
/// a alguno de estos tipos para que la UI nunca dependa de un proveedor.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

class NetworkFailure extends AppFailure {
  const NetworkFailure([
    super.message = 'No pudimos conectarnos. Revisa tu internet e intenta de nuevo.',
  ]);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = 'No encontramos lo que buscas.']);
}

class UnknownFailure extends AppFailure {
  const UnknownFailure([
    super.message = 'Algo salió mal. Intenta de nuevo en un momento.',
  ]);
}
