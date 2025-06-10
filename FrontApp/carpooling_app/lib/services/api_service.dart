import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "http://192.168.1.17:8000/api";

  /// Iniciar sesión
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login/');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"correo": email, "password": password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
          "❌ Error al iniciar sesión: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  /// Registrar nuevo usuario
  Future<bool> register(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/registro/');
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print(
          "❌ Error al registrar usuario: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  /// Obtener datos del usuario autenticado (usando token existente)
  Future<Map<String, dynamic>?> getUsuarioActual(String token) async {
    final url = Uri.parse('$baseUrl/usuario/');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
          "❌ Error al obtener usuario: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  /// Obtener datos del usuario autenticado (desde SharedPreferences)
  Future<Map<String, dynamic>?> getUsuarioActualConToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;
    return await getUsuarioActual(token);
  }

  /// Editar perfil del usuario autenticado
  Future<bool> editarPerfil({
    required String nombres,
    required String apellidos,
    required String celular,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/usuario/');
    final response = await http.patch(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "nombres": nombres,
        "apellidos": apellidos,
        "celular": celular,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      print(
          "❌ Error al editar perfil: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  /// Registrar vehículo del conductor
  Future<bool> registrarVehiculo(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/vehiculo/');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      print(
          "❌ Error al registrar vehículo: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  /// Obtener los datos del vehículo asociado al usuario
  Future<Map<String, dynamic>?> obtenerVehiculo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/vehiculo/');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
          "❌ Error al obtener vehículo: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  /// Verificar si el usuario tiene un vehículo registrado
  Future<bool> tieneVehiculoRegistrado() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/vehiculo/');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 404) {
      return false;
    } else {
      print(
          "❌ Error al consultar vehículo: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  /// Enviar solicitud de viaje
  Future<bool> enviarSolicitudDeViaje({
    required int recorridoId,
    required String puntoRecogida,
    required String puntoDejada,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/solicitud/');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "recorrido": recorridoId,
        "punto_recogida": puntoRecogida,
        "punto_dejada": puntoDejada,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print(
          "❌ Error al enviar solicitud de viaje: ${response.statusCode} - ${response.body}");
      return false;
    }
  }

  /// Obtener recorridos con estado pendiente
  Future<List<Map<String, dynamic>>> obtenerRecorridosPendientes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return [];

    final url = Uri.parse('$baseUrl/recorridos/');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .where((recorrido) => recorrido["estado"] == "pendiente")
            .toList()
            .cast<Map<String, dynamic>>();
      }
    }

    print(
        "❌ Error al obtener recorridos: ${response.statusCode} - ${response.body}");
    return [];
  }
}
