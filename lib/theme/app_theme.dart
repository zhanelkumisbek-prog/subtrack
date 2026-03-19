import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette — Deep Space + Electric Lime
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF13131A);
  static const Color surfaceElevated = Color(0xFF1C1C27);
  static const Color surfaceCard = Color(0xFF1E1E2E);

  static const Color accent = Color(0xFFBEF264); // Electric lime
  static const Color accentDim = Color(0xFF4D6B1A);
  static const Color accentGlow = Color(0x33BEF264);

  static const Color textPrimary = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFF8888A8);
  static const Color textMuted = Color(0xFF44445A);

  static const Color danger = Color(0xFFFF4757);
  static const Color dangerDim = Color(0x33FF4757);
  static const Color warning = Color(0xFFFFB236);
  static const Color warningDim = Color(0x33FFB236);
  static const Color success = Color(0xFF2ECC71);

  static const Color border = Color(0xFF2A2A3D);
  static const Color borderLight = Color(0xFF3A3A55);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: accent,
        secondary: accentDim,
        error: danger,
        onSurface: textPrimary,
        onPrimary: Color(0xFF0A0A0F),
      ),
      fontFamily: 'DMSans',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Syne',
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -1.5,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Syne',
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1.0,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Syne',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Syne',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Syne',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Syne',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return background;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return surfaceElevated;
        }),
      ),
    );
  }

  // Subscription category colors
  static const Map<String, Color> categoryColors = {
    'streaming': Color(0xFFFF6B6B),
    'music': Color(0xFF4ECDC4),
    'gaming': Color(0xFF9B59B6),
    'productivity': Color(0xFF3498DB),
    'news': Color(0xFFE67E22),
    'fitness': Color(0xFF2ECC71),
    'cloud': Color(0xFF1ABC9C),
    'other': Color(0xFF95A5A6),
  };

  static const Map<String, String> categoryIcons = {
    'streaming': '🎬',
    'music': '🎵',
    'gaming': '🎮',
    'productivity': '💼',
    'news': '📰',
    'fitness': '💪',
    'cloud': '☁️',
    'other': '📦',
  };
}
