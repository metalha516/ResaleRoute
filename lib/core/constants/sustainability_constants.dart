/// Strict 4px spacing scale, corner radii, and responsive breakpoints from
/// `docs/03_UI_Spec.md` §4.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  static const double radiusCard = 12.0;
  static const double radiusButton = 8.0;
  static const double radiusPill = 999.0;

  static const double mobileBreakpoint = 600.0;

  /// Returns 16px on mobile (< 600px) and 32px on tablet/desktop (>= 600px).
  static double horizontalPadding(double width) {
    return width < mobileBreakpoint ? lg : xxl;
  }
}

/// Immutable per-category sustainability impact estimates.
class CategoryImpact {
  const CategoryImpact({
    required this.co2SavedKg,
    required this.waterSavedLiters,
  });

  final double co2SavedKg;
  final int waterSavedLiters;
}

/// Domain defaults and category-level circularity metrics matching
/// `docs/05_Schema.md` and `docs/01_PRD.md`.
abstract final class SustainabilityConstants {
  static const double defaultCo2SavedKg = 6.50;
  static const int defaultWaterSavedLiters = 1800;

  /// Minimum available consignor balance required for payout requests (in cents).
  static const int minPayoutThresholdCents = 2000;

  /// Default high-value item threshold requiring luxury authentication (in cents).
  static const int defaultHighValueAuthThresholdCents = 25000;

  /// Shopper return dispute window from purchase timestamp (in days).
  static const int returnWindowDays = 7;

  /// Default consignor commission split in basis points (70.00%).
  static const int defaultConsignorSplitBps = 7000;

  /// Total basis points representing 100.00%.
  static const int totalBasisPoints = 10000;

  static const Map<String, CategoryImpact> categoryImpact = {
    'handbags': CategoryImpact(co2SavedKg: 14.20, waterSavedLiters: 4200),
    'outerwear': CategoryImpact(co2SavedKg: 11.80, waterSavedLiters: 3100),
    'dresses': CategoryImpact(co2SavedKg: 8.40, waterSavedLiters: 2400),
    'footwear': CategoryImpact(co2SavedKg: 9.60, waterSavedLiters: 2900),
    'knitwear': CategoryImpact(co2SavedKg: 7.50, waterSavedLiters: 2100),
    'tailoring': CategoryImpact(co2SavedKg: 10.30, waterSavedLiters: 2650),
    'accessories': CategoryImpact(co2SavedKg: 4.20, waterSavedLiters: 950),
  };

  /// Resolves the [CategoryImpact] for a garment category, falling back to
  /// schema defaults (`6.50` kg CO2 / `1800` L water).
  static CategoryImpact impactForCategory(String category) {
    return categoryImpact[category.trim().toLowerCase()] ??
        const CategoryImpact(
          co2SavedKg: defaultCo2SavedKg,
          waterSavedLiters: defaultWaterSavedLiters,
        );
  }
}
