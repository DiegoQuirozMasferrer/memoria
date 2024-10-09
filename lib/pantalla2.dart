import 'package:flutter/material.dart';
import 'api_service.dart';

class Pantalla2 extends StatefulWidget {
  final String initialTitle;

  Pantalla2({required this.initialTitle});

  @override
  _Pantalla2State createState() => _Pantalla2State();
}

class _Pantalla2State extends State<Pantalla2> {
  String? selectedArduino;
  List<String> arduinoList = ['Arduino Uno', 'Arduino Mega', 'Arduino Nano'];
  late String appBarTitle;
  Map<String, dynamic>? weatherData;
  bool isLoading = true;
  double? etc; // Evapotranspiración del cultivo
  String selectedEspecie = 'Palta'; // Especie por defecto seleccionada

  // Lista de especies disponibles
  List<String> especiesCultivo = ['Palta', 'Maíz', 'Trigo', 'Tomate', 'Lechuga'];

  final double aguaMedida = 3.5; // Ejemplo de agua medida en mm (simulada)

  @override
  void initState() {
    super.initState();
    appBarTitle = widget.initialTitle;
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    ApiService apiService = ApiService();
    final data = await apiService.fetchWeatherData();
    setState(() {
      weatherData = data;
      etc = _calculateEtcForPalta(); // Calcular ETc por defecto para Palta
      isLoading = false;
    });
  }

  // Función para calcular la ETc para Palta
  double _calculateEtcForPalta() {
    double kcPalta = 0.7;
    double eto = (weatherData != null)
        ? (_calculateMean(weatherData!['hourly']['temperature_2m']) * 0.1 +
        _calculateMean(weatherData!['hourly']['uv_index']) * 0.05)
        : 0.0;
    return eto * kcPalta;
  }

  // Función para calcular la diferencia de agua
  double _calculateWaterDifference() {
    return aguaMedida - (etc ?? 0.0);
  }

  double _calculateMean(List<dynamic> dataList) {
    if (dataList.isEmpty) return 0.0;
    double sum = dataList.fold(0.0, (previous, current) => previous + current);
    return sum / dataList.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(appBarTitle),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Muestra un indicador de carga mientras se obtienen los datos
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccione la especie de cultivo',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 16),
            // Dropdown para cambiar la especie de cultivo
            DropdownButton<String>(
              dropdownColor: Colors.grey[800],
              isExpanded: true,
              value: selectedEspecie,
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              underline: Container(
                height: 1,
                color: Colors.white,
              ),
              items: especiesCultivo.map((String especie) {
                return DropdownMenuItem<String>(
                  value: especie,
                  child: Text(especie, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (String? newEspecie) {
                setState(() {
                  selectedEspecie = newEspecie!;
                  if (selectedEspecie == 'Palta') {
                    etc = _calculateEtcForPalta(); // Recalcular la ETc para Palta
                  }
                  // Si tienes otras especies, agrega más lógica para calcular la ETc correspondiente
                });
              },
            ),
            SizedBox(height: 24),
            // Mostrar los resultados
            if (etc != null) ...[
              Text(
                "La ETc es: ${etc!.toStringAsFixed(2)} mm",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              SizedBox(height: 16),
              // Mostrar la diferencia de agua
              Text(
                _calculateWaterDifference() >= 0
                    ? "Falta ${_calculateWaterDifference().toStringAsFixed(2)} mm de agua."
                    : "Exceso de ${(-_calculateWaterDifference()).toStringAsFixed(2)} mm de agua.",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
