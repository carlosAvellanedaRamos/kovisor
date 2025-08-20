import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SessionService {
  // Claves para SharedPreferences
  static const String _tokenKey = 'jwt_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  /// Verifica si hay una sesión válida guardada
  static Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (!isLoggedIn || token == null || token.isEmpty) {
        print('🔍 No hay sesión guardada');
        return false;
      }

      // Verificar que el token siga siendo válido
      return await _validateTokenWithServer(token);
    } catch (e) {
      print('Error verificando sesión: $e');
      return false;
    }
  }

  /// Valida el token con el servidor
  static Future<bool> _validateTokenWithServer(String token) async {
    try {
      print('Validando token con servidor...');

      final response = await http.get(
        Uri.parse('http://control.kotexi.com/api/mobile/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('Token válido');
        return true;
      } else {
        print('❌ Token inválido - Status: ${response.statusCode}');
        await clearSession(); // Limpiar sesión inválida
        return false;
      }
    } catch (e) {
      print('Error validando token: $e');
      return false;
    }
  }

  /// Guarda los datos de sesión
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userDataKey, json.encode(userData));
      await prefs.setBool(_isLoggedInKey, true);

      print('Sesión guardada exitosamente');
    } catch (e) {
      print('Error guardando sesión: $e');
    }
  }

  /// Recupera los datos de sesión guardados
  static Future<SessionData?> getSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userDataJson = prefs.getString(_userDataKey);
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

      if (!isLoggedIn || token == null || userDataJson == null) {
        return null;
      }

      final userData = json.decode(userDataJson) as Map<String, dynamic>;

      return SessionData(
        token: token,
        userData: userData,
      );
    } catch (e) {
      print('Error recuperando datos de sesión: $e');
      return null;
    }
  }

  /// Limpia todos los datos de sesión
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_tokenKey);
      await prefs.remove(_userDataKey);
      await prefs.setBool(_isLoggedInKey, false);

      print('🧹 Sesión limpiada');
    } catch (e) {
      print('Error limpiando sesión: $e');
    }
  }

  /// Obtiene solo el token JWT
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      print('Error obteniendo token: $e');
      return null;
    }
  }

  /// Actualiza solo el token (para renovaciones)
  static Future<void> updateToken(String newToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, newToken);
      print('Token actualizado');
    } catch (e) {
      print('Error actualizando token: $e');
    }
  }

  /// Verifica si el usuario está marcado como logueado
  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error verificando estado de login: $e');
      return false;
    }
  }
}

/// Clase para encapsular los datos de sesión
class SessionData {
  final String token;
  final Map<String, dynamic> userData;

  SessionData({
    required this.token,
    required this.userData,
  });

  // Getters de conveniencia
  String? get userId => userData['user_device']?['user_id']?.toString();
  String? get deviceName => userData['user_device']?['name'];
  String? get plate => userData['user_device']?['plate'];
  String? get email => userData['email'];
  String? get name => userData['name'];
}