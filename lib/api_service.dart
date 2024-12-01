import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://34.132.204.112:3004/estaciones';

  /// Obtiene la lista de estaciones disponibles
  Future<List<String>?> fetchStations() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        // Decodifica la respuesta JSON como lista de cadenas
        List<dynamic> jsonData = json.decode(response.body);

        // Verifica que cada elemento sea una cadena y lo convierte
        return jsonData.map((station) => station.toString()).toList();
      } else {
        print("Error al obtener estaciones: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Excepción al obtener estaciones: $e");
      return null;
    }
  }

  /// Obtiene información detallada de una estación por su ID
  Future<Map<String, dynamic>?> fetchStationDetails(String stationId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$stationId'));

      if (response.statusCode == 200) {
        // Procesa la respuesta según el formato esperado
        dynamic jsonData = json.decode(response.body);

        if (jsonData is List<dynamic> && jsonData.isNotEmpty) {
          // Buscar el registro con la fecha más reciente
          jsonData.sort((a, b) => DateTime.parse(b['fechaMasReciente'])
              .compareTo(DateTime.parse(a['fechaMasReciente'])));
          return jsonData.first as Map<String, dynamic>;
        } else if (jsonData is Map<String, dynamic>) {
          return jsonData;
        } else {
          throw Exception("Formato inesperado en los detalles de la estación");
        }
      } else {
        print("Error al obtener detalles de la estación: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Excepción al obtener detalles de la estación: $e");
      return null;
    }
  }
  /// Obtiene los datos de una estación para una fecha específica
  Future<Map<String, dynamic>?> fetchStationDataByDate(
      String stationId, String recentDate) async {
    try {
      // Convertir recentDate en un objeto DateTime y formatear solo la fecha
      final date = DateTime.parse(recentDate).toIso8601String().split('T')[0];
      final url = '$baseUrl/$stationId/$date';

      // Imprime la URL solicitada para depuración
      print('URL solicitada: $url');

      final response = await http.get(Uri.parse(url));

      // Imprime el código de estado y el cuerpo de la respuesta
      print('Código de estado: ${response.statusCode}');
      print('Respuesta completa de la API: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData is Map<String, dynamic>) {
          return jsonData;
        } else {
          throw Exception("Formato inesperado en los datos de la estación");
        }
      } else {
        print("Error al obtener datos de la estación: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Excepción al obtener datos de la estación: $e");
      return null;
    }
  }

}
