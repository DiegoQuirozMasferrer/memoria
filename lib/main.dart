import 'package:flutter/material.dart';
import 'api_service.dart'; // Asegúrate de que esta importación apunte a la clase ApiService actualizada

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Weather App',
      theme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  Map<String, dynamic>? weatherData; // Almacena los datos meteorológicos

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      isLoading = true;
    });

    ApiService apiService = ApiService();

    // Coordenadas de ejemplo (puedes cambiarlas o hacerlas configurables)
    final latitude = -35.4264;
    final longitude = -71.6554;

    // Obtener los datos meteorológicos
    final data = await apiService.fetchWeatherData(
      latitude: latitude,
      longitude: longitude,
    );

    setState(() {
      weatherData = data;
      isLoading = false;
    });
  }

  Widget _buildSummaryCard(String title, IconData icon, Color color, String value) {
    return Expanded(
      child: Card(
        color: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          height: 100,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherSummary() {
    if (weatherData == null) {
      return Center(child: Text('No hay datos meteorológicos disponibles.'));
    }

    final tempMin = weatherData!['temperature_min']?.toStringAsFixed(2) ?? 'N/A';
    final tempMax = weatherData!['temperature_max']?.toStringAsFixed(2) ?? 'N/A';
    final tempAvg = weatherData!['temperature_avg']?.toStringAsFixed(2) ?? 'N/A';
    final windSpeed = weatherData!['wind_speed_max']?.toStringAsFixed(2) ?? 'N/A';
    final windGust = weatherData!['wind_gust_max']?.toStringAsFixed(2) ?? 'N/A';

    return Column(
      children: [
        Text(
          'Resumen del clima',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryCard(
              'Temp. Mínima',
              Icons.thermostat,
              Colors.blue,
              '$tempMin °C',
            ),
            _buildSummaryCard(
              'Temp. Máxima',
              Icons.thermostat,
              Colors.red,
              '$tempMax °C',
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSummaryCard(
              'Temp. Promedio',
              Icons.thermostat,
              Colors.green,
              '$tempAvg °C',
            ),
            _buildSummaryCard(
              'Viento Máximo',
              Icons.air,
              Colors.orange,
              '$windSpeed m/s',
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildSummaryCard(
          'Ráfaga Máxima',
          Icons.air,
          Colors.purple,
          '$windGust m/s',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clima Actual'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildWeatherSummary(),
          ],
        ),
      ),
    );
  }
}