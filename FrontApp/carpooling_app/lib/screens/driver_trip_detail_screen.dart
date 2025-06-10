import 'package:flutter/material.dart';

class DriverTripDetailScreen extends StatefulWidget {
  const DriverTripDetailScreen({super.key});

  @override
  State<DriverTripDetailScreen> createState() => _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState extends State<DriverTripDetailScreen> {
  bool viajeIniciado = false;

  List<Map<String, dynamic>> pasajeros = [
    {
      "nombre": "Laura",
      "apellido": "Martínez",
      "telefono": "3001234567",
      "recogida": "Ciudad Jardín",
      "dejada": "Barrio Junín",
      "precio": 8000,
      "estado": "pendiente",
    },
    {
      "nombre": "Carlos",
      "apellido": "Pérez",
      "telefono": "3129876543",
      "recogida": "Parque el Divino Niño",
      "dejada": "Universidad",
      "precio": 10000,
      "estado": "pendiente",
    },
  ];

  final precioTotal = 26000;

  void _viajeCompletado() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final hayPasajerosAceptados =
        pasajeros.any((p) => p["estado"] == "aceptado");

    return Scaffold(
      appBar: AppBar(
        title: Text("Detalle del recorrido"),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
            child: Text("Cancelar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            color: Colors.blue.shade100,
            child: Center(child: Text("MAPA DE RUTA AQUÍ")),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade100,
            child: Text(
              "Precio total: COP $precioTotal",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pasajeros.length,
              itemBuilder: (context, index) {
                final p = pasajeros[index];
                if (p["estado"] == "rechazado") return SizedBox.shrink();

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${p["nombre"]} ${p["apellido"]}",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("Teléfono: ${p["telefono"]}"),
                            Text("Punto de recogida: ${p["recogida"]}"),
                            Text("Lugar de dejada: ${p["dejada"]}"),
                            Text("Precio a pagar: COP ${p["precio"]}"),
                          ],
                        ),
                      ),
                      if (p["estado"] == "pendiente")
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    pasajeros[index]["estado"] = "aceptado";
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Has aceptado a ${p["nombre"]} ${p["apellido"]}")),
                                  );
                                },
                                child: Container(
                                  color: Colors.green,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  child: Text("Aceptar",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    pasajeros[index]["estado"] = "rechazado";
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Has rechazado a ${p["nombre"]} ${p["apellido"]}")),
                                  );
                                },
                                child: Container(
                                  color: Colors.red,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  child: Text("Rechazar",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (hayPasajerosAceptados && !viajeIniciado)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    viajeIniciado = true;
                  });
                },
                child: Text("Iniciar viaje"),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 45)),
              ),
            ),
          if (viajeIniciado)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _viajeCompletado,
                child: Text("Viaje completado"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 45),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
