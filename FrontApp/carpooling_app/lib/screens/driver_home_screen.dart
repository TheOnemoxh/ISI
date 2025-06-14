import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

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
      });
    } catch (_) {}
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
    } catch (_) {}
    return [];
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
          Container(
            color: Colors.blue.shade100,
            child: const Center(
              child: Text("MAPA AQUÍ",
                  style: TextStyle(color: Colors.black45, fontSize: 20)),
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
