import 'package:flutter/material.dart';
import 'package:resaleroute/core/constants/app_colors.dart';
import 'package:resaleroute/core/constants/app_typography.dart';
import 'package:resaleroute/core/constants/sustainability_constants.dart';

/// Dark-First Editorial Vault ThemeData definitions matching `docs/03_UI_Spec.md`.
abstract final class AppTheme {
  /// Subtle card shadow permitted ONLY in Light Mode (`0 2px 8px rgba(0,0,0,0.04)`).
  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Returns empty shadows in Dark Mode (strictly zero drop shadows) and
  /// [lightCardShadow] in Light Mode.
  static List<BoxShadow> cardShadows(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const <BoxShadow>[]
        : lightCardShadow;
  }

  /// Primary Dark-First Editorial Vault theme (`ThemeMode.dark` default).
  static ThemeData get darkTheme {
    const palette = AppColors.dark;
    final textTheme = AppTypography.buildTextTheme(
      palette.textPrimary,
      palette.textSecondary,
    );

    final colorScheme = ColorScheme.dark(
      primary: palette.accentPrimary,
      onPrimary: palette.buttonOnPrimary,
      secondary: palette.accentLuxury,
      onSecondary: palette.buttonOnPrimary,
      surface: palette.bgSurface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.bgElevated,
      error: palette.statusDanger,
      onError: palette.textPrimary,
      outline: palette.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.bgCanvas,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bgCanvas,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTypography.headingMd.copyWith(
          color: palette.textPrimary,
        ),
        shape: Border(
          bottom: BorderSide(color: palette.borderSubtle, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.bgSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: palette.borderSubtle, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.bgSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: palette.borderSubtle, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.bgSurface,
        elevation: 0,
        modalElevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusCard),
          ),
          side: BorderSide(color: palette.borderSubtle, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: _buildInputDecorationTheme(palette),
      filledButtonTheme: _buildFilledButtonTheme(palette),
      elevatedButtonTheme: _buildElevatedButtonTheme(palette, isDark: true),
      outlinedButtonTheme: _buildOutlinedButtonTheme(palette),
    );
  }

  /// Light Mode theme with 1px `#E5E7EB` borders and subtle elevation.
  static ThemeData get lightTheme {
    const palette = AppColors.light;
    const lightShadow = Color.fromRGBO(0, 0, 0, 0.04);
    final textTheme = AppTypography.buildTextTheme(
      palette.textPrimary,
      palette.textSecondary,
    );

    final colorScheme = ColorScheme.light(
      primary: palette.accentPrimary,
      onPrimary: palette.buttonOnPrimary,
      secondary: palette.accentLuxury,
      onSecondary: palette.buttonOnPrimary,
      surface: palette.bgSurface,
      onSurface: palette.textPrimary,
      surfaceContainerHighest: palette.bgElevated,
      error: palette.statusDanger,
      onError: palette.buttonOnPrimary,
      outline: palette.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.bgCanvas,
      textTheme: textTheme,
      extensions: const <ThemeExtension<dynamic>>[palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bgSurface,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: lightShadow,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTypography.headingMd.copyWith(
          color: palette.textPrimary,
        ),
        shape: Border(
          bottom: BorderSide(color: palette.borderSubtle, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.bgSurface,
        elevation: 2,
        shadowColor: lightShadow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: palette.borderSubtle, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.bgSurface,
        elevation: 2,
        shadowColor: lightShadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
          side: BorderSide(color: palette.borderSubtle, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.bgSurface,
        elevation: 2,
        modalElevation: 2,
        shadowColor: lightShadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusCard),
          ),
          side: BorderSide(color: palette.borderSubtle, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: palette.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: _buildInputDecorationTheme(palette),
      filledButtonTheme: _buildFilledButtonTheme(palette),
      elevatedButtonTheme: _buildElevatedButtonTheme(palette, isDark: false),
      outlinedButtonTheme: _buildOutlinedButtonTheme(palette),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(
    AppColorPalette palette,
  ) {
    final radius = BorderRadius.circular(AppSpacing.radiusButton);
    return InputDecorationTheme(
      filled: true,
      fillColor: palette.bgElevated,
      hintStyle: AppTypography.bodyMd.copyWith(color: palette.textSecondary),
      labelStyle: AppTypography.labelSm.copyWith(color: palette.textSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.borderSubtle, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.accentPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.statusDanger, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: palette.statusDanger, width: 1.5),
      ),
    );
  }

  static FilledButtonThemeData _buildFilledButtonTheme(
    AppColorPalette palette,
  ) {
    return FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(
          AppTypography.titleSm.copyWith(fontSize: 14, height: 20 / 14),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.bgElevated;
          }
          if (states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused)) {
            return palette.primaryPressed;
          }
          return palette.accentPrimary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.disabledText;
          }
          return palette.buttonOnPrimary;
        }),
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: palette.focusRing, width: 2);
          }
          return BorderSide.none;
        }),
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    AppColorPalette palette, {
    required bool isDark,
  }) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        elevation: WidgetStatePropertyAll(isDark ? 0 : 1),
        shadowColor: WidgetStatePropertyAll(
          isDark ? Colors.transparent : const Color.fromRGBO(0, 0, 0, 0.04),
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.bgElevated;
          }
          if (states.contains(WidgetState.pressed)) {
            return palette.primaryPressed;
          }
          return palette.accentPrimary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return palette.disabledText;
          }
          return palette.buttonOnPrimary;
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    AppColorPalette palette,
  ) {
    return OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        foregroundColor: WidgetStatePropertyAll(palette.textPrimary),
        side: WidgetStatePropertyAll(
          BorderSide(color: palette.borderSubtle, width: 1),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
        ),
      ),
    );
  }
}
