// lib/theme/light_colors.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _LightGreenGoldPalette {
  _LightGreenGoldPalette._();
  // Primary: Fresh Green
  static const Color primary = Color(0xFF4CAF50); // Green 500
  static const Color onPrimary = Colors.white;
  static const Color primaryContainer = Color(0xFFC8E6C9); // Green 100
  static const Color onPrimaryContainer = Color(0xFF0D1F12); // Dark Green

  // Secondary: Vibrant Yellow/Gold
  static const Color secondary = Color(0xFFFFC107); // Amber 500
  static const Color onSecondary = Colors.black;
  static const Color secondaryContainer = Color(0xFFFFECB3); // Amber 100
  static const Color onSecondaryContainer = Color(0xFF261A00); // Dark Brown

  // Tertiary (Optional Accent)
  static const Color tertiary = Color(0xFF006874); // Tealish
  static const Color onTertiary = Colors.white;
  static const Color tertiaryContainer = Color(0xFF97F0FF); // Light Cyan
  static const Color onTertiaryContainer = Color(0xFF001F24); // Dark Cyan

  static const Color error = Color(0xFFB00020); // Standard Material Red
  static const Color onError = Colors.white;
  static const Color errorContainer = Color(0xFFFFDAD6); // Light Red Container
  static const Color onErrorContainer = Color(0xFF410002); // Dark Red

  // Backgrounds & Surfaces: Green-Tinted & Light
  // ============================================================
  // >>>>>>>>>>>> THIS IS THE LINE TO CHANGE <<<<<<<<<<<<<<<
  // ============================================================
  static const Color background =
      Color.fromARGB(255, 21, 193, 84); // Light Green 50 background <-- CHANGED
  // ============================================================

  static const Color onBackground =
      Color(0xFF1B2E1C); // Dark Greenish Grey text
  static const Color surface = Colors.white; // White cards/dialogs etc.
  static const Color onSurface = Color(0xFF1B2E1C); // Dark Greenish Grey text

  static const Color surfaceVariant =
      Color(0xFFDCEDDC); // Light Green accent bg
  static const Color onSurfaceVariant = Color(0xFF414941); // Medium dark green

  static const Color outline = Color(0xFF717971); // Greyish Green Outline
  static const Color outlineVariant = Color(0xFFC1C9BF); // Lighter Outline
  static const Color shadow = Colors.black;
  static const Color scrim = Colors.black;

  static const Color inverseSurface = Color(0xFF2F312F); // Dark inverse surface
  static const Color onInverseSurface = Color(0xFFF0F1EC); // Light text on dark
  static const Color inversePrimary =
      Color(0xFF9CD69E); // Light Green inverse primary

  static const Color surfaceTint = primary; // Primary color tint

  // M3 Surface Tones (Approximated for Light Theme - used by ColorScheme)
  // Re-approximate based on the new background
  static const Color surfaceDim = Color(0xFFD9DFD9); // Derived from E8F5E9
  static const Color surfaceBright = Color(0xFFE8F5E9); // Same as background
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow =
      Color(0xFFEFF5EF); // Derived from E8F5E9
  static const Color surfaceContainer =
      Color(0xFFE9F0E9); // Derived from E8F5E9
  static const Color surfaceContainerHigh =
      Color(0xFFE3EAE3); // Derived from E8F5E9
  static const Color surfaceContainerHighest =
      Color(0xFFDEE5DE); // Derived from E8F5E9

  // Text & Icon Colors (Explicit for clarity)
  static const Color textPrimary = Color(0xFF1B2E1C); // Dark Greenish Grey
  static const Color textSecondary = Color(0xFF4C6B4D); // Medium Greenish Grey
  static const Color textDisabled = Color(0xFF9E9E9E); // Standard Grey
  static const Color iconColor = Color(0xFF4C6B4D); // Medium Greenish Grey
  static const Color iconOnPrimary = Colors.white; // Icons on primary buttons
}

