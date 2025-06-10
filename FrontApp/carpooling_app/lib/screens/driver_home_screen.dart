import 'package:flutter/material.dart';
import 'driver_trip_detail_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  @override
  _DriverHomeScreenState createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final TextEditingController startController = TextEditingController();
  final TextEditingController endController = TextEditingController();

  TimeOfDay? selectedTime;

  void _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modo Conductor")),
      body: Stack(
        children: [
          // Simulación del mapa
          Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.blue.shade100,
            child: Center(
              child: Text(
                "MAPA AQUÍ",
                style: TextStyle(color: Colors.black45, fontSize: 20),
              ),
            ),
          ),

          // Formulario flotante
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
                boxShadow: [
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
                    controller: startController,
                    decoration: InputDecoration(
                      labelText: "Desde",
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: endController,
                    decoration: InputDecoration(
                      labelText: "Hasta",
                      prefixIcon: Icon(Icons.flag),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: _selectTime,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Hora de salida",
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedTime != null
                            ? selectedTime!.format(context)
                            : "Selecciona la hora",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final desde = startController.text.trim();
                      final hasta = endController.text.trim();
                      final hora = selectedTime?.format(context) ?? "";

                      if (desde.isEmpty || hasta.isEmpty || hora.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Completa todos los campos")),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverTripDetailScreen(),
                        ),
                      );
                    },

                    child: Text("Crear recorrido"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
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
