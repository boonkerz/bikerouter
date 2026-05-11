import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';
import 'screens/map_screen.dart';

void main() {
  runApp(const WegwieselApp());
}

class WegwieselApp extends StatelessWidget {
  const WegwieselApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wegwiesel',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFf5e9d8),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6a4a28),
          onPrimary: Color(0xFFf5e9d8),
          secondary: Color(0xFF3e4d65),
          onSecondary: Color(0xFFf5e9d8),
          surface: Color(0xFFf5e9d8),
          onSurface: Color(0xFF2a2014),
          surfaceContainerHigh: Color(0xFFebd9bd),
        ),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}
