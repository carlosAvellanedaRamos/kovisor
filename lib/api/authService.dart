import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'sessionService.dart';

class AuthService {
  static Future<String> login(String email, String password) async {
    final url = Uri.parse('http://control.kotexi.com/api/mobile/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['token'] != null) {
        print('Login exitoso para: ${data['user']['email']}');
        return data['token'];
      } else {
        throw Exception('Token no recibido');
      }
    } else {
      throw Exception('Error de autenticación');
    }
  }

  static Future<void> logout() async {
    try {
      final token = await SessionService.getToken();

      if (token != null) {
        print('Cerrando sesión en el servidor...');
        final response = await http.post(
          Uri.parse('http://control.kotexi.com/api/mobile/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          print('Sesión cerrada en el servidor');
        } else {
          print('Error al cerrar sesión en servidor: ${response.statusCode}');
        }
      }

      await SessionService.clearSession();

    } catch (e) {
      print('Error en logout del servidor: $e');
      await SessionService.clearSession();
    }
  }

  static Future<bool> hasValidSession() async {
    return await SessionService.hasValidSession();
  }

  static Future<SessionData?> getCurrentSession() async {
    return await SessionService.getSessionData();
  }
}