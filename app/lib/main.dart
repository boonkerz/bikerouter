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
