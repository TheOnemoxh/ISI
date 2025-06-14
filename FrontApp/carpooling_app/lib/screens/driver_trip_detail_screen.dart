import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DriverTripDetailScreen extends StatefulWidget {
  final int recorridoId;

  const DriverTripDetailScreen({super.key, required this.recorridoId});

  @override
  State<DriverTripDetailScreen> createState() => _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState extends State<DriverTripDetailScreen> {
  bool viajeIniciado = false;
  List<Map<String, dynamic>> solicitudes = [];
  Timer? pollingTimer;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
    pollingTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _cargarSolicitudes());
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargarSolicitudes() async {
    final nuevasSolicitudes =
        await ApiService().obtenerSolicitudesPorRecorrido(widget.recorridoId);
    setState(() {
      solicitudes = nuevasSolicitudes;
    });
  }

  Future<void> _cambiarEstadoRecorrido(String nuevoEstado) async {
    final exito = await ApiService()
        .cambiarEstadoRecorrido(widget.recorridoId, nuevoEstado);
    if (!exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cambiar el estado a $nuevoEstado")),
      );
    }
  }

  void _viajeCompletado() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final hayPasajerosAceptados =
        solicitudes.any((p) => p["estado"] == "aceptada");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del recorrido"),
        actions: [
          TextButton(
            onPressed: () async {
              await _cambiarEstadoRecorrido('cancelado');
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            color: Colors.blue.shade100,
            child: const Center(child: Text("MAPA DE RUTA AQUÍ")),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade100,
            child: Text(
              "Solicitudes recibidas: ${solicitudes.length}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: solicitudes.length,
              itemBuilder: (context, index) {
                final s = solicitudes[index];
                if (s["estado"] == "rechazada") return const SizedBox.shrink();

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Solicitud #${s["id"]}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text("Punto de recogida: ${s["punto_recogida"]}"),
                            Text("Lugar de dejada: ${s["punto_dejada"]}"),
                            Text("Estado: ${s["estado"]}"),
                          ],
                        ),
                      ),
                      if (s["estado"] == "pendiente")
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final exito = await ApiService()
                                      .aceptarSolicitud(s["id"]);
                                  if (exito) {
                                    setState(() {
                                      solicitudes[index]["estado"] = "aceptada";
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Solicitud aceptada")),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Error al aceptar solicitud")),
                                    );
                                  }
                                },
                                child: Container(
                                  color: Colors.green,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  child: const Text("Aceptar",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final exito = await ApiService()
                                      .rechazarSolicitud(s["id"]);
                                  if (exito) {
                                    setState(() {
                                      solicitudes[index]["estado"] =
                                          "rechazada";
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("Solicitud rechazada")),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Error al rechazar solicitud")),
                                    );
                                  }
                                },
                                child: Container(
                                  color: Colors.red,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  alignment: Alignment.center,
                                  child: const Text("Rechazar",
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
                onPressed: () async {
                  final exito = await ApiService()
                      .cambiarEstadoRecorrido(widget.recorridoId, 'en_curso');
                  if (exito) {
                    setState(() {
                      viajeIniciado = true;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Error al iniciar viaje")),
                    );
                  }
                },
                child: const Text("Iniciar viaje"),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45)),
              ),
            ),
          if (viajeIniciado)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  final exito = await ApiService()
                      .cambiarEstadoRecorrido(widget.recorridoId, 'completado');
                  if (exito) {
                    _viajeCompletado();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Error al completar el viaje")),
                    );
                  }
                },
                child: const Text("Viaje completado"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
