import 'package:flutter/material.dart';
import 'travel_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController pickupController = TextEditingController();
  final TextEditingController destinationController = TextEditingController();

  void obtenerDatos() {
    final origen = pickupController.text.trim();
    final destino = destinationController.text.trim();

    if (origen.isEmpty || destino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa ambos campos")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TravelResultsScreen(
          puntoRecogida: origen,
          puntoDejada: destino,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeView(
      pickupController: pickupController,
      destinationController: destinationController,
      onBuscarViaje: obtenerDatos,
    );
  }
}

class HomeView extends StatelessWidget {
  final TextEditingController pickupController;
  final TextEditingController destinationController;
  final VoidCallback onBuscarViaje;

  const HomeView({
    required this.pickupController,
    required this.destinationController,
    required this.onBuscarViaje,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.blue.shade100,
          child: const Center(
            child: Text(
              "MAPA AQUÍ",
              style: TextStyle(color: Colors.black45, fontSize: 20),
            ),
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
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pickupController,
                  decoration: InputDecoration(
                    hintText: '¿Dónde te recogemos?',
                    prefixIcon:
                        const Icon(Icons.my_location, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: destinationController,
                  decoration: InputDecoration(
                    hintText: "¿A dónde quieres ir?",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onBuscarViaje,
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