// ========== Palette 2: TikTok Dark & Gold (For Dark Theme) ==========
// Based on the _DarkPalette3 from the user's provided code snippet
class _TiktokDarkPalette {
  _TiktokDarkPalette._();
  // Primary: Rich Gold
  static const Color primary = Color(0xFFFFCA28); // Amber A400 (Good Gold)
  static const Color onPrimary = Colors.black; // Black usually best on Gold
  static const Color primaryContainer =
      Color(0xFF7B5D00); // Dark Gold (Derived)
  static const Color onPrimaryContainer =
      Color(0xFFFFDEA6); // Light Gold (Derived)

  // Secondary: Subtle accent
  static const Color secondary = Color(0xFF66BB6A); // Soft Green Accent
  static const Color onSecondary = Colors.black; // Black on the soft green
  static const Color secondaryContainer =
      Color(0xFF314f34); // Darker Green (Derived)
  static const Color onSecondaryContainer =
      Color(0xFFC4ECCA); // Light Green (Derived)

  // Tertiary (Defining one for completeness, can adjust)
  static const Color tertiary = Color(0xFFA7C8CF); // Soft Blue-Green
  static const Color onTertiary = Color(0xFF08363D); // Dark Teal
  static const Color tertiaryContainer = Color(0xFF244D54); // Darker Teal
  static const Color onTertiaryContainer = Color(0xFFC3E8EF); // Light Teal

  // Backgrounds & Surfaces: TikTok Style Dark
  static const Color background =
      Color(0xFF121212); // Very Dark Grey (Off-black)
  static const Color onBackground = Color(0xFFEAEAEA); // Light Grey/Off-white
  static const Color surface =
      Color(0xFF1E1E1E); // Slightly Lighter Dark Surface
  static const Color onSurface =
      Color(0xFFF5F5F5); // Slightly brighter Off-white

  static const Color surfaceVariant =
      Color(0xFF2C2C2E); // Even Lighter Surface for accents
  static const Color onSurfaceVariant =
      Color(0xFFB0B0B0); // Medium Light Grey on Variant

  static const Color error = Color(0xFFEF9A9A); // Light Red for Dark Theme
  static const Color onError = Colors.black;
  static const Color errorContainer =
      Color(0xFF93000A); // Dark Red Container (Derived)
  static const Color onErrorContainer =
      Color(0xFFFFDAD6); // Light Red on Container (Derived)

  static const Color outline =
      Color(0xFF999077); // Grey/Beige Outline (Derived)
  static const Color outlineVariant =
      Color(0xFF4E4639); // Darker Outline (Derived)
  static const Color shadow = Colors.black;
  static const Color scrim = Colors.black;

  static const Color inverseSurface =
      Color(0xFFE5E2DA); // Light Inverse Surface (Derived)
  static const Color onInverseSurface =
      Color(0xFF32302C); // Dark on Inverse (Derived)
  static const Color inversePrimary =
      Color(0xFF5F4600); // Dark Gold Inverse (Derived)

  static const Color surfaceTint = primary; // Gold tint

  // M3 Surface Tones (Derived from background/surface)
  static const Color surfaceDim = Color(0xFF121212); // Same as background
  static const Color surfaceBright =
      Color(0xFF383838); // A bit lighter than surfaceVariant
  static const Color surfaceContainerLowest =
      Color(0xFF0D0D0D); // Darker than background
  static const Color surfaceContainerLow = Color(0xFF1E1E1E); // Same as surface
  static const Color surfaceContainer =
      Color(0xFF222222); // Slightly lighter than surface
  static const Color surfaceContainerHigh =
      Color(0xFF2C2C2E); // Same as surfaceVariant
  static const Color surfaceContainerHighest =
      Color(0xFF373737); // Lighter than variant

  // Text Colors
  static const Color textPrimary = Color(0xFFF5F5F5); // Bright Off-white
  static const Color textSecondary = Color(0xFFB0B0B0); // Medium Light Grey
  static const Color textDisabled = Color(0xFF757575); // Darker Grey

  // Icon Colors
  static const Color iconColor =
      Color(0xFFB0B0B0); // Medium Light Grey for icons
  static const Color iconOnPrimary = onPrimary; // Black icons on gold buttons
}

