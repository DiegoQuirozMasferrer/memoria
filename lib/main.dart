import 'package:flutter/material.dart';
import 'pantalla2.dart';
import 'api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiService apiService = ApiService();

  // Obtener estaciones al iniciar la aplicación
  final estaciones = await apiService.fetchStations();

  runApp(MyApp(estaciones: estaciones ?? []));
}

class MyApp extends StatelessWidget {
  final List<String> estaciones;

  MyApp({required this.estaciones});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web App',
      theme: ThemeData.dark(),
      home: HomePage(estaciones: estaciones),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<String> estaciones;

  HomePage({required this.estaciones});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  Map<String, String> stationDates = {};
  Map<String, String> waterMessages = {}; // Mensajes de riego por estación
  Map<String, double?> waterNeeds = {}; // Valores de riego necesarios
  Map<String, double?> etcValues = {}; // Valores de ETc por estación

  @override
  void initState() {
    super.initState();
    _fetchStationData();
    _calculateWaterMessages();
  }

  Future<void> _fetchStationData() async {
    setState(() {
      isLoading = true;
    });

    ApiService apiService = ApiService();
    for (String stationId in widget.estaciones) {
      final data = await apiService.fetchStationDetails(stationId);
      if (data != null && data.containsKey('fechaMasReciente')) {
        final recentDate = data['fechaMasReciente'];
        stationDates[stationId] = recentDate;
      } else {
        stationDates[stationId] = 'Sin datos';
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _calculateWaterMessages() async {
    double totalWaterNeed = 0.0; // Acumulador para las necesidades hídricas
    int count = 0; // Contador de estaciones válidas

    for (String stationId in widget.estaciones) {
      // Simulación de valores obtenidos
      double? waterNeed = waterNeeds[stationId]; // Ejemplo de necesidad hídrica
      double etc = 0; // Ejemplo de ETc


      setState(() {
        waterNeeds[stationId] = waterNeed;
        etcValues[stationId] = etc;
      });

      totalWaterNeed += waterNeed!;
      count++;
    }

    // Calcular el promedio de las necesidades hídricas
    double averageWaterNeed = count > 0 ? totalWaterNeed / count : 0.0;

    setState(() {
      waterNeeds['average'] = averageWaterNeed; // Actualizar el promedio3

    });
  }




  double _calculateAverage(Map<String, double?> data) {
    final nonNullValues = data.values.where((value) => value != null).toList();
    if (nonNullValues.isEmpty) return 0.0;
    return nonNullValues.reduce((a, b) => a! + b!)! / nonNullValues.length;
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

  Widget _buildDeviceButton(String stationId, Color color) {
    final recentDate = stationDates[stationId] ?? 'Sin datos';
    final waterMessage = waterMessages[stationId] ?? 'Calculando...';
    print('Water need for $stationId: ${waterNeeds[stationId]}');
    // Obtener valores calculados para la estación


    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Pantalla2(
              stationId: stationId,
              recentDate: recentDate,
            ),
          ),
        );

        if (result != null && result is Map<String, dynamic>) {
          final returnedStationId = result['stationId'];
          final waterNeed = result['waterNeed'] as double?;

          if (returnedStationId != null && waterNeed != null) {
            setState(() {
              waterMessages[returnedStationId] = waterNeed > 0
                  ? 'Riego necesario: ${waterNeed.toStringAsFixed(2)} mm/día'
                  : 'No es necesario regar las plantas.';


              print('Water need for $stationId: ${waterNeed}');
            });
          }
        }
      },
      child: Card(
        color: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sensors, size: 40, color: color),
              SizedBox(height: 10),
              Text(
                stationId,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 5),
              Text(
                waterMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: waterMessage.contains('No es necesario')
                      ? Colors.green
                      : Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),

            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSummaryCards() {
    final averageWaterNeed = waterNeeds['average'] ?? 0.0;
    final averageEtc = _calculateAverage(etcValues);
    final connectedDevices = widget.estaciones.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryCard(
          'mm Necesarios\nPromedios',
          Icons.water_drop,
          Colors.blue,
          '${averageWaterNeed.toStringAsFixed(2)} m³/día',
        ),
        _buildSummaryCard(
          'Dispositivos\nConectados',
          Icons.devices,
          Colors.purple,
          '  $connectedDevices', // Muestra la cantidad de dispositivos conectados
        ),
      ],
    );
  }

  Widget _buildCultivosProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '% del estado de los cultivos',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.7, // Simulación del progreso
          backgroundColor: Colors.grey[700],
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Bienvenido',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildSummaryCards(),
            SizedBox(height: 16),
            _buildCultivosProgress(),
            SizedBox(height: 16),
            Text(
              'Dispositivos conectados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.estaciones.length,
              itemBuilder: (context, index) {
                Color color = Colors.primaries[index % Colors.primaries.length];
                return _buildDeviceButton(
                  widget.estaciones[index],
                  color,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
