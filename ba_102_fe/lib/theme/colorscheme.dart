import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF4B0082); 
  static const Color lightSecondary = Color(0xFF625B71);
  static const Color lightSurface = Color(0xFFFEF7FF);
  
  // Dark Theme Colors
  static const Color darkPrimary = Color(0xFFD0BCFF);
  static const Color darkSecondary = Color(0xFFCCC2DC);
  static const Color darkSurface = Color(0xFF1C1B1F);

  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: lightPrimary,
    brightness: Brightness.light,
    primary: lightPrimary,
  );

  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: lightPrimary, 
    brightness: Brightness.dark,
    primary: darkPrimary,
  );
}
