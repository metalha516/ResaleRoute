import 'package:flutter/material.dart';
import 'package:resaleroute/core/constants/app_colors.dart';
import 'package:resaleroute/core/constants/app_typography.dart';
import 'package:resaleroute/core/constants/sustainability_constants.dart';
import 'package:resaleroute/core/theme/app_theme.dart';

/// Navigable route shell for `/consignor/ledger` (`consignor`).
class ConsignorLedgerScreen extends StatelessWidget {
  const ConsignorLedgerScreen({
    super.key,
    this.payoutStatus,
  });

  final String? payoutStatus;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final horizontalPadding = AppSpacing.horizontalPadding(
      MediaQuery.sizeOf(context).width,
    );

    return Scaffold(
      backgroundColor: palette.bgCanvas,
      appBar: AppBar(
        title: const Text('Consignor Ledger'),
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
                  'APPEND-ONLY FINANCIAL LEDGER',
                  style: AppTypography.labelSm.copyWith(
                    color: palette.accentPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Escrow, Available & Lifetime Payouts',
                  style: AppTypography.headingMd.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Deterministic integer-cent ledger summarizing 7-day escrow '
                  'holds, settled funds, and consignor payout disbursements.',
                  style: AppTypography.bodyMd.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                if (payoutStatus != null && payoutStatus!.isNotEmpty) ...[
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
                      'PAYOUT_STATUS: $payoutStatus',
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
