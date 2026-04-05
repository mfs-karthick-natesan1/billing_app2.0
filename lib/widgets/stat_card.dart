import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      button: onTap != null,
      child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTypography.currency.copyWith(
                color: valueColor ?? AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.label),
          ],
        ),
      ),
      ),
    );
  }
}
