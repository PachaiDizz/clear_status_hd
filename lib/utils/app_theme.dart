import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────
  static const Color primaryColor = Color(0xFF00E87A); // punchy green
  static const Color primaryDark = Color(0xFF00B85E);
  static const Color accentColor = Color(0xFF00E87A);

  // ── Dark surface stack ────────────────────────────────────
  static const Color backgroundDark = Color(0xFF080C10); // near-black base
  static const Color surfaceDark = Color(0xFF0C1117); // app-bar / nav
  static const Color cardDark = Color(0xFF0C1117); // media cards
  static const Color trackDark = Color(0xFF0F1519); // tab track
  static const Color thumbDark = Color(0xFF1A2530); // inactive thumb bg
  static const Color logoBg = Color(0xFF0E1C16); // icon well

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B9AAA);
  static const Color textHint = Color(0xFF3E5060);

  // ── Semantic ──────────────────────────────────────────────
  static const Color errorColor = Color(0xFFFF5F5F);
  static const Color warningColor = Color(0xFFFFA940);

  // ── Border helpers ────────────────────────────────────────
  static const Color borderSubtle = Color(0x0FFFFFFF); // ~6 % white
  static const Color borderMid = Color(0x1AFFFFFF); // ~10 % white

  // ══════════════════════════════════════════════════════════
  // DARK THEME
  // ══════════════════════════════════════════════════════════
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
          surface: surfaceDark,
          error: errorColor,
        ),
        scaffoldBackgroundColor: backgroundDark,
        cardColor: cardDark,

        // ── AppBar ──────────────────────────────────────────
        appBarTheme: const AppBarTheme(
          backgroundColor: surfaceDark,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),

        // ── ElevatedButton ───────────────────────────────────
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),

        // ── Text ────────────────────────────────────────────
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
          headlineMedium: TextStyle(
            color: textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: textPrimary, fontSize: 15),
          bodyMedium: TextStyle(color: textSecondary, fontSize: 13),
          bodySmall: TextStyle(color: textHint, fontSize: 11),
        ),

        // ── SnackBar ─────────────────────────────────────────
        snackBarTheme: SnackBarThemeData(
          backgroundColor: cardDark,
          contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: borderMid),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ══════════════════════════════════════════════════════════
  // LIGHT THEME  (keeps parity; primary green stays)
  // ══════════════════════════════════════════════════════════
  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        primaryColor: primaryColor,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          surface: Color(0xFFF4F6F8),
          error: errorColor,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF0D1117),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: Color(0xFF0D1117)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
}
