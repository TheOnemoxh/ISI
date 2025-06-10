import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'travel_results_screen.dart';
import '../services/api_service.dart';

class TravelDetailScreen extends StatefulWidget {
  final Map<String, dynamic> viaje;
  final String puntoRecogida;
  final String puntoDejada;

  const TravelDetailScreen({
    required this.viaje,
    required this.puntoRecogida,
    required this.puntoDejada,
    super.key,
  });

  @override
  State<TravelDetailScreen> createState() => _TravelDetailScreenState();
}

class _TravelDetailScreenState extends State<TravelDetailScreen> {
  bool solicitudEnviada = false;
  bool conductorAcepto = false;
  bool permitirRetroceso = true;
  bool recogido = false;
  bool viajeCompletado = false;
  Map<String, dynamic>? vehiculo;
  Map<String, dynamic>? conductor;

  @override
  void initState() {
    super.initState();
    obtenerDatosVehiculoYConductor();
  }

  Future<void> obtenerDatosVehiculoYConductor() async {
    final vehiculoData = await ApiService().obtenerVehiculo();
    final conductorData = await ApiService().getUsuarioActualConToken();

    setState(() {
      vehiculo = vehiculoData;
      conductor = conductorData;
    });
  }

  void _llamarAlConductor() async {
    final numero = conductor?["celular"] ?? "";
    final Uri uri = Uri(scheme: 'tel', path: numero);

    if (await launcher.canLaunchUrl(uri)) {
      await launcher.launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo iniciar la llamada")),
      );
    }
  }

  void _rechazarViaje() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("El conductor rechazó el viaje")),
    );

    setState(() {
      solicitudEnviada = false;
      conductorAcepto = false;
      permitirRetroceso = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => TravelResultsScreen(
                puntoRecogida: widget.puntoRecogida,
                puntoDejada: widget.puntoDejada)),
      );
    });
  }

  void _cancelarViaje() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => TravelResultsScreen(
              puntoRecogida: widget.puntoRecogida,
              puntoDejada: widget.puntoDejada)),
    );
  }

  void _completarViaje() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _solicitarViaje() async {
    setState(() {
      solicitudEnviada = true;
      permitirRetroceso = false;
    });

    await Future.delayed(const Duration(seconds: 2));

    final exito = await ApiService().enviarSolicitudDeViaje(
      recorridoId: widget.viaje['id'],
      puntoRecogida: widget.puntoRecogida,
      puntoDejada: widget.puntoDejada,
    );

    if (exito) {
      setState(() => conductorAcepto = true);
    } else {
      _rechazarViaje();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viaje = widget.viaje;

    return WillPopScope(
      onWillPop: () async => permitirRetroceso,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Detalle del viaje"),
          automaticallyImplyLeading: permitirRetroceso,
          actions: [
            if (solicitudEnviada && !recogido && !viajeCompletado)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                tooltip: 'Cancelar viaje',
                onPressed: _cancelarViaje,
              ),
          ],
        ),
        body: vehiculo == null || conductor == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${conductor!["nombres"]} ${conductor!["apellidos"]}",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text("Desde: ${viaje["origen"]}"),
                    Text("Hasta: ${viaje["destino"]}"),
                    Text("Hora de salida: ${viaje["fecha_hora_salida"]}"),
                    const SizedBox(height: 20),
                    const Text("Vehículo",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Modelo: ${vehiculo!["modelo"]}"),
                    Text("Color: ${vehiculo!["color"]}"),
                    Text("Placa: ${vehiculo!["placa"]}"),
                    const SizedBox(height: 20),
                    const Text("Precio",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("COP ${viaje["precio_total"]}",
                        style:
                            const TextStyle(fontSize: 20, color: Colors.green)),
                    const SizedBox(height: 30),
                    if (!solicitudEnviada)
                      ElevatedButton(
                        onPressed: _solicitarViaje,
                        child: const Text("Solicitar viaje"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    if (solicitudEnviada && !conductorAcepto)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Esperando confirmación del conductor..."),
                          const SizedBox(height: 10),
                          if (!recogido)
                            ElevatedButton(
                              onPressed: _llamarAlConductor,
                              child: const Text("Llamar al conductor"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                        ],
                      ),
                    if (conductorAcepto && !viajeCompletado) ...[
                      const Divider(),
                      const Text("El conductor aceptó tu solicitud",
                          style: TextStyle(color: Colors.green)),
                      const SizedBox(height: 10),
                      Text("Número del conductor: ${conductor!["celular"]}"),
                      if (!recogido)
                        ElevatedButton(
                          onPressed: _llamarAlConductor,
                          child: const Text("Llamar al conductor"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      const SizedBox(height: 10),
                      if (!recogido)
                        ElevatedButton(
                          onPressed: () => setState(() => recogido = true),
                          child: const Text("Presiona cuando ya te recogieron"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                    ],
                    if (recogido && !viajeCompletado)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() => viajeCompletado = true);
                            _completarViaje();
                          },
                          child: const Text("Viaje completado"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
