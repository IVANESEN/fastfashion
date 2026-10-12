import 'package:shared_preferences/shared_preferences.dart';

/// Almacén clave → texto. En web usa `localStorage` vía SharedPreferences.
abstract interface class KeyValueStore {
  String? read(String key);

  /// Devuelve `false` si no se pudo guardar (p. ej. cuota llena).
  Future<bool> write(String key, String value);

  Future<void> remove(String key);
}

class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPrefsStore> open() async {
    return SharedPrefsStore(await SharedPreferences.getInstance());
  }

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<bool> write(String key, String value) async {
    try {
      return await _prefs.setString(key, value);
    } on Object {
      return false;
    }
  }

  @override
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }
}

/// Implementación en memoria para pruebas.
class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  String? read(String key) => _data[key];

  @override
  Future<bool> write(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
}
