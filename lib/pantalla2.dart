import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HistoryScreen.dart';
import 'api_service.dart';

class Pantalla2 extends StatefulWidget {
  final String stationId;
  final String recentDate;

  Pantalla2({required this.stationId, required this.recentDate});

  @override
  _Pantalla2State createState() => _Pantalla2State();
}

class _Pantalla2State extends State<Pantalla2> {
  bool isLoading = true;
  num? temperature;
  num? humidity;
  num? humidity_int;
  num? windSpeed;
  double? etc;
  num? solarRadiation;
  num? soilHumidity;
  num? kp;
  String waterMessage = '';

  final num waterAvailableBase = 5.0; // Base de agua disponible (mm/día)
  double? waterNeed;
  double? netDemandInM3; // Demanda neta en m³ por hectárea
  double? irrigationTime; // Tiempo de riego (horas)

  // Variables para el marco de plantación, tipo de riego y caudal
  final TextEditingController plantingFrameController =
  TextEditingController(text: '4.0');
  final TextEditingController flowRateController = TextEditingController();
  final TextEditingController kcController = TextEditingController(text: '0.7'); // Campo para Kc
  String irrigationType = 'Goteo'; // Tipo de riego por defecto
  bool isFlowRateInLiters = true; // True: litros/hora, False: m³/hora

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _fetchStationData();

    // Agregar listeners para los controladores
    plantingFrameController.addListener(() {
      _recalculateNetDemand();
      _recalculateIrrigationTime();
    });

    flowRateController.addListener(() {
      _recalculateIrrigationTime();
    });

