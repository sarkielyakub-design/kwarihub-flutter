import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
class AppTheme {
  AppTheme._();
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary);
    return ThemeData(useMaterial3: true, colorScheme: scheme.copyWith(primary: AppColors.primary, onPrimary: Colors.white), scaffoldBackgroundColor: AppColors.background, fontFamily: 'Roboto', appBarTheme: const AppBarTheme(backgroundColor: AppColors.white, foregroundColor: AppColors.text, elevation: 0), inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5))), elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0)));
  }
}
