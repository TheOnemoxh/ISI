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

  /// Obtener datos del usuario autenticado (usando token)
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

  /// Obtener usuario actual desde SharedPreferences
  Future<Map<String, dynamic>?> getUsuarioActualConToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;
    return await getUsuarioActual(token);
  }

  /// Editar perfil
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

    return response.statusCode == 200;
  }

  /// Registrar vehículo
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

    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Obtener vehículo del usuario
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

  /// Verificar si el usuario tiene vehículo
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

    return response.statusCode == 200;
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

    return response.statusCode == 200 || response.statusCode == 201;
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
            .cast<Map<String, dynamic>>()
            .toList();
      }
    }

    print(
        "❌ Error al obtener recorridos: ${response.statusCode} - ${response.body}");
    return [];
  }

  /// Obtener todos los recorridos con detalles (conductor y vehículo)
  Future<List<Map<String, dynamic>>> obtenerRecorridosConDetalles() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return [];

    final url = Uri.parse('$baseUrl/recorridos/detalles/');
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
        return data.cast<Map<String, dynamic>>();
      }
    }

    print(
        "❌ Error al obtener recorridos con detalles: ${response.statusCode} - ${response.body}");
    return [];
  }

  /// ✅ NUEVO: Obtener recorrido por ID con detalles
  Future<Map<String, dynamic>?> obtenerDetalleRecorridoPorId(
      int recorridoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final url = Uri.parse('$baseUrl/recorridos/$recorridoId/detalles/');
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    print(
        "❌ Error al obtener detalle del recorrido: ${response.statusCode} - ${response.body}");
    return null;
  }

  /// Crear un nuevo recorrido
  Future<bool> crearRecorrido({
    required String origen,
    required String destino,
    required String fechaHoraSalida,
    required double precioTotal,
    required int asientosDisponibles,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/recorridos/');
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "origen": origen,
        "destino": destino,
        "fecha_hora_salida": fechaHoraSalida,
        "precio_total": precioTotal.toStringAsFixed(2),
        "asientos_disponibles": asientosDisponibles,
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }
}
