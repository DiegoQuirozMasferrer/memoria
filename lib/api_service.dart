import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl =
      "https://clientapis.biovision.digital/siac/climapi-open/v1/forecast";
  final String latitude = "-35.4264";
  final String longitude = "-71.6554";
  final String hourlyParams = "temperature_2m,relative_humidity_2m,uv_index";

  Future<Map<String, dynamic>?> fetchWeatherData() async {
    // Obtén la fecha y hora actual
    DateTime now = DateTime.now();
    String currentDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String currentTime = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    print("Fecha actual: $currentDate, Hora actual: $currentTime");

    final response = await http.get(Uri.parse(
        "$baseUrl?latitude=$latitude&longitude=$longitude&hourly=$hourlyParams"));

    if (response.statusCode == 200) {
      // Si la solicitud fue exitosa, parsea el JSON y retorna los datos
      return json.decode(response.body);
    } else {
      // Si la solicitud falla, retorna null o lanza una excepción
      print("Error al obtener datos: ${response.statusCode}");
      return null;
    }
  }
}