    kcController.addListener(() {
      _recalculateETc();
      _recalculateWaterNeed();
      _recalculateNetDemand();
    });
  }

  Future<void> _fetchStationData() async {
    setState(() {
      isLoading = true;
    });

    ApiService apiService = ApiService();
    final data = await apiService.fetchStationDataByDate(
        widget.stationId, widget.recentDate);

    // Procesar datos
    if (data != null && data.containsKey('archivo')) {
      final archivo = data['archivo'] as List<dynamic>;

      if (archivo.isNotEmpty) {
        final firstEntry = archivo.first as Map<String, dynamic>;

        if (firstEntry.containsKey('sensors')) {
          final sensors = firstEntry['sensors'] as List<dynamic>;

          // Obtener datos de BME280_ext
          final bme280Ext = sensors.firstWhere(
                (sensor) => sensor['name'] == 'BME280_ext',
            orElse: () => null,
          );

          if (bme280Ext != null &&
              bme280Ext.containsKey('measurements') &&
              bme280Ext['measurements'] != null) {
            final measurements = bme280Ext['measurements'] as List<dynamic>;

            temperature = _getMeasurementValue(measurements, 'temperature');
            humidity = _getMeasurementValue(measurements, 'humidity');
          }

          // Obtener velocidad del viento de WindSpeed_side
          final windSpeedSensor = sensors.firstWhere(
                (sensor) => sensor['name'] == 'WindSpeed_side',
            orElse: () => null,
          );

          if (windSpeedSensor != null &&
              windSpeedSensor.containsKey('measurements') &&
              windSpeedSensor['measurements'] != null) {
            final measurements =
            windSpeedSensor['measurements'] as List<dynamic>;
            windSpeed = _getMeasurementValue(measurements, 'speed');
          }

          // Obtener radiación solar del sensor BH1750
          if (firstEntry.containsKey('nodes')) {
            final nodes = firstEntry['nodes'] as List<dynamic>;

            for (final node in nodes) {
              final sensors = node['sensors'] as List<dynamic>;

              final bh1750Sensor = sensors.firstWhere(
                    (sensor) => sensor['name'] == 'BH1750',
                orElse: () => null,
              );

              if (bh1750Sensor != null &&
                  bh1750Sensor.containsKey('measurements') &&
                  bh1750Sensor['measurements'] != null) {
                final measurements =
                bh1750Sensor['measurements'] as List<dynamic>;
                solarRadiation = _getMeasurementValue(measurements, 'light')! *
                    0.0079; // Conversión a W/m²
                break;
              }
            }
          }
        }
      }
    }

    _recalculateETc();
    _recalculateWaterNeed();
    _recalculateNetDemand();

    setState(() {
      isLoading = false;
    });
  }

  num? _getMeasurementValue(List<dynamic> measurements, String type) {
    final measurement = measurements.firstWhere(
          (m) => m['type'] == type,
      orElse: () => null,
    );
    return measurement != null ? measurement['value'] as num : null;
  }

  void _recalculateETc() {
    if (temperature != null && solarRadiation != null) {
      // Calcular ET0 usando la fórmula de Hargreaves
      final et0 = _calculateHargreavesET0(temperature!, solarRadiation!);

      // Obtener Kc del campo de entrada
      final kc = double.tryParse(kcController.text) ?? 0.7;

      // Calcular ETc
      setState(() {
        etc = et0 * kc;
      });

      print('ET0 calculado: ${et0.toStringAsFixed(2)} mm/día');
      print('ETc calculado: ${etc?.toStringAsFixed(2)} mm/día');
    } else {
      setState(() {
        etc = null;
      });
      print('No se puede calcular ETc: faltan datos necesarios.');
    }
  }

  double _calculateHargreavesET0(num temperature, num solarRadiation) {
    // Fórmula de Hargreaves simplificada
    final double tMean = temperature.toDouble();
    final double ra = solarRadiation.toDouble(); // Radiación solar en W/m²
    final double et0 = 0.0023 * (tMean + 17.8) * sqrt(ra) * (tMean - 10.0);
    return et0;
  }

  void _recalculateWaterNeed() {
    if (etc != null && etc != 0) {
      // Calcula el agua disponible basada en la humedad del suelo
      final adjustedWaterAvailable =
      calculateAdjustedWaterAvailable(waterAvailableBase, humidity_int);

      // Calcula la necesidad hídrica
      waterNeed = (etc! - adjustedWaterAvailable);

      print('Necesidad hídrica calculada: ${waterNeed?.toStringAsFixed(2)} mm/día');
    } else if (etc == 0) {
      waterNeed = 0;
      print('No es necesario regar.');
    } else {
      print('No se puede calcular la necesidad hídrica: ETc es nulo.');
    }
  }

  void _recalculateNetDemand() {
    if (etc != null) {
      // Marco de plantación en m² por planta
      final plantingFrame = double.tryParse(plantingFrameController.text) ?? 0.0;
      if (plantingFrame <= 0) {
        setState(() {
          netDemandInM3 = null;
          waterMessage = 'Marco de plantación no válido.';
        });
        print('El marco de plantación no es válido.');
        return;
      }

      // Número de plantas por hectárea
      final plantsPerHa = 10000 / plantingFrame;

      // Eficiencia del riego
      final irrigationEfficiency = _getIrrigationEfficiency();

      // Demanda neta ajustada en mm/día
      final netDemandInMm = (etc! * plantsPerHa) / irrigationEfficiency;

      // Convertir de mm/ha a m³/ha
      setState(() {
        netDemandInM3 = netDemandInMm * 0.01; // Conversión de mm a m³

        if (netDemandInM3! <= 0) {
          waterMessage = 'No es necesario regar las plantas.';
        } else {
          waterMessage = '';
        }
      });

      _recalculateIrrigationTime();

      print(
          'Demanda neta ajustada calculada: ${netDemandInM3?.toStringAsFixed(2)} m³/día');
    } else {
      setState(() {
        netDemandInM3 = null;
      });
      print('No se puede calcular la demanda neta ajustada: ETc es nulo.');
      waterMessage = 'No se puede calcular la demanda neta ajustada: ETc es nulo.';
    }
  }

  void _recalculateIrrigationTime() {
    final flowRate = double.tryParse(flowRateController.text) ?? 0.0;
    final plantingFrame = double.tryParse(plantingFrameController.text) ?? 0.0;

    if (netDemandInM3 != null && flowRate > 0 && plantingFrame > 0) {
      final plantsPerHa = 10000 / plantingFrame;
      final demandPerPlant = netDemandInM3! / plantsPerHa;

      if (isFlowRateInLiters) {
        setState(() {
          irrigationTime = (demandPerPlant * 1000) / flowRate;
        });
      } else {
        setState(() {
          irrigationTime = demandPerPlant / flowRate;
        });
      }

      print('Tiempo de riego calculado por planta: ${irrigationTime?.toStringAsFixed(2)} horas');
    } else {
      setState(() {
        irrigationTime = null;
      });
      print('No se puede calcular el tiempo de riego: valores inválidos.');
    }
  }

  double calculateAdjustedWaterAvailable(num base, num? soilHumidity) {
    if (soilHumidity == null) return base.toDouble();
    return base * (soilHumidity / 100);
  }

  double _getIrrigationEfficiency() {
    Map<String, double> irrigationEfficiencies = {
      'Goteo': 0.90,
      'Aspersión': 0.75,
      'Gravedad': 0.55,
    };
    return irrigationEfficiencies[irrigationType] ?? 0.90;
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      plantingFrameController.text = prefs.getString('plantingFrame') ?? '4.0';
      irrigationType = prefs.getString('irrigationType') ?? 'Goteo';
      kcController.text = prefs.getString('kc') ?? '0.7';
    });
  }

  Future<void> _saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('plantingFrame', plantingFrameController.text);
    await prefs.setString('irrigationType', irrigationType);
    await prefs.setString('kc', kcController.text);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(
          context,
          {
            'stationId': widget.stationId,
            'waterNeed': waterNeed,
            'etc': etc,
          },
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Estación: ${widget.stationId}'),
          actions: [
            IconButton(
              icon: Icon(Icons.history),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextField(
                controller: kcController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Coeficiente de Cultivo (Kc)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: plantingFrameController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _saveData();
                  _recalculateNetDemand();
                },
                decoration: InputDecoration(
                  labelText: 'Marco de Plantación (m² por planta)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: flowRateController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _recalculateIrrigationTime();
                },
                decoration: InputDecoration(
                  labelText: isFlowRateInLiters
                      ? 'Caudal (litros/hora)'
                      : 'Caudal (m³/hora)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text(isFlowRateInLiters
                    ? 'Caudal (m³/hora)'
                    : 'Caudal (litros/hora)'),
                value: isFlowRateInLiters,
                onChanged: (value) {
                  setState(() {
                    isFlowRateInLiters = value;
                    _recalculateIrrigationTime();
                  });
                },
              ),
              SizedBox(height: 16),
              DropdownButton<String>(
                value: irrigationType,
                isExpanded: true,
                items: ['Goteo', 'Aspersión', 'Gravedad']
                    .map((String irrigation) {
                  return DropdownMenuItem<String>(
                    value: irrigation,
                    child: Text(irrigation),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    irrigationType = newValue!;
                    _saveData();
                    _recalculateNetDemand();
                  });
                },
              ),
              SensorCard(
                title: 'Necesidad Hídrica',
                icon: Icons.water_drop,
                value:
                '${waterNeed?.toStringAsFixed(2) ?? "Sin datos"} mm/día',
                color: Colors.blueAccent,
              ),
              SensorCard(
                title: 'Demanda Neta Ajustada',
                icon: Icons.calculate,
                value:
                '${netDemandInM3?.toStringAsFixed(2) ?? "Sin datos"} m³/ha',
                color: Colors.green,
              ),
              SensorCard(
                title: 'Tiempo de Riego',
                icon: Icons.timer,
                value:
                '${irrigationTime?.toStringAsFixed(2) ?? "Sin datos"} horas',
                color: Colors.orange,
              ),
              _buildWaterMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaterMessage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        waterMessage,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: waterMessage.contains('No es necesario')
              ? Colors.green
              : Colors.red,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final Color color;

  SensorCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}