import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fleet_model.dart';
import 'baseUrl.dart';

class FleetService {
  static Future<Fleet> fetchFleet() async {
    final response = await http.get(Uri.parse('${BaseUrlApi.url}/flota'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is Map && data['flota'] is List) {
        return Fleet.fromJson(data['flota'][0]);
      } else if (data is List) {
        return Fleet.fromJson(data[0]);
      } else {
        throw Exception('Formato inesperado de datos');
      }
    } else {
      throw Exception('Error al cargar la flota actual');
    }
  }
}
