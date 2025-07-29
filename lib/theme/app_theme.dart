import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Tema para o Modo Claro (Light Mode)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue.shade800,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white, // Cor do texto e ícones na AppBar
      ),
      // A customização da TabBar foi TEMPORARIAMENTE removida para corrigir o erro de build.
      // tabBarTheme: const TabBarTheme(
      //   labelColor: Colors.white,
      //   unselectedLabelColor: Colors.white70,
      //   indicatorColor: Colors.white,
      // ),
    );
  }

  // Tema para o Modo Escuro (Dark Mode)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue.shade800,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
      // A customização da TabBar foi TEMPORARIAMENTE removida.
      // tabBarTheme: const TabBarTheme(
      //   labelColor: Colors.white,
      //   indicatorColor: Colors.white,
      // ),
    );
  }
}