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

  @override
  void initState() {
    super.initState();
    _fetchStationData();
  }

  /// Obtiene `fechaMasReciente` de cada estación
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

        // Imprime la fecha en la consola
        print('Estación: $stationId, Fecha más reciente: $recentDate');
      } else {
        stationDates[stationId] = 'Sin datos';

        // Imprime que no se encontraron datos
        print('Estación: $stationId, Fecha más reciente: Sin datos');
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  /// Construye un botón dinámico para cada estación con la fecha más reciente
  Widget _buildDeviceButton(String stationId, Color color) {
    final recentDate = stationDates[stationId] ?? 'Sin datos';

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Pantalla2(
            stationId: stationId,
            recentDate: recentDate,
          ),
        ),
      ),
      child: Card(
        color: Colors.grey[800],
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
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                'Fecha: $recentDate',
                style: TextStyle(fontSize: 14, color: Colors.white70),
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
        title: Text('Estaciones'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Dispositivos conectados',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: widget.estaciones.length,
                itemBuilder: (context, index) {
                  Color color = Colors.primaries[index % Colors.primaries.length];
                  return _buildDeviceButton(widget.estaciones[index], color);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
