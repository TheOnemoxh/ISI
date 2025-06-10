import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'driver_trip_detail_screen.dart';

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

  void _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  Future<void> _crearRecorrido() async {
    final origen = startController.text.trim();
    final destino = endController.text.trim();
    if (origen.isEmpty || destino.isEmpty || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => cargando = true);

    // Construir la fecha/hora de salida
    final now = DateTime.now();
    final salida = DateTime(
      now.year,
      now.month,
      now.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // Obtener datos del vehículo (para asientos)
    final vehiculoInfo = await ApiService().obtenerVehiculo();
    final asientos = vehiculoInfo?['numero_asientos'] as int? ?? 1;

    // Precio provisional (más adelante calculado con distancia)
    final precio = 10000.0;

    // Llamar al backend para crear el recorrido
    final exito = await ApiService().crearRecorrido(
      origen: origen,
      destino: destino,
      fechaHoraSalida: salida.toIso8601String(),
      precioTotal: precio,
      asientosDisponibles: asientos,
    );

    setState(() => cargando = false);

    if (exito) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DriverTripDetailScreen()),
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
          // Mapa simulado
          Container(
            color: Colors.blue.shade100,
            child: const Center(
              child: Text("MAPA AQUÍ",
                  style: TextStyle(color: Colors.black45, fontSize: 20)),
            ),
          ),
          // Formulario flotante
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
                  TextField(
                    controller: startController,
                    decoration: const InputDecoration(
                      labelText: "Desde",
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: endController,
                    decoration: const InputDecoration(
                      labelText: "Hasta",
                      prefixIcon: Icon(Icons.flag),
                      border: OutlineInputBorder(),
                    ),
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
