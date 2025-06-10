import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService apiService = ApiService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRepeatPassword = true;
  String selectedCountryCode = "+57";

  Future<void> guardarSesionActiva() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sesionIniciada', true);
  }

  Future<void> _registrarUsuario() async {
    if (passwordController.text != repeatPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    final data = {
      "correo": emailController.text.trim(),
      "nombres": firstNameController.text.trim(),
      "apellidos": lastNameController.text.trim(),
      "celular": selectedCountryCode + phoneController.text.trim(),
      "password": passwordController.text,
      "es_conductor": false, // Siempre será false
    };

    final exito = await apiService.register(data);

    if (exito) {
      await guardarSesionActiva();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo registrar el usuario")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Correo"),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(hintText: 'email@example.com'),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              Text("Nombres"),
              TextFormField(
                controller: firstNameController,
                decoration: InputDecoration(hintText: 'Ruben David'),
              ),
              SizedBox(height: 10),
              Text("Apellidos"),
              TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(hintText: 'Gonzalez Agamez'),
              ),
              SizedBox(height: 10),
              Text("Número de celular"),
              Row(
                children: [
                  DropdownButton<String>(
                    value: selectedCountryCode,
                    onChanged: (newValue) {
                      setState(() {
                        selectedCountryCode = newValue!;
                      });
                    },
                    items: ['+57', '+1', '+52', '+54'].map((code) {
                      return DropdownMenuItem(value: code, child: Text(code));
                    }).toList(),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(hintText: '321 456 7890'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text("Contraseña"),
              TextFormField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text("Repetir contraseña"),
              TextFormField(
                controller: repeatPasswordController,
                obscureText: _obscureRepeatPassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureRepeatPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureRepeatPassword = !_obscureRepeatPassword;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registrarUsuario,
                child: Text("Registrarse"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
