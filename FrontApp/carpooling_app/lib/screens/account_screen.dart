import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'edit_account_screen.dart';
import 'register_vehicle_screen.dart';

class AccountScreen extends StatefulWidget {
  final bool esConductor;
  final VoidCallback onCambiarModo;

  const AccountScreen({
    required this.esConductor,
    required this.onCambiarModo,
    super.key,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String email = '';
  String nombres = '';
  String apellidos = '';
  String telefono = '';
  bool cargando = true;

  bool esConductorBackend = false;
  bool tieneVehiculoBackend = false;

  @override
  void initState() {
    super.initState();
    inicializarEstado();
  }

  Future<void> inicializarEstado() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => cargando = false);
      return;
    }

    try {
      final usuario = await ApiService().getUsuarioActual(token);
      final tieneVehiculo = await ApiService().tieneVehiculoRegistrado();

      if (usuario != null) {
        setState(() {
          email = usuario['correo'] ?? '';
          nombres = usuario['nombres'] ?? '';
          apellidos = usuario['apellidos'] ?? '';
          telefono = usuario['celular'] ?? '';
          esConductorBackend = usuario['es_conductor'] ?? false;
          tieneVehiculoBackend = tieneVehiculo;
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
      }
    } catch (e) {
      print("❌ Error al cargar datos: $e");
      setState(() => cargando = false);
    }
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> manejarCambioModo() async {
    if (esConductorBackend || tieneVehiculoBackend) {
      // ✅ Ya es conductor o ya tiene vehículo → cambiar de modo
      widget.onCambiarModo();
    } else {
      // ❌ No es conductor ni tiene vehículo → redirigir a pantalla de registro
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterVehicleScreen(
            onRegistroCompletado: () async {
              await inicializarEstado(); // Recargar estado
              widget.onCambiarModo(); // Activar modo conductor
              Navigator.pop(context); // Cerrar pantalla
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreModo = widget.esConductor ? "Modo Conductor" : "Modo Pasajero";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final recargar = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditAccountScreen(
                    email: email,
                    nombres: nombres,
                    apellidos: apellidos,
                    telefono: telefono,
                  ),
                ),
              );
              if (recargar == true) {
                await inicializarEstado();
              }
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoItem(title: "Correo", value: email),
                  InfoItem(title: "Nombres", value: nombres),
                  InfoItem(title: "Apellidos", value: apellidos),
                  InfoItem(title: "Teléfono", value: telefono),
                  const SizedBox(height: 30),
                  const Divider(),
                  const Text("Modo actual:", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        widget.esConductor
                            ? Icons.directions_car
                            : Icons.person,
                        color: Colors.indigo,
                      ),
                      const SizedBox(width: 10),
                      Text(nombreModo, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: manejarCambioModo,
                      child: Text(
                        "Cambiar a ${widget.esConductor ? 'Modo Pasajero' : 'Modo Conductor'}",
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: cerrarSesion,
                      icon: const Icon(Icons.logout),
                      label: const Text("Cerrar sesión"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class InfoItem extends StatelessWidget {
  final String title;
  final String value;

  const InfoItem({required this.title, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
          const Divider(),
        ],
      ),
    );
  }
}
