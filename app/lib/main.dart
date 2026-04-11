import 'package:flutter/material.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const BikeRouterApp());
}

class BikeRouterApp extends StatelessWidget {
  const BikeRouterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeRouter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1a1a2e),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4fc3f7),
          surface: Color(0xFF1a1a2e),
        ),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
