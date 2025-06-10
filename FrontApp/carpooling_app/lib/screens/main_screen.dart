import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'driver_home_screen.dart';
import 'account_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  bool esConductor = false;
  bool vehiculoRegistrado = false;
  bool mostrarRegistroVehiculo = false;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    verificarEstadoUsuario();
  }

  Future<void> verificarEstadoUsuario() async {
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
        final esConductorActual = usuario['es_conductor'] ?? false;

        setState(() {
          esConductor = esConductorActual;
          vehiculoRegistrado = tieneVehiculo;
          mostrarRegistroVehiculo = !esConductorActual && !tieneVehiculo;
          cargando = false;
        });
      } else {
        setState(() => cargando = false);
      }
    } catch (e) {
      print("❌ Error en MainScreen al verificar estado: $e");
      setState(() => cargando = false);
    }
  }

  void cambiarModo() {
    setState(() {
      esConductor = !esConductor;
    });
  }

  void completarRegistroVehiculo() {
    setState(() {
      vehiculoRegistrado = true;
      mostrarRegistroVehiculo = false;
      esConductor = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      esConductor ? DriverHomeScreen() : HomeScreen(),
      const Center(child: Text("Historial")),
      AccountScreen(
        esConductor: esConductor,
        onCambiarModo: cambiarModo,
      ),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Principal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'Historial'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cuenta'),
        ],
      ),
    );
  }
}