// --- Base Text Styles (Using Poppins) ---
// Define the styles once, apply color per theme.
class _AppTextStyles {
  static final TextStyle _base = GoogleFonts.poppins(letterSpacing: 0.15);
  // M3 Style Definitions (Size/Weight/Spacing)
  static TextStyle displayLarge =
      _base.copyWith(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12);
  static TextStyle displayMedium =
      _base.copyWith(fontSize: 45, fontWeight: FontWeight.w400, height: 1.15);
  static TextStyle displaySmall =
      _base.copyWith(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22);
  static TextStyle headlineLarge =
      _base.copyWith(fontSize: 32, fontWeight: FontWeight.w500, height: 1.25);
  static TextStyle headlineMedium =
      _base.copyWith(fontSize: 28, fontWeight: FontWeight.w500, height: 1.28);
  static TextStyle headlineSmall =
      _base.copyWith(fontSize: 24, fontWeight: FontWeight.w500, height: 1.33);
  static TextStyle titleLarge =
      _base.copyWith(fontSize: 22, fontWeight: FontWeight.w500, height: 1.27);
  static TextStyle titleMedium = _base.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
      letterSpacing: 0.15);
  static TextStyle titleSmall = _base.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1);
  static TextStyle bodyLarge = _base.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0.5);
  static TextStyle bodyMedium = _base.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
      letterSpacing: 0.25);
  static TextStyle bodySmall = _base.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.33,
      letterSpacing: 0.4);
  static TextStyle labelLarge = _base.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.43,
      letterSpacing: 0.1);
  static TextStyle labelMedium = _base.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.33,
      letterSpacing: 0.5);
  static TextStyle labelSmall = _base.copyWith(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.45,
      letterSpacing: 0.5);
}

// ============================================================
//         Centralized Theme Definitions
// ============================================================
class AppThemes {
  AppThemes._();

