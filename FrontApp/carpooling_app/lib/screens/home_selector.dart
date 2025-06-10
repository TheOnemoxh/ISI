import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'driver_home_screen.dart';

class HomeScreenSelector extends StatelessWidget {
  final bool esConductor;

  const HomeScreenSelector({required this.esConductor, super.key});

  @override
  Widget build(BuildContext context) {
    return esConductor ? DriverHomeScreen() : HomeScreen();
  }
}
