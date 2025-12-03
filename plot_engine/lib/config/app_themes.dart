import 'package:flutter/material.dart';

enum AppTheme {
  light,
  dark,
  halloween,
}

class AppThemes {
  // Light theme
  static ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFFF6B00), // Bright orange
          selectionColor: Color(0x4DFF6B00), // Orange with 30% opacity
          selectionHandleColor: Color(0xFFFF6B00),
        ),
      );

  // Dark theme
  static ThemeData get darkTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF00D4FF), // Bright cyan
          selectionColor: Color(0x4D00D4FF), // Cyan with 30% opacity
          selectionHandleColor: Color(0xFF00D4FF),
        ),
      );

  // Halloween theme - spooky dark theme with orange and purple accents
  static ThemeData get halloweenTheme => ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00), // Pumpkin orange
          onPrimary: Color(0xFF1A0A00),
          primaryContainer: Color(0xFF8B4000), // Dark orange
          onPrimaryContainer: Color(0xFFFFDDB3),
          secondary: Color(0xFF9D4EDD), // Purple
          onSecondary: Color(0xFF2D0A4E),
          secondaryContainer: Color(0xFF5A189A), // Deep purple
          onSecondaryContainer: Color(0xFFE0AAFF),
          tertiary: Color(0xFF00FF41), // Eerie green
          onTertiary: Color(0xFF003314),
          tertiaryContainer: Color(0xFF00802A),
          onTertiaryContainer: Color(0xFFB3FFD1),
          error: Color(0xFFFF0000), // Blood red
          onError: Color(0xFF330000),
          errorContainer: Color(0xFF8B0000),
          onErrorContainer: Color(0xFFFFB3B3),
          surface: Color(0xFF1A0F1F), // Very dark purple-black
          onSurface: Color(0xFFE8D5FF), // Light purple-white
          surfaceContainerHighest: Color(0xFF2D1B3D), // Dark purple
          onSurfaceVariant: Color(0xFFD4B8FF),
          outline: Color(0xFF8B4EDD),
          outlineVariant: Color(0xFF4A2563),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
          inverseSurface: Color(0xFFE8D5FF),
          onInverseSurface: Color(0xFF1A0F1F),
          inversePrimary: Color(0xFF8B4000),
          surfaceTint: Color(0xFFFF6B00),
        ),
        useMaterial3: true,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFFFF6B00), // Pumpkin orange cursor
          selectionColor: Color(0x4DFF6B00), // Orange selection
          selectionHandleColor: Color(0xFFFF6B00),
        ),
        // Custom text theme with spooky feel
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B00),
          ),
          displayMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B00),
          ),
          displaySmall: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF6B00),
          ),
          headlineLarge: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFFE8D5FF),
          ),
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFFE8D5FF),
          ),
          headlineSmall: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFFE8D5FF),
          ),
        ),
        // Icon theme with orange tint
        iconTheme: const IconThemeData(
          color: Color(0xFFFF6B00),
        ),
        // App bar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A0F1F),
          foregroundColor: Color(0xFFFF6B00),
          elevation: 0,
        ),
        // Card theme
        cardTheme: CardThemeData(
          color: const Color(0xFF2D1B3D),
          elevation: 4,
          shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Color(0xFF8B4EDD),
              width: 1,
            ),
          ),
        ),
        // Elevated button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B00),
            foregroundColor: const Color(0xFF1A0A00),
            elevation: 4,
            shadowColor: const Color(0xFFFF6B00).withValues(alpha: 0.5),
          ),
        ),
        // Floating action button theme
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFF6B00),
          foregroundColor: Color(0xFF1A0A00),
        ),
        // Divider theme
        dividerTheme: const DividerThemeData(
          color: Color(0xFF8B4EDD),
          thickness: 1,
        ),
      );

  // Get theme by enum
  static ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return lightTheme;
      case AppTheme.dark:
        return darkTheme;
      case AppTheme.halloween:
        return halloweenTheme;
    }
  }

  // Get theme name for display
  static String getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.halloween:
        return '🎃 Halloween';
    }
  }

  // Get theme icon
  static IconData getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.halloween:
        return Icons.celebration; // Closest to a pumpkin/party icon
    }
  }
}