  // Common Button Shape & Padding
  static final OutlinedBorder _buttonShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  static const EdgeInsets _buttonPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 14);

  // Common Page Transitions
  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
    },
  );

  // ================== LIGHT THEME (Green/Gold) ==================
  static final ThemeData lightTheme = _buildThemeData(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      brightness: Brightness.light,
      primary: _LightGreenGoldPalette.primary,
      onPrimary: _LightGreenGoldPalette.onPrimary,
      primaryContainer: _LightGreenGoldPalette.primaryContainer,
      onPrimaryContainer: _LightGreenGoldPalette.onPrimaryContainer,
      secondary: _LightGreenGoldPalette.secondary,
      onSecondary: _LightGreenGoldPalette.onSecondary,
      secondaryContainer: _LightGreenGoldPalette.secondaryContainer,
      onSecondaryContainer: _LightGreenGoldPalette.onSecondaryContainer,
      tertiary: _LightGreenGoldPalette.tertiary,
      onTertiary: _LightGreenGoldPalette.onTertiary,
      tertiaryContainer: _LightGreenGoldPalette.tertiaryContainer,
      onTertiaryContainer: _LightGreenGoldPalette.onTertiaryContainer,
      error: _LightGreenGoldPalette.error,
      onError: _LightGreenGoldPalette.onError,
      errorContainer: _LightGreenGoldPalette.errorContainer,
      onErrorContainer: _LightGreenGoldPalette.onErrorContainer,
      surface: _LightGreenGoldPalette.surface,
      onSurface: _LightGreenGoldPalette.onSurface,
      onSurfaceVariant: _LightGreenGoldPalette.onSurfaceVariant,
      outline: _LightGreenGoldPalette.outline,
      outlineVariant: _LightGreenGoldPalette.outlineVariant,
      shadow: _LightGreenGoldPalette.shadow,
      scrim: _LightGreenGoldPalette.scrim,
      inverseSurface: _LightGreenGoldPalette.inverseSurface,
      onInverseSurface: _LightGreenGoldPalette.onInverseSurface,
      inversePrimary: _LightGreenGoldPalette.inversePrimary,
      surfaceTint: _LightGreenGoldPalette.surfaceTint,
      // M3 Surface Tones
      surfaceBright: _LightGreenGoldPalette.surfaceBright,
      surfaceDim: _LightGreenGoldPalette.surfaceDim,
      surfaceContainerLowest: _LightGreenGoldPalette.surfaceContainerLowest,
      surfaceContainerLow: _LightGreenGoldPalette.surfaceContainerLow,
      surfaceContainer: _LightGreenGoldPalette.surfaceContainer,
      surfaceContainerHigh: _LightGreenGoldPalette.surfaceContainerHigh,
      surfaceContainerHighest: _LightGreenGoldPalette.surfaceContainerHighest,
    ),
    textThemeColors: const _ThemeTextColors(
      primary: _LightGreenGoldPalette.textPrimary,
      secondary: _LightGreenGoldPalette.textSecondary,
      disabled: _LightGreenGoldPalette.textDisabled,
    ),
    iconColors: const _ThemeIconColors(
      primary: _LightGreenGoldPalette.iconColor,
      onPrimary: _LightGreenGoldPalette.iconOnPrimary,
    ),
  );

  // ================== DARK THEME (TikTok Dark & Gold) ==================
  static final ThemeData darkTheme = _buildThemeData(
    // Using the correct name now
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: _TiktokDarkPalette.primary,
      onPrimary: _TiktokDarkPalette.onPrimary,
      primaryContainer: _TiktokDarkPalette.primaryContainer,
      onPrimaryContainer: _TiktokDarkPalette.onPrimaryContainer,
      secondary: _TiktokDarkPalette.secondary,
      onSecondary: _TiktokDarkPalette.onSecondary,
      secondaryContainer: _TiktokDarkPalette.secondaryContainer,
      onSecondaryContainer: _TiktokDarkPalette.onSecondaryContainer,
      tertiary: _TiktokDarkPalette.tertiary,
      onTertiary: _TiktokDarkPalette.onTertiary,
      tertiaryContainer: _TiktokDarkPalette.tertiaryContainer,
      onTertiaryContainer: _TiktokDarkPalette.onTertiaryContainer,
      error: _TiktokDarkPalette.error,
      onError: _TiktokDarkPalette.onError,
      errorContainer: _TiktokDarkPalette.errorContainer,
      onErrorContainer: _TiktokDarkPalette.onErrorContainer,
      surface: _TiktokDarkPalette.surface,
      onSurface: _TiktokDarkPalette.onSurface,
      onSurfaceVariant: _TiktokDarkPalette.onSurfaceVariant,
      outline: _TiktokDarkPalette.outline,
      outlineVariant: _TiktokDarkPalette.outlineVariant,
      shadow: _TiktokDarkPalette.shadow,
      scrim: _TiktokDarkPalette.scrim,
      inverseSurface: _TiktokDarkPalette.inverseSurface,
      onInverseSurface: _TiktokDarkPalette.onInverseSurface,
      inversePrimary: _TiktokDarkPalette.inversePrimary,
      surfaceTint: _TiktokDarkPalette.surfaceTint,
      // M3 Surface Tones
      surfaceBright: _TiktokDarkPalette.surfaceBright,
      surfaceDim: _TiktokDarkPalette.surfaceDim,
      surfaceContainerLowest: _TiktokDarkPalette.surfaceContainerLowest,
      surfaceContainerLow: _TiktokDarkPalette.surfaceContainerLow,
      surfaceContainer: _TiktokDarkPalette.surfaceContainer,
      surfaceContainerHigh: _TiktokDarkPalette.surfaceContainerHigh,
      surfaceContainerHighest: _TiktokDarkPalette.surfaceContainerHighest,
    ),
    textThemeColors: const _ThemeTextColors(
      primary: _TiktokDarkPalette.textPrimary,
      secondary: _TiktokDarkPalette.textSecondary,
      disabled: _TiktokDarkPalette.textDisabled,
    ),
    iconColors: const _ThemeIconColors(
      primary: _TiktokDarkPalette.iconColor,
      onPrimary: _TiktokDarkPalette.iconOnPrimary,
    ),
  );

  // --- ThemeData Builder Helper (Handles both Light and Dark) ---
  static ThemeData _buildThemeData({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required _ThemeTextColors textThemeColors,
    required _ThemeIconColors iconColors,
  }) {
    final bool isDark = brightness == Brightness.dark;

    // Define base text styles without color
    final textThemeBase = TextTheme(
      displayLarge: _AppTextStyles.displayLarge,
      displayMedium: _AppTextStyles.displayMedium,
      displaySmall: _AppTextStyles.displaySmall,
      headlineLarge: _AppTextStyles.headlineLarge,
      headlineMedium: _AppTextStyles.headlineMedium,
      headlineSmall: _AppTextStyles.headlineSmall,
      titleLarge: _AppTextStyles.titleLarge,
      titleMedium: _AppTextStyles.titleMedium,
      titleSmall: _AppTextStyles.titleSmall,
      bodyLarge: _AppTextStyles.bodyLarge,
      bodyMedium: _AppTextStyles.bodyMedium,
      bodySmall: _AppTextStyles.bodySmall,
      labelLarge: _AppTextStyles.labelLarge,
      labelMedium: _AppTextStyles.labelMedium,
      labelSmall: _AppTextStyles.labelSmall,
    );

    // Apply specific theme colors to the base text styles
    final textTheme = textThemeBase
        .copyWith(
          displayLarge: textThemeBase.displayLarge
              ?.copyWith(color: textThemeColors.primary),
          displayMedium: textThemeBase.displayMedium
              ?.copyWith(color: textThemeColors.primary),
          displaySmall: textThemeBase.displaySmall
              ?.copyWith(color: textThemeColors.primary),
          headlineLarge: textThemeBase.headlineLarge
              ?.copyWith(color: textThemeColors.primary),
          headlineMedium: textThemeBase.headlineMedium
              ?.copyWith(color: textThemeColors.primary),
          headlineSmall: textThemeBase.headlineSmall
              ?.copyWith(color: textThemeColors.primary),
          titleLarge: textThemeBase.titleLarge
              ?.copyWith(color: textThemeColors.primary),
          titleMedium: textThemeBase.titleMedium
              ?.copyWith(color: textThemeColors.primary),
          titleSmall: textThemeBase.titleSmall
              ?.copyWith(color: textThemeColors.secondary),
          bodyLarge:
              textThemeBase.bodyLarge?.copyWith(color: textThemeColors.primary),
          bodyMedium: textThemeBase.bodyMedium
              ?.copyWith(color: textThemeColors.secondary),
          bodySmall: textThemeBase.bodySmall
              ?.copyWith(color: textThemeColors.disabled),
          labelLarge: textThemeBase.labelLarge
              ?.copyWith(color: textThemeColors.primary),
          labelMedium: textThemeBase.labelMedium
              ?.copyWith(color: textThemeColors.primary),
          labelSmall: textThemeBase.labelSmall
              ?.copyWith(color: textThemeColors.primary),
        )
        .apply(
          // Apply overall display/body colors
          displayColor: textThemeColors.primary,
          bodyColor: textThemeColors.primary,
        );

    // Use appropriate base theme
    final baseTheme = isDark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);

    // --- Build the ThemeData ---
    return baseTheme.copyWith(
      brightness: brightness,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: isDark ? colorScheme.surface : colorScheme.surface,
      cardColor: isDark ? colorScheme.surfaceContainer : colorScheme.surface,
      dividerColor: colorScheme.outlineVariant,
      hintColor: textThemeColors.disabled,
      colorScheme: colorScheme,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: iconColors.primary, size: 24),
      primaryIconTheme: IconThemeData(color: colorScheme.onPrimary),
      appBarTheme: AppBarTheme(
        elevation: isDark ? 0 : 1,
        scrolledUnderElevation: isDark ? 0 : 2,
        // Dark uses surface, Light uses primary AppBar background
        // *** ADJUSTMENT for TikTok Dark: Match background for seamless look ***
        backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
        foregroundColor:
            isDark ? colorScheme.onSurface : colorScheme.onPrimary,
        // *** ADJUSTMENT for TikTok Dark: Use general icon color ***
        iconTheme: IconThemeData(
            color: isDark ? iconColors.primary : colorScheme.onPrimary),
        titleTextStyle: _AppTextStyles.titleLarge.copyWith(
            color: isDark ? colorScheme.onSurface : colorScheme.onPrimary),
        centerTitle: true,
        surfaceTintColor:
            Colors.transparent, // No tint for dark AppBar generally
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: _AppTextStyles.labelLarge,
          padding: _buttonPadding,
          shape: _buttonShape,
          elevation: isDark ? 2 : 1, // Slightly more prominent button in dark
          shadowColor: isDark
              ? colorScheme.primary.withOpacity(0.3)
              : Colors.transparent,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onPrimary.withOpacity(0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onPrimary.withOpacity(0.08);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: _AppTextStyles.labelLarge,
          // Dark uses outline color, Light uses primary color for border
          side: BorderSide(
              color: isDark
                  ? colorScheme.primary.withOpacity(0.7)
                  : colorScheme.primary,
              width: 1.5), // Adjusted Dark border
          padding: _buttonPadding,
          shape: _buttonShape,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withOpacity(0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withOpacity(0.08);
            }
            return null;
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: _AppTextStyles.labelLarge,
          padding: _buttonPadding,
          shape: _buttonShape,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withOpacity(0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withOpacity(0.08);
            }
            return null;
          }),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        // *** ADJUSTMENT for TikTok Dark: Use primary for FAB ***
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // *** ADJUSTMENT for TikTok Dark: Use surfaceVariant ***
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
            : colorScheme.surfaceContainerHighest.withOpacity(0.5),
        hintStyle:
            _AppTextStyles.bodyLarge.copyWith(color: textThemeColors.disabled),
        labelStyle: _AppTextStyles.bodyLarge
            .copyWith(color: colorScheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        // *** ADJUSTMENT for TikTok Dark: No border usually ***
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: colorScheme.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: colorScheme.error, width: 2.0),
        ),
        border: OutlineInputBorder(
          // Default state
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        // *** ADJUSTMENT for TikTok Dark: Darker background ***
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHigh,
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        selectedColor: isDark
            ? colorScheme.primary
            : colorScheme.secondaryContainer, // Gold selection for dark
        secondarySelectedColor: colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        // Apply correct label color
        labelStyle: _AppTextStyles.labelLarge.copyWith(
            color: isDark
                ? colorScheme.onSurfaceVariant
                : colorScheme.onSurfaceVariant),
        // Text on selected chip
        secondaryLabelStyle: _AppTextStyles.labelLarge.copyWith(
            color: isDark
                ? colorScheme.onPrimary
                : colorScheme.onSecondaryContainer),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          // *** ADJUSTMENT for TikTok Dark: No border usually ***
          side: BorderSide.none,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: 18),
        elevation: 0,
        pressElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        // *** ADJUSTMENT for TikTok Dark: Match background ***
        backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
        selectedItemColor: isDark
            ? colorScheme.primary
            : colorScheme.onPrimary, // Gold selection for dark
        unselectedItemColor: isDark
            ? textThemeColors.disabled
            : colorScheme.onPrimary.withOpacity(0.7), // Grey disabled for dark
        selectedLabelStyle: _AppTextStyles.labelMedium.copyWith(
            color: isDark ? colorScheme.primary : colorScheme.onPrimary),
        unselectedLabelStyle: _AppTextStyles.labelMedium.copyWith(
            color: isDark
                ? textThemeColors.disabled
                : colorScheme.onPrimary.withOpacity(0.7)),
        elevation: isDark ? 0 : 2, // No elevation for dark bottom nav
        type: BottomNavigationBarType.fixed,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }
}

// Helper classes for organizing colors passed to the builder
class _ThemeTextColors {
  final Color primary;
  final Color secondary;
  final Color disabled;
  const _ThemeTextColors(
      {required this.primary, required this.secondary, required this.disabled});
}

class _ThemeIconColors {
  final Color primary;
  final Color onPrimary; // Icon on primary color surfaces (buttons, FABs)
  const _ThemeIconColors({required this.primary, required this.onPrimary});
}
