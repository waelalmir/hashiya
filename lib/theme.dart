import 'package:flutter/material.dart';

class HC {
  static const green = Color(0xFF064A44);
  static const cream = Color(0xFFEDE5D3);
  static const mid = Color(0xFF0A524A);
  static const deep = Color(0xFF032B27);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'IBMPlexSansArabic',
      scaffoldBackgroundColor: HC.deep,
      colorScheme: const ColorScheme.dark(
        primary: HC.cream,
        onPrimary: HC.green,
        secondary: HC.cream,
        surface: HC.green,
        onSurface: HC.cream,
      ),
    );
