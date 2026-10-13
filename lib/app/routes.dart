/// Rutas de la app. Las pantallas navegan por estas constantes y nunca por
/// cadenas sueltas, de modo que el router sea el único que las conoce.
abstract final class AppRoutes {
  // Públicas
  static const welcome = '/welcome';
  static const login = '/login';
  static const signup = '/signup';

  // Pestañas (dentro de la barra inferior)
  static const today = '/today';
  static const closet = '/closet';
  static const assistant = '/assistant';
  static const reminders = '/reminders';

  // Pantallas completas sobre las pestañas
  static const addGarment = '/closet/add';
  static const garmentPattern = '/closet/item/:id';
  static const profile = '/profile';

  static String garment(String id) => '/closet/item/$id';
}
