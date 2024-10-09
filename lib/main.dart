import 'package:flutter/material.dart';
import 'pantalla2.dart';
import 'api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web App',
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
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  double? etc; // Evapotranspiración del cultivo
  final double idealWater = 5.0; // Valor ideal de agua en mm, que se puede ajustar

  // Aquí simulamos la cantidad de agua medida para cada dispositivo Arduino
  final Map<String, double> arduinoWaterLevels = {
    'Arduino 1': 3.0, // ejemplo de mm de agua medida
    'Arduino 2': 5.0, // ejemplo de mm de agua medida
    'Arduino 3': 7.0, // ejemplo de mm de agua medida
    'Arduino 4': 4.5, // ejemplo de mm de agua medida
  };

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    ApiService apiService = ApiService();
    final data = await apiService.fetchWeatherData();
    if (data != null) {
      // Supongamos que 'temperature_2m' y 'uv_index' son listas de valores horarios
      double temperatureMean = _calculateMean(data['hourly']['temperature_2m']);
      double uvIndexMean = _calculateMean(data['hourly']['uv_index']);

      // Calcular ETₒ y ETc
      double eto = (temperatureMean * 0.1) + (uvIndexMean * 0.05);
      double kc = 0.7; // Coeficiente de cultivo para paltas
      double etcValue = eto * kc;

      setState(() {
        weatherData = data;
        etc = etcValue;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateMean(List<dynamic> dataList) {
    if (dataList.isEmpty) return 0.0;
    double sum = dataList.fold(0.0, (previous, current) => previous + current);
    return sum / dataList.length;
  }

  double _calculateWaterDifference(String arduinoName) {
    double waterMeasured = arduinoWaterLevels[arduinoName] ?? 0.0;
    return waterMeasured - (etc ?? idealWater); // Diferencia entre agua medida y ETc (o valor ideal)
  }

  double _calculateAverageWaterDifference() {
    double totalDifference = 0.0;
    int count = arduinoWaterLevels.length;

    arduinoWaterLevels.forEach((arduino, waterMeasured) {
      double difference = _calculateWaterDifference(arduino);
      totalDifference += difference;
    });

    return count > 0 ? totalDifference / count : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    double promedioDiferenciaAgua = _calculateAverageWaterDifference();
    double promedioETc = etc ?? 0.0; // Usamos el valor de ETc calculado

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Acción de búsqueda
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Indicador de carga
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
              'Promedios',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Muestra el promedio de las diferencias de agua
                _buildPromedioCard(
                  '${promedioDiferenciaAgua.toStringAsFixed(1)} mm',
                  'Promedio Diferencia de Agua',
                  Colors.blue,
                ),
                // Muestra el promedio de ETc
                _buildPromedioCard(
                  '${promedioETc.toStringAsFixed(2)} mm',
                  'Promedio ETc',
                  Colors.green,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              '% del estado de los cultivos',
              style: TextStyle(fontSize: 16),
            ),
            LinearProgressIndicator(value: 0.7),
            SizedBox(height: 16),
            Text(
              'Dispositivos conectados',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDeviceButton('Arduino 1', Colors.red),
                  _buildDeviceButton('Arduino 2', Colors.orange),
                  _buildDeviceButton('Arduino 3', Colors.orange),
                  _buildDeviceButton('Arduino 4', Colors.green),
                ],
              ),
            ),
            if (etc != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos de Evapotranspiración',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'ETc estimado: ${etc!.toStringAsFixed(2)} mm/día',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Acción del botón flotante
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                // Acción de botón de inicio
              },
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Acción de botón de eliminar
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildPromedioCard(String title, String subtitle, Color color) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: color,
              child: Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceButton(String title, Color color) {
    double waterDifference = _calculateWaterDifference(title); // Calcula la diferencia de agua

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => Pantalla2(initialTitle: title),
        ));
      },
      child: Card(
        color: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.purple, size: 30),
              SizedBox(height: 10),
              Icon(Icons.water_drop, color: Colors.blue),
              Text(
                title,
                style: TextStyle(color: Colors.white),
              ),
              Spacer(),
              LinearProgressIndicator(
                value: waterDifference >= 0 ? 0.5 : 1.0,
                color: color,
                backgroundColor: Colors.grey,
              ),
              SizedBox(height: 10),
              // Uso de Expanded para evitar desbordamiento horizontal
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround, // Alineación lateral
                  children: [
                    Flexible(
                      child: Chip(
                        label: Text(
                          etc != null ? ' ${etc!.toStringAsFixed(2)} mm' : 'Cargando...', // Mostrar ETc calculada o mensaje de carga
                          style: TextStyle(color: Colors.white, fontSize: 8), // Tamaño de texto ajustado
                          overflow: TextOverflow.ellipsis, // Asegura que el texto no se desborde
                        ),
                        backgroundColor: Colors.purple,
                        padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0), // Padding ajustado para más espacio
                      ),
                    ),
                    SizedBox(width: 8), // Espacio entre los chips
                    Flexible(
                      child: Chip(
                        label: Text(
                          '${waterDifference.toStringAsFixed(1)}',
                          style: const TextStyle(color: Colors.white, fontSize:12), // Tamaño de texto ajustado
                          overflow: TextOverflow.ellipsis, // Asegura que el texto no se desborde
                        ),
                        backgroundColor: Colors.purple,
                        padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0), // Padding ajustado para más espacio
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
