import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DetallesCuartel extends StatefulWidget {
  final Map<String, dynamic> datos; // Datos del cuartel
  final Map<String, dynamic>? weatherData; // Datos meteorológicos
  final Function(Map<String, dynamic>) onGuardar;

  DetallesCuartel({required this.datos, this.weatherData, required this.onGuardar});

  @override
  _DetallesCuartelState createState() => _DetallesCuartelState();
}

class _DetallesCuartelState extends State<DetallesCuartel> {
  final _formKey = GlobalKey<FormState>();
  final _controllerKc = TextEditingController();
  final _controllerCaudal = TextEditingController();
  final _controllerEmisores = TextEditingController();
  double? _etc;
  final _controllerArea = TextEditingController();
  double? _tiempoRiego;
  double? _etoHargreaves; // Valor de ETo calculado con Hargreaves

  @override
  void initState() {
    super.initState();
    // Inicializar los controladores con los datos existentes
    _controllerKc.text = widget.datos['kc'] ?? '';
    _controllerCaudal.text = widget.datos['caudal'] ?? '';
    _controllerEmisores.text = widget.datos['emisores'] ?? '';
    _controllerArea.text = widget.datos['Area'] ?? '';

    // Calcular ETo si hay datos meteorológicos disponibles
    if (widget.weatherData != null) {
      _etoHargreaves = _calcularEToHargreaves(widget.weatherData!);
    }

    // Escuchar cambios en los controladores para recalcular ETo
    _controllerKc.addListener(_recalcularETo);
    _controllerCaudal.addListener(_recalcularETo);
    _controllerEmisores.addListener(_recalcularETo);
    _controllerArea.addListener(_recalcularETo);
  }

  @override
  void dispose() {
    // Limpiar los controladores cuando el widget se destruya
    _controllerKc.removeListener(_recalcularETo);
    _controllerCaudal.removeListener(_recalcularETo);
    _controllerEmisores.removeListener(_recalcularETo);
    _controllerArea.removeListener(_recalcularETo);
    _controllerKc.dispose();
    _controllerCaudal.dispose();
    _controllerEmisores.dispose();
    _controllerArea.dispose();
    super.dispose();
  }

  /// Recalcula ETo cuando se modifican los valores de Kc, caudal o emisores
  void _recalcularETo() {
    if (widget.weatherData != null) {
      setState(() {
        _etoHargreaves = _calcularEToHargreaves(widget.weatherData!);

        // Calcular ETc usando el valor de Kc
        final kc = double.tryParse(_controllerKc.text) ?? 0.0;
        _etc = (_etoHargreaves ?? 0.0) * kc;

        // Calcular el tiempo de riego
        final area = double.tryParse(_controllerArea.text) ?? 1.0; // Área en m² (valor por defecto: 1 m²)
        final caudal = double.tryParse(_controllerCaudal.text) ?? 0.0; // Caudal en L/h
        final emisores = int.tryParse(_controllerEmisores.text) ?? 0; // Número de emisores

        if (caudal > 0 && emisores > 0) {
          final volumenAgua = _etc! * area; // Volumen de agua en litros (1 mm = 1 L/m²)
          final caudalTotal = caudal * emisores; // Caudal total en L/h
          _tiempoRiego = volumenAgua / caudalTotal; // Tiempo de riego en horas
        } else {
          _tiempoRiego = null;
        }
      });
    }
  }

  /// Calcula la evapotranspiración de referencia (ETo) usando la fórmula de Hargreaves
  double _calcularEToHargreaves(Map<String, dynamic> weatherData) {
    final double tAvg = weatherData['temperature_avg'] ?? 0.0; // Temperatura promedio
    final double tMax = weatherData['temperature_max'] ?? 0.0; // Temperatura máxima
    final double tMin = weatherData['temperature_min'] ?? 0.0; // Temperatura mínima
    final double ra = _calcularRadiacionExtraterrestre(weatherData); // Radiación solar extraterrestre

    // Fórmula de Hargreaves: ETo = 0.0023 * (Tavg + 17.8) * (Tmax - Tmin)^0.5 * Ra
    final double eto = 0.0023 * (tAvg + 17.8) * pow((tMax - tMin), 0.5) * ra;

    return eto;
  }

