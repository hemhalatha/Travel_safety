library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Centralised application theme — Travel Safety deep-navy brand.
///
/// All colour tokens, typography, and component defaults live here.
/// Update this file to restyle the entire app.
class AppTheme {
  AppTheme._();

  // ── Brand palette ──────────────────────────────────────────────────────────
  /// Primary — deep navy. Conveys trust, authority, safety.
  static const Color primaryNavy = Color(0xFF1B3A6B);

  /// Page/scaffold background — cool off-white with a hint of blue.
  static const Color backgroundBlue = Color(0xFFF5F7FB);

  /// Card & input surface — pure white.
  static const Color surfaceWhite = Color(0xFFFFFFFF);

  /// Primary text — near-black charcoal.
  static const Color charcoal = Color(0xFF1C2536);

  /// Secondary / muted text.
  static const Color mutedGray = Color(0xFF64748B);

  /// Subtle border and divider colour.
  static const Color borderLight = Color(0xFFE2E8F0);

  // ── Safety status colours ──────────────────────────────────────────────────
  /// SAFE text — dark green.
  static const Color safeColor = Color(0xFF166534);

  /// SAFE indicator dot — medium green.
  static const Color safeIcon = Color(0xFF16A34A);

  /// SAFE container background — very light green.
  static const Color safeContainer = Color(0xFFF0FDF4);

  /// SAFE container border — subtle green.
  static const Color safeBorder = Color(0xFFBBF7D0);

  static const Color warningColor = Color(0xFFF57F17);
  static const Color dangerColor = Color(0xFFC62828);

  // ── Theme ──────────────────────────────────────────────────────────────────

  static ThemeData get lightTheme {
    // Generate secondary/tertiary tones via Material 3 seed algorithm.
    final generated = ColorScheme.fromSeed(
      seedColor: primaryNavy,
      brightness: Brightness.light,
    );

    // Override primary + surface with exact brand values.
    final colorScheme = generated.copyWith(
      primary: primaryNavy,
      onPrimary: surfaceWhite,
      surface: backgroundBlue,
      onSurface: charcoal,
      surfaceContainerLowest: surfaceWhite,
      outline: borderLight,
      outlineVariant: const Color(0xFFEEF2FB),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundBlue,

      // AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: backgroundBlue,
        foregroundColor: charcoal,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: charcoal,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: charcoal),
        actionsIconTheme: IconThemeData(color: charcoal),
      ),

      // Card ────────────────────────────────────────────────────────────────
      // White surface on the blue-tinted background creates natural sections
      // without needing borders or heavy elevation.
      cardTheme: const CardThemeData(
        elevation: 0,
        color: surfaceWhite,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
      ),

      // Input decoration ────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryNavy, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: mutedGray, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: primaryNavy, fontSize: 12),
        prefixIconColor: mutedGray,
        suffixIconColor: mutedGray,
      ),

      // Elevated button — navy filled, strong CTA ───────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: surfaceWhite,
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Outlined button ─────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          side: const BorderSide(color: borderLight),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Filled button ───────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // Text button ─────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavy,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),

      // Snack bar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: charcoal,
        contentTextStyle: const TextStyle(color: surfaceWhite, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
