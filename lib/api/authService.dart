import 'dart:convert';
import 'package:http/http.dart' as http;

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
        return data['token'];
      } else {
        throw Exception('Token no recibido');
      }
    } else {
      throw Exception('Error de autenticación');
    }
  }
}