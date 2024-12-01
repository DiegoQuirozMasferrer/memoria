import 'dart:math';
import 'package:flutter/material.dart';
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
  Map<String, dynamic>? stationData;
  num? temperature;
  num? humidity;
  num? windSpeed;
  double? etc;
  num? solarRadiation;
  num? soilHumidity;

  final num waterAvailableBase = 5.0; // Base de agua disponible (mm/día)
  double? waterNeed;

  // Especies vegetales y selección actual
  final List<String> species = ['Paltos', 'Papa', 'Tomate', 'Lechuga'];
  String selectedSpecies = 'Paltos';

  @override
  void initState() {
    super.initState();
    _fetchStationData();
  }

  Future<void> _fetchStationData() async {
    setState(() {
      isLoading = true;
    });

    ApiService apiService = ApiService();
    final data = await apiService.fetchStationDataByDate(
        widget.stationId, widget.recentDate);
    print('Datos de la estación: $data');

    if (data != null && data.containsKey('archivo')) {
      final archivo = data['archivo'] as List<dynamic>;

      if (archivo.isNotEmpty) {
        final firstEntry = archivo.first as Map<String, dynamic>;

        if (firstEntry.containsKey('sensors')) {
          final sensors = firstEntry['sensors'] as List<dynamic>;

          // BME280_ext
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

          // BME280_int
          final bme280Int = sensors.firstWhere(
                (sensor) => sensor['name'] == 'BME280_int',
            orElse: () => null,
          );

          if (bme280Int != null &&
              bme280Int.containsKey('measurements') &&
              bme280Int['measurements'] != null) {
            final measurements = bme280Int['measurements'] as List<dynamic>;
            soilHumidity = _getMeasurementValue(measurements, 'humidity');
          }

          // WindSpeed_side
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

          // BH1750
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

    setState(() {
      stationData = data;
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
    if (temperature != null &&
        humidity != null &&
        windSpeed != null &&
        solarRadiation != null) {
      etc = calculateETc(
          selectedSpecies, temperature!, humidity!, windSpeed!, solarRadiation!);
    }
  }

  void _recalculateWaterNeed() {
    if (etc != null) {
      final adjustedWaterAvailable = calculateAdjustedWaterAvailable(
          waterAvailableBase, soilHumidity);
      waterNeed = etc! - adjustedWaterAvailable;
    }
  }

  double calculateAdjustedWaterAvailable(num base, num? soilHumidity) {
    if (soilHumidity == null) return base.toDouble();
    return base * (soilHumidity / 100);
  }

  double calculateETc(String selectedSpecies, num temperature, num humidity,
      num windSpeed, num solarRadiation) {
    Map<String, double> cropCoefficients = {
      'Paltos': 0.7,
      'Papa': 0.85,
      'Tomate': 1.05,
      'Lechuga': 0.95,
    };

    double kc = cropCoefficients[selectedSpecies] ?? 0.7;

    double et0 = (0.0023 * (temperature + 17.8) * sqrt(windSpeed) *
        solarRadiation) *
        (100 - humidity);

    return et0 * kc;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Estación: ${widget.stationId}'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            DropdownButton<String>(
              value: selectedSpecies,
              isExpanded: true,
              items: species.map((String species) {
                return DropdownMenuItem<String>(
                  value: species,
                  child: Text(species),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedSpecies = newValue!;
                  _recalculateETc();
                  _recalculateWaterNeed();
                });
              },
            ),
            SizedBox(height: 16),
            Text('Temperatura: ${temperature ?? "Sin datos"} °C'),
            Text('Humedad: ${humidity ?? "Sin datos"} %'),
            Text('Velocidad del viento: ${windSpeed ?? "Sin datos"} m/s'),
            Text(
                'Radiación solar: ${solarRadiation?.toStringAsFixed(2) ?? "Sin datos"} W/m²'),
            Text('Humedad del suelo: ${soilHumidity ?? "Sin datos"} %'),
            SizedBox(height: 16),
            Text(
              'Evapotranspiración del cultivo (${selectedSpecies}): ${etc?.toStringAsFixed(2) ?? "Sin datos"} mm/día',
            ),
            SizedBox(height: 16),
            Text(
              'Necesidad Hídrica: ${waterNeed?.toStringAsFixed(2) ?? "Sin datos"} mm/día',
              style: TextStyle(
                  color: waterNeed != null && waterNeed! > 0
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
