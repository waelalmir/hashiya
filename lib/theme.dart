import 'package:flutter/material.dart';

class HC {
  static const green = Color(0xFF054743);
  static const cream = Color(0xFFF7F4EB);
  static const deep = Color(0xFF032B27);
}

// الثيم الأساسي للتطبيق مع دعم الثيمات والخطوط الموحدة
ThemeData buildTheme() {
  const font = 'IBMPlexSansArabic';
  return ThemeData(
    useMaterial3: true,
    fontFamily: font,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HC.green,
      primary: HC.green,
      surface: HC.green,
    ),
    scaffoldBackgroundColor: HC.deep,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: HC.cream),
      bodyMedium: TextStyle(color: HC.cream),
      bodySmall: TextStyle(color: HC.cream),
      titleLarge: TextStyle(color: HC.cream),
      titleMedium: TextStyle(color: HC.cream),
      titleSmall: TextStyle(color: HC.cream),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HC.cream.withValues(alpha: .12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: HC.cream.withValues(alpha: .3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: HC.cream.withValues(alpha: .3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: HC.cream, width: 2)),
      labelStyle: TextStyle(color: HC.cream.withValues(alpha: .8)),
      hintStyle: TextStyle(color: HC.cream.withValues(alpha: .4)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: HC.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: HC.cream),
      contentTextStyle: const TextStyle(color: HC.cream),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: HC.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: HC.cream.withValues(alpha: .1),
      selectedColor: HC.cream,
      labelStyle: const TextStyle(color: HC.cream),
      secondaryLabelStyle: const TextStyle(color: HC.green),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
