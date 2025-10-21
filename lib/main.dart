import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glow_breez/screens/wallet_screen.dart';

void main() async {
  await BreezSdkSparkLib.init();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glow',
      home: const WalletScreen(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0, scrolledUnderElevation: 0),
      ),
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1A2B4A), // Lighter variant of your dark blue
          secondary: Color(0xFF2A3B5A), // Slightly lighter for secondary
          tertiary: Color(0xFF3A4B6A), // Even lighter for tertiary
          surface: Color(0xFF00091C), // Your first color
          background: Color(0xFF0A1428), // Your second color (RGBO 10,20,40)
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onSurface: Colors.white,
          onBackground: Colors.white,
          onSurfaceVariant: Color(0xFFB0B8C8), // Light gray for text on dark
          outline: Color(0xFF4A5B7A), // Subtle outline color
          error: Color(0xFFCF6679), // Material 3 error color
          onError: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF00091C), // Use your first color for app bar
          foregroundColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A1428), // Use your second color for scaffold
      ),
      themeMode: ThemeMode.dark,
    );
  }
}
