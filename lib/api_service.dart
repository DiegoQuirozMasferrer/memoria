import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://clientapis.biovision.digital/siac/climapi/v1/forecast';
  final String apiKey = '24e387b90f024131b37de4baec57f670';

  /// Obtiene los datos meteorológicos para una ubicación específica
  Future<Map<String, dynamic>?> fetchWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Construye la URL con los parámetros necesarios
      final url = Uri.parse('$baseUrl?latitude=$latitude&longitude=$longitude'
          '&hourly=temperature_2m,wind_speed_10m'
          '&daily=temperature_2m_max,temperature_2m_min,wind_speed_10m_max,wind_gusts_10m_max,et0_fao_evapotranspiration'
          '&timezone=auto&past_days=7&forecast_days=1&apikey=$apiKey');

      // Realiza la solicitud HTTP
      final response = await http.get(url);

      // Verifica si la solicitud fue exitosa
      if (response.statusCode == 200) {
        // Decodifica la respuesta JSON
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Procesa los datos para extraer la información requerida
        return _processWeatherData(jsonData);
      } else {
        print("Error al obtener datos meteorológicos: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Excepción al obtener datos meteorológicos: $e");
      return null;
    }
  }

  /// Procesa los datos JSON para extraer la información relevante
  Map<String, dynamic> _processWeatherData(Map<String, dynamic> jsonData) {
    // Extrae los datos diarios
    final Map<String, dynamic> dailyData = jsonData['daily'];

    // Calcula la temperatura promedio
    final List<double> maxTemps = List<double>.from(dailyData['temperature_2m_max']);
    final List<double> minTemps = List<double>.from(dailyData['temperature_2m_min']);
    final double avgTemp = (maxTemps.reduce((a, b) => a + b) + minTemps.reduce((a, b) => a + b)) / (maxTemps.length + minTemps.length);

    // Extrae las velocidades del viento
    final List<double> windSpeeds = List<double>.from(dailyData['wind_speed_10m_max']);
    final List<double> windGusts = List<double>.from(dailyData['wind_gusts_10m_max']);

    // Devuelve un mapa con los datos procesados
    return {
      'temperature_min': minTemps.first, // Temperatura mínima del primer día
      'temperature_max': maxTemps.first, // Temperatura máxima del primer día
      'temperature_avg': avgTemp,        // Temperatura promedio
      'wind_speed_max': windSpeeds.first, // Velocidad máxima del viento del primer día
      'wind_gust_max': windGusts.first,   // Ráfaga máxima del viento del primer día
    };
  }

  /// Obtiene los datos de una estación para una fecha específica
  Future<Map<String, dynamic>?> fetchStationDataByDate(
      String stationId, String recentDate) async {
    try {
      // Convertir recentDate en un objeto DateTime y formatear solo la fecha
      final date = DateTime.parse(recentDate).toIso8601String().split('T')[0];
      final url = '$baseUrl?latitude=-35.4264&longitude=-71.6554&hourly=temperature_2m,wind_speed_10m'
          '&daily=temperature_2m_max,temperature_2m_min,wind_speed_10m_max,wind_gusts_10m_max,et0_fao_evapotranspiration'
          '&timezone=auto&past_days=7&forecast_days=1&apikey=$apiKey';

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