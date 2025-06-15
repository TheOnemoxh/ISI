import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'travel_results_screen.dart';

const LOCATIONIQ_KEY = 'pk.d1aabacbcfacc94fe6c3e553c634498e';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  String? puntoRecogida;
  double? latRecogida;
  double? lonRecogida;

  String? puntoDejada;
  double? latDejada;
  double? lonDejada;

  Position? ubicacionActual;
  final MapController _mapController = MapController();
  List<LatLng> ruta = [];

  @override
  void initState() {
    super.initState();
    obtenerUbicacionActual();
  }

  Future<void> obtenerUbicacionActual() async {
    try {
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) {
        throw Exception('Ubicación deshabilitada');
      }

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado');
        }
      }

      final ubicacion = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        ubicacionActual = ubicacion;
        _mapController.move(
          LatLng(ubicacion.latitude, ubicacion.longitude),
          13,
        );
      });
    } catch (e) {
      print("❌ Error obteniendo ubicación: $e");
    }
  }

  Future<List<dynamic>> buscarSugerencias(String query) async {
    if (query.isEmpty || ubicacionActual == null) return [];

    final lat = ubicacionActual!.latitude;
    final lon = ubicacionActual!.longitude;

    final url =
        'https://us1.locationiq.com/v1/autocomplete.php?key=$LOCATIONIQ_KEY&q=$query&format=json&limit=5&viewbox=${lon - 0.05},${lat + 0.05},${lon + 0.05},${lat - 0.05}&bounded=1';

    try {
      final response = await http.get(Uri.parse(url));
      print("🔍 URL: $url");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("❌ Error de respuesta: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error en búsqueda: $e");
    }

    return [];
  }

  Future<void> obtenerRuta() async {
    if (latRecogida == null ||
        lonRecogida == null ||
        latDejada == null ||
        lonDejada == null) return;

    final url =
        'https://us1.locationiq.com/v1/directions/driving/$lonRecogida,$latRecogida;$lonDejada,$latDejada?key=$LOCATIONIQ_KEY&overview=full&geometries=geojson';

    print("📡 Llamando a LocationIQ: $url");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          ruta =
              coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        });
      } else {
        print("❌ Error al obtener ruta: ${response.body}");
      }
    } catch (e) {
      print("❌ Error conectando con LocationIQ: $e");
    }
  }

  void obtenerDatos() {
    if (puntoRecogida == null || puntoDejada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa ambos campos")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TravelResultsScreen(
          puntoRecogida: puntoRecogida!,
          puntoDejada: puntoDejada!,
          latRecogida: latRecogida!,
          lonRecogida: lonRecogida!,
          latDejada: latDejada!,
          lonDejada: lonDejada!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: ubicacionActual != null
                  ? LatLng(
                      ubicacionActual!.latitude, ubicacionActual!.longitude)
                  : LatLng(4.6097, -74.0817),
              zoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.carpooling_app',
              ),
              if (ruta.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: ruta,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (latRecogida != null && lonRecogida != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(latRecogida!, lonRecogida!),
                      builder: (ctx) =>
                          const Icon(Icons.location_on, color: Colors.green),
                    ),
                  if (latDejada != null && lonDejada != null)
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(latDejada!, lonDejada!),
                      builder: (ctx) =>
                          const Icon(Icons.location_on, color: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: pickupController,
                    decoration: InputDecoration(
                      hintText: '¿Dónde te recogemos?',
                      prefixIcon:
                          const Icon(Icons.my_location, color: Colors.green),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  suggestionsCallback: buscarSugerencias,
                  itemBuilder: (context, dynamic suggestion) => ListTile(
                    title: Text(suggestion['display_name']),
                  ),
                  onSuggestionSelected: (dynamic suggestion) {
                    pickupController.text = suggestion['display_name'];
                    puntoRecogida = suggestion['display_name'];
                    latRecogida = double.tryParse(suggestion['lat']);
                    lonRecogida = double.tryParse(suggestion['lon']);
                    setState(() {
                      ruta.clear();
                    });
                    obtenerRuta();
                  },
                ),
                const SizedBox(height: 10),
                TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: destinationController,
                    decoration: InputDecoration(
                      hintText: '¿A dónde quieres ir?',
                      prefixIcon: const Icon(Icons.place, color: Colors.blue),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  suggestionsCallback: buscarSugerencias,
                  itemBuilder: (context, dynamic suggestion) => ListTile(
                    title: Text(suggestion['display_name']),
                  ),
                  onSuggestionSelected: (dynamic suggestion) {
                    destinationController.text = suggestion['display_name'];
                    puntoDejada = suggestion['display_name'];
                    latDejada = double.tryParse(suggestion['lat']);
                    lonDejada = double.tryParse(suggestion['lon']);
                    setState(() {
                      ruta.clear();
                    });
                    obtenerRuta();
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: obtenerDatos,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text("Buscar viaje"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
