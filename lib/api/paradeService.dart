import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/parade_model.dart';
import 'baseUrl.dart';

class ParadeService {
  static Future<List<Parade>> fetchParades() async {
    final response = await http.get(Uri.parse('${BaseUrlApi.url}/paraderos'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Parade.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar los paraderos');
    }
  }
}