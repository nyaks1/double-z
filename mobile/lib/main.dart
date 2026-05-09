import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/welcome.dart';
import 'screens/home.dart';
import 'screens/confirm.dart';

void main() {
  runApp(const DoubleZApp());
}

class DoubleZApp extends StatelessWidget {
  const DoubleZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Double Z',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0E15),
        primaryColor: const Color(0xFF6C63FF),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
          displayLarge: GoogleFonts.outfit(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: GoogleFonts.outfit(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1A1B2E),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/confirm': (context) => const ConfirmScreen(),
      },
    );
  }
}
