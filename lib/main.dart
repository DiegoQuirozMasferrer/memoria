import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled7/DetallesCuartel.dart';
import 'api_service.dart'; // Asegúrate de que esta importación apunte a la clase ApiService actualizada

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Cultivos y Clima',
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
  final List<Map<String, dynamic>> cuarteles = []; // Lista de cuarteles con datos

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    _cargarCuarteles();
  }

  // Cargar los cuarteles guardados desde SharedPreferences
  Future<void> _cargarCuarteles() async {
    final prefs = await SharedPreferences.getInstance();
    final cuartelesGuardados = prefs.getStringList('cuarteles') ?? [];
    setState(() {
      cuarteles.clear();
      for (var cuartel in cuartelesGuardados) {
        cuarteles.add(Map<String, dynamic>.from(json.decode(cuartel)));
      }
    });
  }

  // Guardar los cuarteles en SharedPreferences
  Future<void> _guardarCuarteles() async {
    final prefs = await SharedPreferences.getInstance();
    final cuartelesGuardados = cuarteles.map((cuartel) => json.encode(cuartel)).toList();
    await prefs.setStringList('cuarteles', cuartelesGuardados);
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

    // Agregar la latitud a los datos meteorológicos
    data?['latitude'] = latitude;

    setState(() {
      weatherData = data;
      isLoading = false;
    });
  }

  // Función para agregar un nuevo cuartel
  void _agregarCuartel() async {
    final nombre = await _mostrarDialogoEditarNombre(context, 'Nuevo Cuartel');
    if (nombre != null && nombre.isNotEmpty) {
      setState(() {
        cuarteles.add({
          'nombre': nombre,
          'datos': <String, dynamic>{}, // Asegúrate de que sea un Map<String, dynamic>
        });
      });
      await _guardarCuarteles(); // Guardar los cuarteles actualizados
    }
  }

  // Función para editar el nombre de un cuartel
  void _editarCuartel(int index) async {
    final nombreActual = cuarteles[index]['nombre'];
    final nuevoNombre = await _mostrarDialogoEditarNombre(context, 'Editar Cuartel', nombreActual);
    if (nuevoNombre != null && nuevoNombre.isNotEmpty) {
      setState(() {
        cuarteles[index]['nombre'] = nuevoNombre;
      });
      await _guardarCuarteles(); // Guardar los cuarteles actualizados
    }
  }

  // Función para mostrar un diálogo de edición de nombre
  Future<String?> _mostrarDialogoEditarNombre(BuildContext context, String titulo, [String? valorInicial]) async {
    final controller = TextEditingController(text: valorInicial);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(titulo),
          content: TextFormField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Nombre del cuartel'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final nombre = controller.text.trim();
                if (nombre.isNotEmpty) {
                  Navigator.pop(context, nombre);
                }
              },
              child: Text('Guardar'),
            ),
          ],
        );
      },
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
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Temp. Mínima',
                Icons.thermostat,
                Colors.blue,
                '$tempMin °C',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'Temp. Máxima',
                Icons.thermostat,
                Colors.red,
                '$tempMax °C',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Temp. Promedio',
                Icons.thermostat,
                Colors.green,
                '$tempAvg °C',
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildSummaryCard(
                'Viento Máximo',
                Icons.air,
                Colors.orange,
                '$windSpeed m/s',
              ),
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

  Widget _buildSummaryCard(String title, IconData icon, Color color, String value) {
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 100,
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget para construir una tarjeta de cuartel
  Widget _buildCuartelCard(int index) {
    final nombre = cuarteles[index]['nombre'];
    final datos = cuarteles[index]['datos'] as Map<String, dynamic>; // Asegúrate de que sea un Map<String, dynamic>
    return Card(
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final datosActualizados = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetallesCuartel(
                datos: datos,
                weatherData: weatherData, // Pasar weatherData con la latitud
                onGuardar: (nuevosDatos) async {
                  setState(() {
                    cuarteles[index]['datos'] = nuevosDatos;
                  });
                  await _guardarCuarteles(); // Guardar los cuarteles actualizados
                },
              ),
            ),
          );
        },
        child: Container(
          height: 100,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                nombre ?? 'Sin nombre',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (datos.isNotEmpty)
                Text(
                  'Kc: ${datos['kc'] ?? 'N/A'}, Caudal: ${datos['caudal'] ?? 'N/A'}, Área: ${datos['area'] ?? 'N/A'} m², '
                      'Tiempo de riego: ${datos['Tiempo de riegoo']?? 'N/A'}'
                      ,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Cultivos y Clima'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (weatherData != null) _buildWeatherSummary(),
            SizedBox(height: 32),
            Text(
              'Cuarteles del Cultivo',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: cuarteles.length,
              itemBuilder: (context, index) {
                return _buildCuartelCard(index);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarCuartel,
        child: Icon(Icons.add),
      ),
    );
  }
}