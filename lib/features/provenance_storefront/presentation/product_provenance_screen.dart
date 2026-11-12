import 'package:flutter/material.dart';
import 'package:resaleroute/core/constants/app_colors.dart';
import 'package:resaleroute/core/constants/app_typography.dart';
import 'package:resaleroute/core/constants/sustainability_constants.dart';
import 'package:resaleroute/core/theme/app_theme.dart';

/// Navigable route shell for `/shop/item/:id` (`shopper`, public).
class ProductProvenanceScreen extends StatelessWidget {
  const ProductProvenanceScreen({
    super.key,
    required this.itemId,
    this.qrToken,
  });

  final String itemId;
  final String? qrToken;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final horizontalPadding = AppSpacing.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      backgroundColor: palette.bgCanvas,
      appBar: AppBar(
        title: const Text('Provenance Certificate'),
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
                  'SHA-256 CUSTODY CHAIN',
                  style: AppTypography.labelSm.copyWith(
                    color: palette.accentLuxury,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Garment Details & Provenance Timeline',
                  style: AppTypography.headingMd.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tamper-evident provenance history, condition certificate, '
                  'and atomic escrow checkout.',
                  style: AppTypography.bodyMd.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: palette.bgElevated,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                        border:
                            Border.all(color: palette.borderSubtle, width: 1),
                      ),
                      child: Text(
                        'ITEM_ID: $itemId',
                        style: AppTypography.monoData.copyWith(
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    if (qrToken != null && qrToken!.isNotEmpty)
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
                          'QR_TOKEN: $qrToken',
                          style: AppTypography.monoData.copyWith(
                            color: palette.accentLuxury,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
