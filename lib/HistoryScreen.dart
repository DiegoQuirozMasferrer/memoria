import 'dart:convert'; // Necesario para jsonEncode y jsonDecode
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Demanda Hídrica'),
      ),
      body: FutureBuilder<List<HistoryEntry>>(
        future: _getHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No hay datos en el historial.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }
          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final entry = history[index];
              return ListTile(
                title: Text(
                  'Hora: ${_formatTime(entry.date)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Demanda Hídrica: ${entry.waterDemand.toStringAsFixed(2)} mm/día',
                  style: TextStyle(fontSize: 14),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Recupera el historial desde SharedPreferences
  Future<List<HistoryEntry>> _getHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList('waterDemandHistory') ?? [];

    List<HistoryEntry> entries = history.map((entry) {
      final json = jsonDecode(entry);
      return HistoryEntry.fromJson(json);
    }).toList();

    // Ordenar por fecha descendente (más reciente primero)
    entries.sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    return entries;
  }

  /// Formatea la fecha ISO para extraer solo la hora
  String _formatTime(String isoDate) {
    final DateTime dateTime = DateTime.parse(isoDate);
    final String formattedTime =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return formattedTime;
  }
}

/// Clase que representa una entrada del historial
class HistoryEntry {
  final String date;
  final double waterDemand;

  HistoryEntry({required this.date, required this.waterDemand});

  /// Serializa a JSON
  Map<String, dynamic> toJson() {
    return {'date': date, 'waterDemand': waterDemand};
  }

  /// Crea una instancia desde JSON
  static HistoryEntry fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      date: json['date'],
      waterDemand: (json['waterDemand'] as num).toDouble(),
    );
  }
}
