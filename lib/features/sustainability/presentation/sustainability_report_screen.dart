import 'package:flutter/material.dart';
import 'package:resaleroute/core/constants/app_colors.dart';
import 'package:resaleroute/core/constants/app_typography.dart';
import 'package:resaleroute/core/constants/sustainability_constants.dart';
import 'package:resaleroute/core/theme/app_theme.dart';

/// Navigable route shell for `/impact` (`boutique_owner`, `shopper`).
class SustainabilityReportScreen extends StatelessWidget {
  const SustainabilityReportScreen({
    super.key,
    this.timeframe,
  });

  final String? timeframe;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final horizontalPadding = AppSpacing.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      backgroundColor: palette.bgCanvas,
      appBar: AppBar(
        title: const Text('Sustainability Impact'),
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
                  'CIRCULARITY METRICS',
                  style: AppTypography.labelSm.copyWith(
                    color: palette.accentPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'CO2 & Water Savings Report',
                  style: AppTypography.headingMd.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Verified carbon and water savings across settled luxury '
                  'garment resales.',
                  style: AppTypography.bodyMd.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                if (timeframe != null && timeframe!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: palette.bgElevated,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                      border: Border.all(color: palette.borderSubtle, width: 1),
                    ),
                    child: Text(
                      'TIMEFRAME: $timeframe',
                      style: AppTypography.monoData.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
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
