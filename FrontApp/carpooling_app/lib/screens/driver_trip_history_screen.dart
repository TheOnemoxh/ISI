import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  State<DriverTripHistoryScreen> createState() =>
      _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  List<Map<String, dynamic>> historial = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final data = await ApiService().obtenerHistorialConductor();
    setState(() {
      historial = data;
      cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial del conductor")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : historial.isEmpty
              ? const Center(child: Text("No hay viajes registrados"))
              : ListView.builder(
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final viaje = historial[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: ListTile(
                        title: Text(
                          "${viaje['origen']} → ${viaje['destino']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Fecha: ${viaje['fecha_hora_salida']}"),
                            Text("Precio total: \$${viaje['precio_total']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
