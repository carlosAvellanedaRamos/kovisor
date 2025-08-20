import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sessionService.dart';

class UserService {
  static Future<Map<String, dynamic>> fetchUser() async {
    final token = await SessionService.getToken();

    print('Token obtenido de SessionService: $token');

    if (token == null) throw Exception('Token no encontrado');

    print('Haciendo request a /user con token: $token');

    final response = await http.get(
      Uri.parse('http://control.kotexi.com/api/mobile/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      print('Datos del usuario parseados correctamente');
      return userData;
    } else {
      print('Error en response: ${response.statusCode} - ${response.body}');
      throw Exception('Error al obtener datos del usuario');
    }
  }
}