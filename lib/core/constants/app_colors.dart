import 'package:flutter/material.dart';

/// Semantic color palette extension for ResaleRoute's Dark-First Editorial Vault
/// design system (see `docs/03_UI_Spec.md`).
@immutable
class AppColorPalette extends ThemeExtension<AppColorPalette> {
  const AppColorPalette({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.accentPrimary,
    required this.accentLuxury,
    required this.statusWarning,
    required this.statusDanger,
    required this.borderSubtle,
    required this.primaryPressed,
    required this.focusRing,
    required this.disabledText,
    required this.buttonOnPrimary,
  });

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color accentPrimary;
  final Color accentLuxury;
  final Color statusWarning;
  final Color statusDanger;
  final Color borderSubtle;
  final Color primaryPressed;
  final Color focusRing;
  final Color disabledText;
  final Color buttonOnPrimary;

  @override
  AppColorPalette copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgElevated,
    Color? textPrimary,
    Color? textSecondary,
    Color? accentPrimary,
    Color? accentLuxury,
    Color? statusWarning,
    Color? statusDanger,
    Color? borderSubtle,
    Color? primaryPressed,
    Color? focusRing,
    Color? disabledText,
    Color? buttonOnPrimary,
  }) {
    return AppColorPalette(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgElevated: bgElevated ?? this.bgElevated,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      accentLuxury: accentLuxury ?? this.accentLuxury,
      statusWarning: statusWarning ?? this.statusWarning,
      statusDanger: statusDanger ?? this.statusDanger,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      focusRing: focusRing ?? this.focusRing,
      disabledText: disabledText ?? this.disabledText,
      buttonOnPrimary: buttonOnPrimary ?? this.buttonOnPrimary,
    );
  }

  @override
  AppColorPalette lerp(
    covariant ThemeExtension<AppColorPalette>? other,
    double t,
  ) {
    if (other is! AppColorPalette) {
      return this;
    }
    return AppColorPalette(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t) ?? bgCanvas,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t) ?? bgSurface,
      bgElevated: Color.lerp(bgElevated, other.bgElevated, t) ?? bgElevated,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      accentPrimary:
          Color.lerp(accentPrimary, other.accentPrimary, t) ?? accentPrimary,
      accentLuxury:
          Color.lerp(accentLuxury, other.accentLuxury, t) ?? accentLuxury,
      statusWarning:
          Color.lerp(statusWarning, other.statusWarning, t) ?? statusWarning,
      statusDanger:
          Color.lerp(statusDanger, other.statusDanger, t) ?? statusDanger,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      primaryPressed:
          Color.lerp(primaryPressed, other.primaryPressed, t) ?? primaryPressed,
      focusRing: Color.lerp(focusRing, other.focusRing, t) ?? focusRing,
      disabledText:
          Color.lerp(disabledText, other.disabledText, t) ?? disabledText,
      buttonOnPrimary: Color.lerp(buttonOnPrimary, other.buttonOnPrimary, t) ??
          buttonOnPrimary,
    );
  }
}

/// Static dark and light token palettes matching `docs/03_UI_Spec.md` §2 & §5.1.
abstract final class AppColors {
  static const AppColorPalette dark = AppColorPalette(
    bgCanvas: Color(0xFF0B0D10),
    bgSurface: Color(0xFF13171D),
    bgElevated: Color(0xFF1C222B),
    textPrimary: Color(0xFFF3F4F6),
    textSecondary: Color(0xFF9CA3AF),
    accentPrimary: Color(0xFF10B981),
    accentLuxury: Color(0xFFD4AF37),
    statusWarning: Color(0xFFF59E0B),
    statusDanger: Color(0xFFEF4444),
    borderSubtle: Color(0xFF262E3B),
    primaryPressed: Color(0xFF059669),
    focusRing: Color(0xFF34D399),
    disabledText: Color(0xFF4B5563),
    buttonOnPrimary: Color(0xFF0B0D10),
  );

  static const AppColorPalette light = AppColorPalette(
    bgCanvas: Color(0xFFF8F9FA),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFF1F3F5),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    accentPrimary: Color(0xFF059669),
    accentLuxury: Color(0xFFB48A1E),
    statusWarning: Color(0xFFD97706),
    statusDanger: Color(0xFFDC2626),
    borderSubtle: Color(0xFFE5E7EB),
    primaryPressed: Color(0xFF047857),
    focusRing: Color(0xFF34D399),
    disabledText: Color(0xFF9CA3AF),
    buttonOnPrimary: Color(0xFFFFFFFF),
  );

  /// Resolves the active [AppColorPalette] from [BuildContext], defaulting to [dark].
  static AppColorPalette of(BuildContext context) {
    return Theme.of(context).extension<AppColorPalette>() ?? AppColors.dark;
  }
}
