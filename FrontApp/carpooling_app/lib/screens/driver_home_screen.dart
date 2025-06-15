import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'driver_trip_detail_screen.dart';

const LOCATIONIQ_KEY = 'pk.d1aabacbcfacc94fe6c3e553c634498e';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();
  TimeOfDay? selectedTime;
  bool cargando = false;

  String? puntoInicio;
  String? puntoFin;
  double? latInicio;
  double? lonInicio;
  double? latFin;
  double? lonFin;

  Position? _ubicacionActual;
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
      if (!servicioHabilitado) return;

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _ubicacionActual = pos;
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          13,
        );
      });
    } catch (e) {
      print("Error al obtener ubicación: $e");
    }
  }

  Future<List<dynamic>> buscarSugerencias(String query) async {
    if (_ubicacionActual == null || query.isEmpty) return [];

    final lat = _ubicacionActual!.latitude;
    final lon = _ubicacionActual!.longitude;

    try {
      final url =
          'https://us1.locationiq.com/v1/autocomplete.php?key=$LOCATIONIQ_KEY&q=$query&format=json&limit=5&viewbox=${lon - 0.2},${lat + 0.2},${lon + 0.2},${lat - 0.2}&bounded=1';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error en buscarSugerencias: $e");
    }
    return [];
  }

  Future<void> obtenerRuta() async {
    if (latInicio == null ||
        lonInicio == null ||
        latFin == null ||
        lonFin == null) {
      print(
          "Coordenadas incompletas: latInicio=$latInicio, lonInicio=$lonInicio, latFin=$latFin, lonFin=$lonFin");
      return;
    }

    final url =
        'https://us1.locationiq.com/v1/directions/driving/$lonInicio,$latInicio;$lonFin,$latFin?key=$LOCATIONIQ_KEY&overview=full&geometries=geojson';

    print("Llamando a: $url");

    try {
      final response = await http.get(Uri.parse(url));
      print("Código de respuesta: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coordinates =
            data['routes'][0]['geometry']['coordinates'] as List;
        setState(() {
          ruta =
              coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        });
      } else {
        print("Respuesta de error: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al obtener la ruta")),
        );
      }
    } catch (e) {
      print("Error de conexión con LocationIQ: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al conectar con LocationIQ")),
      );
    }
  }

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  Future<void> _crearRecorrido() async {
    if (puntoInicio == null ||
        puntoFin == null ||
        latInicio == null ||
        latFin == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => cargando = true);

    final now = DateTime.now();
    final salida = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final vehiculoInfo = await ApiService().obtenerVehiculo();
    final asientos = vehiculoInfo?['numero_asientos'] as int? ?? 1;
    final precio = 10000.0;

    final recorridoIdCreado = await ApiService().crearRecorrido(
      origen: puntoInicio!,
      destino: puntoFin!,
      fechaHoraSalida: salida.toIso8601String(),
      precioTotal: precio,
      asientosDisponibles: asientos,
      latOrigen: latInicio!,
      lonOrigen: lonInicio!,
      latDestino: latFin!,
      lonDestino: lonFin!,
    );

    setState(() => cargando = false);

    if (recorridoIdCreado != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DriverTripDetailScreen(recorridoId: recorridoIdCreado),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al crear recorrido")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Modo Conductor")),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _ubicacionActual != null
                    ? LatLng(
                        _ubicacionActual!.latitude, _ubicacionActual!.longitude)
                    : LatLng(4.6097, -74.0817), // Bogotá por defecto
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
                    if (latInicio != null && lonInicio != null)
                      Marker(
                        width: 40,
                        height: 40,
                        point: LatLng(latInicio!, lonInicio!),
                        builder: (ctx) =>
                            const Icon(Icons.location_on, color: Colors.green),
                      ),
                    if (latFin != null && lonFin != null)
                      Marker(
                        width: 40,
                        height: 40,
                        point: LatLng(latFin!, lonFin!),
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
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TypeAheadFormField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: startController,
                      decoration: const InputDecoration(
                        labelText: "Desde",
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    suggestionsCallback: buscarSugerencias,
                    itemBuilder: (context, dynamic suggestion) => ListTile(
                      title: Text(suggestion['display_name']),
                    ),
                    onSuggestionSelected: (dynamic suggestion) {
                      startController.text = suggestion['display_name'];
                      puntoInicio = suggestion['display_name'];
                      latInicio = double.tryParse(suggestion['lat']);
                      lonInicio = double.tryParse(suggestion['lon']);
                      setState(() {
                        ruta.clear();
                      });
                      obtenerRuta();
                    },
                  ),
                  const SizedBox(height: 10),
                  TypeAheadFormField(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: endController,
                      decoration: const InputDecoration(
                        labelText: "Hasta",
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    suggestionsCallback: buscarSugerencias,
                    itemBuilder: (context, dynamic suggestion) => ListTile(
                      title: Text(suggestion['display_name']),
                    ),
                    onSuggestionSelected: (dynamic suggestion) {
                      endController.text = suggestion['display_name'];
                      puntoFin = suggestion['display_name'];
                      latFin = double.tryParse(suggestion['lat']);
                      lonFin = double.tryParse(suggestion['lon']);
                      setState(() {
                        ruta.clear();
                      });
                      obtenerRuta();
                    },
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Hora de salida",
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedTime?.format(context) ?? "Selecciona la hora",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: cargando ? null : _crearRecorrido,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Crear recorrido"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
