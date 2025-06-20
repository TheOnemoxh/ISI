import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'travel_detail_screen.dart';

class TravelResultsScreen extends StatefulWidget {
  final String puntoRecogida;
  final String puntoDejada;
  final double latRecogida;
  final double lonRecogida;
  final double latDejada;
  final double lonDejada;

  const TravelResultsScreen({
    super.key,
    required this.puntoRecogida,
    required this.puntoDejada,
    required this.latRecogida,
    required this.lonRecogida,
    required this.latDejada,
    required this.lonDejada,
  });

  @override
  State<TravelResultsScreen> createState() => _TravelResultsScreenState();
}

class _TravelResultsScreenState extends State<TravelResultsScreen> {
  List<Map<String, dynamic>> viajes = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarViajesDisponibles();
  }

  Future<void> cargarViajesDisponibles() async {
    try {
      final data = await ApiService().obtenerRecorridosPendientes();
      setState(() {
        viajes = data;
        cargando = false;
      });
    } catch (e) {
      print("❌ Error al cargar viajes: $e");
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Viajes disponibles")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : viajes.isEmpty
              ? const Center(child: Text("No hay viajes disponibles"))
              : ListView.builder(
                  itemCount: viajes.length,
                  itemBuilder: (context, index) {
                    final viaje = viajes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        leading: const Icon(Icons.directions_car,
                            color: Colors.indigo),
                        title: Text("Desde: ${viaje["origen"]}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Hasta: ${viaje["destino"]}"),
                            Text("Fecha: ${viaje["fecha_hora_salida"]}"),
                            Builder(builder: (context) {
                              double precioTotal = double.tryParse(
                                      viaje["precio_total"].toString()) ??
                                  0;
                              double precioPorPasajero = precioTotal / 4;
                              return Text(
                                  "Precio por pasajero: COP ${precioPorPasajero.toStringAsFixed(2)}");
                            }),
                            Text(
                                "Asientos disponibles: ${viaje["asientos_disponibles"]}"),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TravelDetailScreen(
                                recorridoId: viaje["id"],
                                puntoRecogida: widget.puntoRecogida,
                                puntoDejada: widget.puntoDejada,
                                latRecogida: widget.latRecogida,
                                lonRecogida: widget.lonRecogida,
                                latDejada: widget.latDejada,
                                lonDejada: widget.lonDejada,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
