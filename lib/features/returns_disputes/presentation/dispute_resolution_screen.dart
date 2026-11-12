import 'package:flutter/material.dart';
import 'package:resaleroute/core/constants/app_colors.dart';
import 'package:resaleroute/core/constants/app_typography.dart';
import 'package:resaleroute/core/constants/sustainability_constants.dart';
import 'package:resaleroute/core/theme/app_theme.dart';

/// Navigable route shell for `/disputes/:id` (`boutique_owner`, `shopper`).
class DisputeResolutionScreen extends StatelessWidget {
  const DisputeResolutionScreen({
    super.key,
    required this.disputeId,
  });

  final String disputeId;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final horizontalPadding = AppSpacing.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      backgroundColor: palette.bgCanvas,
      appBar: AppBar(
        title: const Text('Escrow Dispute Resolution'),
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
                  '7-DAY RETURN ESCROW',
                  style: AppTypography.labelSm.copyWith(
                    color: palette.statusDanger,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Return Claim & Evidence Review',
                  style: AppTypography.headingMd.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Review shopper return evidence, freeze consignor escrow '
                  'settlement, and record owner resolution verdicts.',
                  style: AppTypography.bodyMd.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: palette.bgElevated,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    border: Border.all(color: palette.borderSubtle, width: 1),
                  ),
                  child: Text(
                    'DISPUTE_ID: $disputeId',
                    style: AppTypography.monoData.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
