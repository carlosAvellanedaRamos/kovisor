
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/foreign_fleet_model.dart';
import 'baseUrl.dart';

class AdvanceFleetService {
  static Future<List<ForeignFleet>> fetchAdvanceFleets() async {
    final response = await http.get(Uri.parse('${BaseUrlApi.url}/flota_delante'));
    print(response);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data is List) {
        return data.map((item) => ForeignFleet.fromJson(item)).toList();
      } else {
        throw Exception('Formato inesperado de flota_anterior');
      }
    } else {
      throw Exception('Error al cargar las flotas atrasadas');
    }
  }
}