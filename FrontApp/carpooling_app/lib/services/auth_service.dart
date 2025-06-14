// auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  /// Obtiene el token de sesión almacenado localmente
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Guarda el token de sesión
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  /// Elimina el token de sesión (por ejemplo al cerrar sesión)
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
