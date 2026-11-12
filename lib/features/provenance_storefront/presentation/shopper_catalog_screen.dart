import 'package:flutter/material.dart';
import 'package:resaleroute/core/constants/app_colors.dart';
import 'package:resaleroute/core/constants/app_typography.dart';
import 'package:resaleroute/core/constants/sustainability_constants.dart';
import 'package:resaleroute/core/theme/app_theme.dart';

/// Navigable route shell for `/shop/catalog` (`shopper`, public).
class ShopperCatalogScreen extends StatelessWidget {
  const ShopperCatalogScreen({
    super.key,
    this.category,
    this.grade,
  });

  final String? category;
  final String? grade;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final horizontalPadding = AppSpacing.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      backgroundColor: palette.bgCanvas,
      appBar: AppBar(
        title: const Text('Authenticated Catalog'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: AppSpacing.xl,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: palette.bgSurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
              border: Border.all(color: palette.borderSubtle, width: 1),
              boxShadow: AppTheme.cardShadows(context),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURATED LUXURY RESALE',
                  style: AppTypography.labelSm.copyWith(
                    color: palette.accentLuxury,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Verified Boutique Storefront',
                  style: AppTypography.headingMd.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Browse authenticated pre-owned pieces with condition '
                  'grades, transparent pricing, and QR provenance access.',
                  style: AppTypography.bodyMd.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                if ((category != null && category!.isNotEmpty) ||
                    (grade != null && grade!.isNotEmpty)) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (category != null && category!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.bgElevated,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                            border: Border.all(
                              color: palette.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'CATEGORY: $category',
                            style: AppTypography.monoData.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      if (grade != null && grade!.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: palette.bgElevated,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusPill),
                            border: Border.all(
                              color: palette.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'GRADE: $grade',
                            style: AppTypography.monoData.copyWith(
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
