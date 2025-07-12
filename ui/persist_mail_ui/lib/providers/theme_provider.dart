import 'package:flutter/material.dart';
import '../models/user_preferences.dart';
import '../services/storage_service.dart';
import '../services/logging_service.dart';

class ThemeProvider extends ChangeNotifier {
  UserPreferences _preferences = UserPreferences.defaultPreferences();

  bool get isDarkMode => _preferences.isDarkMode;

  // Add themeMode for compatibility with app.dart
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeData get currentTheme => isDarkMode ? _darkTheme : _lightTheme;

  ThemeProvider() {
    AppLogger.debug('ThemeProvider: Initializing');
    _loadPreferences();
  }

  void _loadPreferences() {
    try {
      _preferences = StorageService.getUserPreferences();
      AppLogger.debug('ThemeProvider: Preferences loaded', {
        'isDarkMode': _preferences.isDarkMode,
      });
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(
        'ThemeProvider: Failed to load preferences',
        e,
        stackTrace,
      );
    }
  }

  Future<void> toggleTheme() async {
    try {
      final oldValue = _preferences.isDarkMode;
      _preferences.isDarkMode = !_preferences.isDarkMode;
      await StorageService.savePreferences(_preferences);
      AppLogger.themeChanged(_preferences.isDarkMode);
      AppLogger.debug('ThemeProvider: Theme toggled', {
        'from': oldValue,
        'to': _preferences.isDarkMode,
      });
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error('ThemeProvider: Failed to toggle theme', e, stackTrace);
    }
  }

  Future<void> setTheme(bool isDark) async {
    try {
      if (_preferences.isDarkMode != isDark) {
        _preferences.isDarkMode = isDark;
        await StorageService.savePreferences(_preferences);
        AppLogger.themeChanged(isDark);
        AppLogger.debug('ThemeProvider: Theme set', {'isDarkMode': isDark});
        notifyListeners();
      }
    } catch (e, stackTrace) {
      AppLogger.error('ThemeProvider: Failed to set theme', e, stackTrace);
    }
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
