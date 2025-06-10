import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(CarpoolingApp());
}

class CarpoolingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carpooling App',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        // Agrega aquí más rutas si usas nombres para otras pantallas
      },
    );
  }
}
