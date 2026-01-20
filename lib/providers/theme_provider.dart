// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For saving theme preference

class ThemeProvider with ChangeNotifier {
  static const String _themePrefKey =
      'theme_mode_preference'; // Key for SharedPreferences
  ThemeMode _themeMode = ThemeMode.dark; // Default theme

  ThemeProvider() {
    _loadThemePreference(); // Load saved preference on initialization
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // --- Load saved theme preference ---
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themePrefKey);
      if (savedThemeIndex != null &&
          savedThemeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[savedThemeIndex];
        debugPrint(
            "ThemeProvider: Loaded theme preference: $_themeMode"); // Debug log
      } else {
        debugPrint(
            "ThemeProvider: No saved theme preference found, using default: $_themeMode");
      }
    } catch (e) {
      debugPrint("ThemeProvider: Error loading theme preference: $e");
      // Stick with default if loading fails
    } finally {
      notifyListeners(); // Notify listeners after loading (or if default is used)
    }
  }

  // --- Save theme preference ---
  Future<void> _saveThemePreference(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePrefKey, mode.index);
      debugPrint("ThemeProvider: Saved theme preference: $mode"); // Debug log
    } catch (e) {
      debugPrint("ThemeProvider: Error saving theme preference: $e");
    }
  }

  // --- Toggle theme method ---
  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _saveThemePreference(_themeMode); // Save the new preference
    notifyListeners(); // Notify widgets listening to this provider
  }

  // --- Optional: Set specific theme method ---
  void setTheme(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveThemePreference(_themeMode);
      notifyListeners();
    }
  }
}
