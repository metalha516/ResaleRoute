import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Locked typography scale for ResaleRoute matching `docs/03_UI_Spec.md` §3.
abstract final class AppTypography {
  /// Display Large — Plus Jakarta Sans 28px / 36px, Bold 700, -0.5px tracking.
  static TextStyle get displayLg => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  /// Heading Medium — Plus Jakarta Sans 20px / 28px, SemiBold 600, -0.3px tracking.
  static TextStyle get headingMd => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        height: 28 / 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  /// Title Small — Plus Jakarta Sans 16px / 24px, SemiBold 600, 0px tracking.
  static TextStyle get titleSm => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      );

  /// Body Medium — Inter 14px / 20px, Regular 400, 0px tracking.
  static TextStyle get bodyMd => GoogleFonts.inter(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      );

  /// Label Small — Inter 12px / 16px, Medium 500, +0.2px tracking.
  static TextStyle get labelSm => GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );

  /// Monospace Data — JetBrains Mono 13px / 18px, Medium 500, 0px tracking.
  /// Mandatory for SKUs, integer-cent currency amounts, basis-point splits,
  /// and SHA-256 provenance hashes.
  static TextStyle get monoData => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      );

  /// Maps ResaleRoute's typography tokens onto Material 3 [TextTheme].
  static TextTheme buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: displayLg.copyWith(color: primaryColor),
      displayMedium: headingMd.copyWith(color: primaryColor),
      displaySmall: titleSm.copyWith(color: primaryColor),
      headlineLarge: displayLg.copyWith(color: primaryColor),
      headlineMedium: headingMd.copyWith(color: primaryColor),
      headlineSmall: titleSm.copyWith(color: primaryColor),
      titleLarge: headingMd.copyWith(color: primaryColor),
      titleMedium: titleSm.copyWith(color: primaryColor),
      titleSmall: titleSm.copyWith(color: primaryColor),
      bodyLarge: bodyMd.copyWith(color: primaryColor),
      bodyMedium: bodyMd.copyWith(color: primaryColor),
      bodySmall: labelSm.copyWith(color: secondaryColor),
      labelLarge: titleSm.copyWith(
        fontSize: 14,
        height: 20 / 14,
        color: primaryColor,
      ),
      labelMedium: labelSm.copyWith(color: secondaryColor),
      labelSmall: labelSm.copyWith(color: secondaryColor),
    );
  }
}
