import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

const LOCATIONIQ_API_KEY = 'pk.d1aabacbcfacc94fe6c3e553c634498e';

class MapaScreen extends StatefulWidget {
  final double origenLat;
  final double origenLon;
  final double destinoLat;
  final double destinoLon;

  const MapaScreen({
    super.key,
    required this.origenLat,
    required this.origenLon,
    required this.destinoLat,
    required this.destinoLon,
  });

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  List<LatLng> ruta = [];
  bool cargandoRuta = true;

  @override
  void initState() {
    super.initState();
    obtenerRuta();
  }

  Future<void> obtenerRuta() async {
    final url =
        'https://routes.locationiq.com/v1/route/driving/${widget.origenLon},${widget.origenLat};${widget.destinoLon},${widget.destinoLat}?key=$LOCATIONIQ_API_KEY&overview=full&geometries=geojson';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
      setState(() {
        ruta = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        cargandoRuta = false;
      });
    } else {
      setState(() => cargandoRuta = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al obtener la ruta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ruta del Recorrido")),
      body: cargandoRuta
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: MapOptions(
                center: LatLng(widget.origenLat, widget.origenLon),
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://tiles.locationiq.com/v3/$LOCATIONIQ_API_KEY/terrain/{z}/{x}/{y}.png",
                  userAgentPackageName: 'com.example.carpooling_app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: ruta,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(widget.origenLat, widget.origenLon),
                      builder: (context) => const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(widget.destinoLat, widget.destinoLon),
                      builder: (context) => const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
