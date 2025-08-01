// lib/providers/locale_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import your AppLocalizations helper to access supported locales
// Adjust the path based on where your app_string.dart (or generated AppLocalizations) is.
// If it's in lib/services/
import '../services/app_string.dart';
// If it's generated directly in lib/generated/ (common with flutter_intl)
// import '../generated/l10n.dart'; // then AppLocalizations would be S.delegate

class LocaleProvider with ChangeNotifier {
  // --- Private Variable ---
  // Holds the current locale. Start with English as the default.
  Locale _locale = const Locale('en'); // Default locale

  // Key for storing the selected locale in SharedPreferences
  static const String _selectedLocaleKey = 'selected_locale_code';

  // --- Getter ---
  // Allows other parts of the app to read the current locale.
  Locale get locale => _locale;

  // --- Constructor ---
  // When the provider is created, try to load the saved locale.
  LocaleProvider() {
    _loadSavedLocale();
  }

  // --- Load Saved Locale ---
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_selectedLocaleKey);

      if (savedCode != null) {
        final newLocale = Locale(savedCode);
        // Check if the loaded locale is supported before setting it
        if (AppLocalizations.delegate.isSupported(newLocale)) {
          _locale = newLocale;
          print("LocaleProvider: Loaded saved locale '$_locale'.");
          // No need to notifyListeners() here as this is part of initialization.
          // The MaterialApp will pick up this initial _locale value when it first builds
          // and watches this provider.
        } else {
          print(
              "LocaleProvider: Saved locale '$savedCode' is no longer supported. Using default.");
          // Optionally, remove the invalid saved preference
          // await prefs.remove(_selectedLocaleKey);
        }
      } else {
        print(
            "LocaleProvider: No saved locale found. Using default '$_locale'.");
      }
    } catch (e) {
      print("LocaleProvider: Error loading saved locale: $e. Using default.");
    }
    // If you need to ensure MaterialApp rebuilds after async load,
    // you could call notifyListeners() here, but it's often not necessary
    // if MaterialApp is already watching the provider.
    // If you do call it, ensure it's after the async gap:
    // if(mounted) notifyListeners(); // (if this were a StatefulWidget)
    // For ChangeNotifier, just calling it is fine if needed after async operation.
    // However, for initial load, it's usually better that MaterialApp reads the value on its first build.
    notifyListeners(); // Let's add it to be safe, in case MaterialApp builds before this finishes.
  }

  // --- Save Locale ---
  Future<void> _saveLocale(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedLocaleKey, languageCode);
      print("LocaleProvider: Saved locale '$languageCode' to preferences.");
    } catch (e) {
      print("LocaleProvider: Error saving locale: $e");
    }
  }

  // --- Setter Method ---
  // This is how you will change the language in your app.
  void setLocale(Locale newLocale) {
    // 1. Check if the new locale is actually supported by your app.
    if (!AppLocalizations.delegate.isSupported(newLocale)) {
      print(
          "LocaleProvider: Locale '${newLocale.languageCode}' is not supported.");
      return; // Do nothing if the language isn't supported
    }

    // 2. Check if the new locale is actually different from the current one.
    if (_locale.languageCode == newLocale.languageCode) {
      // Compare language codes
      print(
          "LocaleProvider: Locale '${newLocale.languageCode}' is already selected.");
      return; // Do nothing if it's the same language
    }

    // 3. If it's different and supported, update the internal locale.
    _locale = newLocale;
    print("LocaleProvider: Locale changed to '${_locale.languageCode}'.");

    // 4. Save the newly selected locale to preferences.
    _saveLocale(_locale.languageCode);

    // 5. IMPORTANT: Notify all listeners that the locale has changed.
    notifyListeners();
  }

  // --- Optional: Helper to get current language display name ---
  // This map should ideally be kept in sync with your supportedLocales.
  static const Map<String, String> _languageDisplayNames = {
    'en': 'English',
    'am': 'አማርኛ', // Amharic
    'om': 'Oromo', // Example, if you support Oromo
    // Add other supported languages here
  };

  String get currentLanguageDisplayName {
    return _languageDisplayNames[_locale.languageCode] ??
        _locale.languageCode; // Fallback to language code
  }

  // --- Optional: Helper to get a list of supported language display options ---
  // Useful for building a language selection UI.
  List<Map<String, dynamic>> get supportedLanguagesForSelection {
    List<Map<String, dynamic>> options = [];
    // Iterate over the statically defined display names map or your AppLocalizations.supportedLocales
    _languageDisplayNames.forEach((code, name) {
      if (AppLocalizations.delegate.isSupported(Locale(code))) {
        options.add({'code': code, 'name': name, 'locale': Locale(code)});
      }
    });
    return options;
    // Alternatively, if AppLocalizations.supportedLocales is comprehensive:
    return AppLocalizations.supportedLocales.map((locale) {
      return {
        'code': locale.languageCode,
        'name':
            _languageDisplayNames[locale.languageCode] ?? locale.languageCode,
        'locale': locale,
      };
    }).toList();
  }
}
