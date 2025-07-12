import 'package:flutter/material.dart';
import '../models/user_preferences.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  UserPreferences _preferences = UserPreferences.defaultPreferences();

  bool get isDarkMode => _preferences.isDarkMode;

  // Add themeMode for compatibility with app.dart
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get currentTheme => isDarkMode ? _darkTheme : _lightTheme;

  ThemeProvider() {
    _loadPreferences();
  }

  void _loadPreferences() {
    _preferences = StorageService.getUserPreferences();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _preferences.isDarkMode = !_preferences.isDarkMode;
    await StorageService.savePreferences(_preferences);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    _preferences.isDarkMode = isDark;
    await StorageService.savePreferences(_preferences);
    notifyListeners();
  }

  // Light Theme
  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
    ),
  );

  // Dark Theme
  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2196F3),
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
    cardTheme: const CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
    ),
  );
}
