import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

const LOCATIONIQ_KEY = 'pk.d1aabacbcfacc94fe6c3e553c634498e';

class DriverTripDetailScreen extends StatefulWidget {
  final int recorridoId;

  const DriverTripDetailScreen({super.key, required this.recorridoId});

  @override
  State<DriverTripDetailScreen> createState() => _DriverTripDetailScreenState();
}

class _DriverTripDetailScreenState extends State<DriverTripDetailScreen> {
  Timer? ubicacionTimer;
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> solicitudes = [];
  List<LatLng> puntosRuta = [];
  List<LatLng> marcadores = [];
  bool viajeIniciado = false;
  Timer? pollingTimer;
  LatLng? ubicacionActual;

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();

    // 🔁 Polling de solicitudes y ruta
    pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _cargarSolicitudes();
      await _cargarRuta();
    });

    // 🚗 Enviar ubicación del conductor al backend
    ubicacionTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await ApiService().actualizarUbicacionConductor(
        widget.recorridoId,
        pos.latitude,
        pos.longitude,
      );
    });
  }

  @override
  void dispose() {
    pollingTimer?.cancel();
    ubicacionTimer?.cancel();
    super.dispose();
  }

  Future<void> _inicializarPantalla() async {
    await _obtenerUbicacionActual();
    await _cargarRuta();
    await _cargarSolicitudes();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final nuevaUbicacion = LatLng(pos.latitude, pos.longitude);
      setState(() {
        ubicacionActual = nuevaUbicacion;
      });

      // Esta línea centra el mapa con animación una vez obtenida la ubicación
      _mapController.move(nuevaUbicacion, 13);
    } catch (e) {
      print("Error obteniendo ubicación actual: $e");
    }
  }

  Future<void> _cargarRuta() async {
    try {
      final datos =
          await ApiService().obtenerDatosMapaRecorrido(widget.recorridoId);

      if (datos == null || datos['recorrido'] == null) {
        print("❌ Datos del recorrido inválidos");
        return;
      }

      final r = datos['recorrido'];
      final p = datos['pasajeros'] as List;

      List<LatLng> puntos = [];
      List<LatLng> marcadoresTemp = [];

      if (r['lat_origen'] != null && r['lon_origen'] != null) {
        final origen = LatLng(r['lat_origen'], r['lon_origen']);
        puntos.add(origen);
        marcadoresTemp.add(origen);
      }

      for (final pasajero in p) {
        if (pasajero['lat_recogida'] != null &&
            pasajero['lon_recogida'] != null) {
          final recogida =
              LatLng(pasajero['lat_recogida'], pasajero['lon_recogida']);
          puntos.add(recogida);
          marcadoresTemp.add(recogida);
        }
        if (pasajero['lat_dejada'] != null && pasajero['lon_dejada'] != null) {
          final dejada = LatLng(pasajero['lat_dejada'], pasajero['lon_dejada']);
          puntos.add(dejada);
          marcadoresTemp.add(dejada);
        }
      }

      if (r['lat_destino'] != null && r['lon_destino'] != null) {
        final destino = LatLng(r['lat_destino'], r['lon_destino']);
        puntos.add(destino);
        marcadoresTemp.add(destino);
      }

      if (puntos.length < 2) {
        print("❌ No hay suficientes puntos para calcular ruta");
        return;
      }

      final routeString =
          puntos.map((p) => "${p.longitude},${p.latitude}").join(';');
      final url =
          'https://us1.locationiq.com/v1/directions/driving/$routeString?key=$LOCATIONIQ_KEY&overview=full&geometries=geojson';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final coords =
            json.decode(response.body)['routes'][0]['geometry']['coordinates'];
        final nuevaRuta =
            coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        setState(() {
          puntosRuta = nuevaRuta;
          marcadores = marcadoresTemp;
        });
      } else {
        print("❌ Error en ruta LocationIQ: ${response.body}");
      }
    } catch (e) {
      print("❌ Excepción cargando ruta: $e");
    }
  }

  Future<void> _cargarSolicitudes() async {
    final nuevas =
        await ApiService().obtenerSolicitudesPorRecorrido(widget.recorridoId);
    setState(() {
      solicitudes = nuevas;
    });
  }

  Future<void> _cambiarEstadoRecorrido(String estado) async {
    final exito =
        await ApiService().cambiarEstadoRecorrido(widget.recorridoId, estado);
    if (!exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cambiar estado a $estado")),
      );
    }
  }

  void _viajeCompletado() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final hayPasajerosAceptados =
        solicitudes.any((s) => s['estado'] == 'aceptada');

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
          SizedBox(
            height: 240,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: ubicacionActual ?? LatLng(4.6097, -74.0817),
                zoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.carpooling_app',
                ),
                if (puntosRuta.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: puntosRuta,
                        color: Colors.blue,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    ...marcadores.map((p) => Marker(
                          point: p,
                          width: 30,
                          height: 30,
                          builder: (_) => const Icon(Icons.location_on,
                              color: Colors.black),
                        )),
                    if (ubicacionActual != null)
                      Marker(
                        point: ubicacionActual!,
                        width: 30,
                        height: 30,
                        builder: (_) => const Icon(Icons.directions_car,
                            color: Colors.blue),
                      ),
                  ],
                ),
              ],
            ),
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
                if (s['estado'] == 'rechazada') return const SizedBox.shrink();
                return ListTile(
                  title: Text("Solicitud #${s['id']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Recogida: ${s['punto_recogida']}"),
                      Text("Dejada: ${s['punto_dejada']}"),
                      Text("Estado: ${s['estado']}")
                    ],
                  ),
                  trailing: s['estado'] == 'pendiente'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                final exito = await ApiService()
                                    .aceptarSolicitud(s['id']);
                                if (exito)
                                  setState(() => s['estado'] = 'aceptada');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                final exito = await ApiService()
                                    .rechazarSolicitud(s['id']);
                                if (exito)
                                  setState(() => s['estado'] = 'rechazada');
                              },
                            )
                          ],
                        )
                      : null,
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
                  if (exito) setState(() => viajeIniciado = true);
                },
                child: const Text("Iniciar viaje"),
              ),
            ),
          if (viajeIniciado)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  final exito = await ApiService()
                      .cambiarEstadoRecorrido(widget.recorridoId, 'completado');
                  if (exito) _viajeCompletado();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Viaje completado"),
              ),
            ),
        ],
      ),
    );
  }
}
