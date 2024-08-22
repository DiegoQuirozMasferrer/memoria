import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Aplicación Web en Flutter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                // Aquí irá la lógica para obtener los datos
              },
              child: Text('Obtener Datos'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Otra acción
              },
              child: Text('Otro Botón'),
            ),
          ],
        ),
      ),
    );
  }
}
