import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/foreign_fleet_model.dart';
import 'baseUrl.dart';

class BackwardFleetService {
  static Future<List<ForeignFleet>> fetchBackwardFleets() async {
    final response = await http.get(Uri.parse('${BaseUrlApi.url}/flota_anterior'));

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
