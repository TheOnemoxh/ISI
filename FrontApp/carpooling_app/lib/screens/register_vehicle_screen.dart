import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterVehicleScreen extends StatefulWidget {
  final VoidCallback onRegistroCompletado;

  const RegisterVehicleScreen({required this.onRegistroCompletado, super.key});

  @override
  State<RegisterVehicleScreen> createState() => _RegisterVehicleScreenState();
}

class _RegisterVehicleScreenState extends State<RegisterVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final marcaController = TextEditingController();
  final modeloController = TextEditingController();
  final anioController = TextEditingController();
  final colorController = TextEditingController();
  final placaController = TextEditingController();
  final asientosController = TextEditingController();

  bool cargando = false;

  Future<void> _registrarVehiculo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);

    final data = {
      "marca": marcaController.text.trim(),
      "modelo": modeloController.text.trim(),
      "anio": int.tryParse(anioController.text.trim()) ?? 2000,
      "color": colorController.text.trim(),
      "placa": placaController.text.trim(),
      "numero_asientos": int.tryParse(asientosController.text.trim()) ?? 4,
    };

    final exito = await ApiService().registrarVehiculo(data);

    setState(() => cargando = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vehículo registrado correctamente")),
      );
      widget.onRegistroCompletado();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo registrar el vehículo")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Vehículo")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField("Marca", marcaController),
              buildTextField("Modelo", modeloController),
              buildTextField("Año del modelo", anioController,
                  keyboardType: TextInputType.number),
              buildTextField("Color", colorController),
              buildTextField("Placa", placaController),
              buildTextField("Número de asientos", asientosController,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: cargando ? null : _registrarVehiculo,
                child: cargando
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Registrar vehículo"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Este campo es obligatorio";
          }
          return null;
        },
      ),
    );
  }
}
