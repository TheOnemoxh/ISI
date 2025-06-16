import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ApiService {
  final String baseUrl = "http://192.168.1.17:8000/api";

  /// Geocodificar dirección con LocationIQ
  Future<Map<String, double>?> geocodificarDireccion(String direccion) async {
    const apiKey = 'pk.d1aabacbcfacc94fe6c3e553c634498e';
    final url =
        'https://us1.locationiq.com/v1/search.php?key=$apiKey&q=$direccion&format=json';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final resultados = jsonDecode(response.body);
        if (resultados is List && resultados.isNotEmpty) {
          final item = resultados.first;
          final lat = double.tryParse(item['lat'] ?? '');
          final lon = double.tryParse(item['lon'] ?? '');
          if (lat != null && lon != null) {
            return {"lat": lat, "lon": lon};
          }
        }
      }
    } catch (e) {
      print("❌ Error geocodificando dirección: $e");
    }
    return null;
  }

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

    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// Obtener datos del usuario autenticado
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

  Future<Map<String, dynamic>?> getUsuarioActualConToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;
    return await getUsuarioActual(token);
  }

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

  Future<bool> enviarSolicitudDeViaje({
    required int recorridoId,
    required String puntoRecogida,
    required String puntoDejada,
    required double latRecogida,
    required double lonRecogida,
    required double latDejada,
    required double lonDejada,
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
        "lat_recogida": latRecogida,
        "lon_recogida": lonRecogida,
        "lat_dejada": latDejada,
        "lon_dejada": lonDejada,
      }),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  /// ✅ CORREGIDO: consultar estado de solicitud
  Future<String?> consultarEstadoSolicitud(int recorridoId) async {
    final token = await AuthService().getToken();
    final url = Uri.parse('$baseUrl/mis-solicitudes/');

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      for (var solicitud in data) {
        if (solicitud['recorrido'] == recorridoId) {
          return solicitud['estado'];
        }
      }
    } else {
      print(
          "❌ Error al consultar estado: ${response.statusCode} - ${response.body}");
    }

    return null;
  }

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

  Future<int?> crearRecorrido({
    required String origen,
    required String destino,
    required String fechaHoraSalida,
    required double precioTotal,
    required int asientosDisponibles,
    required double latOrigen,
    required double lonOrigen,
    required double latDestino,
    required double lonDestino,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

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
        "origen_lat": latOrigen,
        "origen_lon": lonOrigen,
        "destino_lat": latDestino,
        "destino_lon": lonDestino,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data["id"];
    } else {
      print(
          "❌ Error al crear recorrido: ${response.statusCode} - ${response.body}");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerSolicitudesPorRecorrido(
      int recorridoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return [];

    final url = Uri.parse('$baseUrl/recorridos/$recorridoId/solicitudes/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    }

    print(
        "❌ Error al obtener solicitudes: ${response.statusCode} - ${response.body}");
    return [];
  }

  Future<bool> aceptarSolicitud(int solicitudId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/solicitudes/$solicitudId/aceptar/');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> rechazarSolicitud(int solicitudId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/solicitudes/$solicitudId/rechazar/');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  Future<bool> cambiarEstadoRecorrido(
      int recorridoId, String nuevoEstado) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    final url = Uri.parse(
        'http://192.168.1.17:8000/api/recorridos/$recorridoId/$nuevoEstado/');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> obtenerDatosMapaRecorrido(
      int recorridoId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final url =
        Uri.parse('http://192.168.1.17:8000/api/recorridos/$recorridoId/mapa/');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print("❌ Error obteniendo mapa del recorrido: ${response.body}");
      return null;
    }
  }

  Future<Map<String, String>> getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return {};
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialPasajero() async {
    final headers = await getHeaders();
    final url = Uri.parse('http://192.168.1.17:8000/api/historial/pasajero/');

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data.reversed);
        }
      } else {
        print(
            "❌ Error al obtener historial: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Excepción al obtener historial: $e");
    }

    return [];
  }

  Future<List<Map<String, dynamic>>> obtenerHistorialConductor() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return [];

    final url = Uri.parse('$baseUrl/historial/conductor/');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
    }

    print("❌ Error al obtener historial conductor: ${response.body}");
    return [];
  }

  Future<void> actualizarUbicacionConductor(
      int recorridoId, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final url = Uri.parse(
        'http://192.168.1.17:8000/api/ubicacion/recorrido/$recorridoId/');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'ubicacion_actual_lat': lat,
        'ubicacion_actual_lon': lon,
      }),
    );

    if (response.statusCode != 200) {
      print("❌ Error enviando ubicación: ${response.body}");
    }
  }
}
