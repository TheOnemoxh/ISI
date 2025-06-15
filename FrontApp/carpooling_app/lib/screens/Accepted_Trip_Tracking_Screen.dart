import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

const LOCATIONIQ_KEY = 'pk.d1aabacbcfacc94fe6c3e553c634498e';

class AcceptedTripTrackingScreen extends StatefulWidget {
  final int recorridoId;

  const AcceptedTripTrackingScreen({super.key, required this.recorridoId});

  @override
  State<AcceptedTripTrackingScreen> createState() =>
      _AcceptedTripTrackingScreenState();
}

class _AcceptedTripTrackingScreenState
    extends State<AcceptedTripTrackingScreen> {
  final MapController _mapController = MapController();
  LatLng? ubicacionActual;
  List<LatLng> puntosRuta = [];
  List<LatLng> marcadores = [];

  bool recogido = false;
  bool viajeCompletado = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _obtenerUbicacionActual();
    await _cargarRuta();
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final nuevaUbicacion = LatLng(pos.latitude, pos.longitude);
      setState(() {
        ubicacionActual = nuevaUbicacion;
      });
      _mapController.move(nuevaUbicacion, 15);
    } catch (e) {
      print("❌ Error obteniendo ubicación actual: $e");
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

  void _completarViaje() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🗺 Mapa a pantalla completa
          FlutterMap(
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
                markers: marcadores
                    .map((p) => Marker(
                          point: p,
                          width: 30,
                          height: 30,
                          builder: (_) =>
                              const Icon(Icons.location_on, color: Colors.red),
                        ))
                    .toList(),
              ),
            ],
          ),

          // 🔘 Botones flotantes en la parte inferior
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                if (!recogido)
                  ElevatedButton(
                    onPressed: () => setState(() => recogido = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text("Presiona cuando ya te recogieron"),
                  ),
                if (recogido && !viajeCompletado)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => viajeCompletado = true);
                        _completarViaje();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("Viaje completado"),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
