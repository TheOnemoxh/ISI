import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditAccountScreen extends StatefulWidget {
  final String email;
  final String nombres;
  final String apellidos;
  final String telefono;

  const EditAccountScreen({
    super.key,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
  });

  @override
  State<EditAccountScreen> createState() => _EditAccountScreenState();
}

class _EditAccountScreenState extends State<EditAccountScreen> {
  late final TextEditingController emailController;
  late final TextEditingController nombresController;
  late final TextEditingController apellidosController;
  late final TextEditingController telefonoController;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: widget.email);
    nombresController = TextEditingController(text: widget.nombres);
    apellidosController = TextEditingController(text: widget.apellidos);
    telefonoController = TextEditingController(text: widget.telefono);
  }

  @override
  void dispose() {
    emailController.dispose();
    nombresController.dispose();
    apellidosController.dispose();
    telefonoController.dispose();
    super.dispose();
  }

  Future<void> confirmarCambios() async {
    setState(() => cargando = true);

    final exito = await ApiService().editarPerfil(
      nombres: nombresController.text.trim(),
      apellidos: apellidosController.text.trim(),
      celular: telefonoController.text.trim(),
    );

    setState(() => cargando = false);

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cambios guardados correctamente")),
      );
      Navigator.pop(context, true); // <- 🔁 Indica que se debe recargar
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudieron guardar los cambios")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Cuenta"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              readOnly: true,
              decoration:
                  const InputDecoration(labelText: "Correo (no editable)"),
            ),
            TextField(
              controller: nombresController,
              decoration: const InputDecoration(labelText: "Nombres"),
            ),
            TextField(
              controller: apellidosController,
              decoration: const InputDecoration(labelText: "Apellidos"),
            ),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: "Teléfono"),
              keyboardType: TextInputType.phone,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: cargando ? null : confirmarCambios,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: cargando
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text("Guardando..."),
                      ],
                    )
                  : const Text("Confirmar cambios"),
            )
          ],
        ),
      ),
    );
  }
}