  int _calcularDiaDelAnio() {
    final now = DateTime.now(); // Obtiene la fecha actual
    final startOfYear = DateTime(now.year, 1, 1); // Primer día del año
    final diaDelAnio = now.difference(startOfYear).inDays + 1; // Día del año (1-365)
    return diaDelAnio;
  }

  /// Calcula la radiación solar extraterrestre (Ra)
  double _calcularRadiacionExtraterrestre(Map<String, dynamic> weatherData) {
    final double latitud = -35.4264; // Latitud en grados
    final int diaDelAnio = _calcularDiaDelAnio(); // Día del año (1-365)

    // Convertir la latitud a radianes
    final double phi = latitud * (pi / 180);

    // Declinación solar (δ)
    final double delta = 0.409 * sin((2 * pi / 365) * diaDelAnio - 1.39);

    // Factor de corrección de la distancia Tierra-Sol (dr)
    final double dr = 1 + 0.033 * cos((2 * pi / 365) * diaDelAnio);

    // Ángulo horario de la puesta del sol (ωs)
    final double omegaS = acos(-tan(phi) * tan(delta));

    // Constante solar (Gsc)
    const double gsc = 0.0820; // MJ/m²/min

    // Radiación solar extraterrestre (Ra)
    final double ra = (24 * 60 / pi) * gsc * dr *
        (omegaS * sin(phi) * sin(delta) + cos(phi) * cos(delta) * sin(omegaS));

    return ra;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Cuartel'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _guardarDatos,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (widget.weatherData != null) ...[
                Text(
                  'Datos Meteorológicos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Temperatura Mínima: ${widget.weatherData!['temperature_min']?.toStringAsFixed(2) ?? 'N/A'} °C',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Temperatura Máxima: ${widget.weatherData!['temperature_max']?.toStringAsFixed(2) ?? 'N/A'} °C',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Temperatura Promedio: ${widget.weatherData!['temperature_avg']?.toStringAsFixed(2) ?? 'N/A'} °C',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Viento Máximo: ${widget.weatherData!['wind_speed_max']?.toStringAsFixed(2) ?? 'N/A'} m/s',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Humedad Relativa: ${widget.weatherData!['humidity']?.toStringAsFixed(2) ?? 'N/A'} %',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Radiación Solar Extraterrestre: ${_calcularRadiacionExtraterrestre(widget.weatherData!).toStringAsFixed(2) ?? 'N/A'} MJ/m²/día',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'ETo (Hargreaves): ${_etoHargreaves?.toStringAsFixed(2) ?? 'N/A'} mm/día',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'ETc (Requerimientos hídricos): ${_etc?.toStringAsFixed(2) ?? 'N/A'} mm/día',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (_tiempoRiego != null) ...[
                  SizedBox(height: 16),
                  Text(
                    'Tiempo de riego: ${_tiempoRiego!.toStringAsFixed(2)} horas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
                SizedBox(height: 32),
              ],
              Text(
                'Datos del Cuartel',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controllerKc,
                decoration: InputDecoration(labelText: 'Coeficiente de Cultivo (Kc)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _recalcularETo();
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controllerCaudal,
                decoration: InputDecoration(labelText: 'Caudal de Agua (L/h)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _recalcularETo();
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controllerEmisores,
                decoration: InputDecoration(labelText: 'Número de Emisores'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _recalcularETo();
                  });
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _controllerArea,
                decoration: InputDecoration(labelText: 'Área del cultivo (m²)'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _recalcularETo();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardarDatos() {
    if (_formKey.currentState!.validate()) {
      final nuevosDatos = <String, dynamic>{
        'kc': _controllerKc.text,
        'caudal': _controllerCaudal.text,
        'emisores': _controllerEmisores.text,
        'area': _controllerArea.text,
        'Tiempo de riego': _tiempoRiego,
      };

      // Depuración: Imprime los datos que se están guardando
      print('Datos guardados: $nuevosDatos');

      widget.onGuardar(nuevosDatos);
      Navigator.pop(context);
    }
  }
}