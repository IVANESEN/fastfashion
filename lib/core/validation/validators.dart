/// Validadores compartidos por formularios y repositorios.
/// Devuelven el mensaje de error en español, o `null` si el valor es válido.
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static const minPasswordLength = 6;

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Escribe tu correo.';
    if (!_email.hasMatch(v)) return 'Ese correo no parece válido.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Escribe tu contraseña.';
    if (v.length < minPasswordLength) {
      return 'Usa al menos $minPasswordLength caracteres.';
    }
    return null;
  }

  static String? name(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Dinos cómo te llamas.';
    if (v.length < 2) return 'Usa al menos 2 letras.';
    return null;
  }

  static String normalizeEmail(String value) => value.trim().toLowerCase();
}
