import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _keyRememberEmail = "remember_email";

  /// Guarda ou apaga o email
  static Future<void> setRememberedEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email == null || email.isEmpty) {
      await prefs.remove(_keyRememberEmail);
    } else {
      await prefs.setString(_keyRememberEmail, email);
    }
  }

  /// Lê o email guardado (ou null se não existir)
  static Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRememberEmail);
  }
}
