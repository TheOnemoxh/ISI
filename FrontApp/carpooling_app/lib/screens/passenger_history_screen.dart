import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class PassengerHistoryScreen extends StatefulWidget {
  const PassengerHistoryScreen({super.key});

  @override
  State<PassengerHistoryScreen> createState() => _PassengerHistoryScreenState();
}

class _PassengerHistoryScreenState extends State<PassengerHistoryScreen> {
  List<Map<String, dynamic>> historial = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
  }

  Future<void> _cargarHistorial() async {
    final response = await http.get(
      Uri.parse("http://192.168.1.17:8000/api/historial/pasajero/"),
      headers: await ApiService().getHeaders(), // Usa tu método de headers
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        historial =
            List<Map<String, dynamic>>.from(data.reversed); // orden descendente
        cargando = false;
      });
    } else {
      print("❌ Error cargando historial: ${response.body}");
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de viajes")),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : historial.isEmpty
              ? const Center(child: Text("No hay viajes registrados."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final item = historial[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        title: Text(
                          "${item['recorrido_origen']} → ${item['recorrido_destino']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Fecha: ${item['fecha']}"),
                            Text("Estado: ${item['estado']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
