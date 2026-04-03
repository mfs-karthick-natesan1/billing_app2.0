import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/app_strings.dart';
import '../models/payment_info.dart';

class PaymentModeSelector extends StatelessWidget {
  final PaymentMode selected;
  final ValueChanged<PaymentMode> onChanged;

  const PaymentModeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            icon: Icons.payments,
            label: AppStrings.cash,
            isSelected: selected == PaymentMode.cash,
            onTap: () => onChanged(PaymentMode.cash),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: _ModeCard(
            icon: Icons.qr_code_2,
            label: AppStrings.upi,
            isSelected: selected == PaymentMode.upi,
            onTap: () => onChanged(PaymentMode.upi),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: _ModeCard(
            icon: Icons.account_balance_wallet,
            label: AppStrings.creditUdhar,
            isSelected: selected == PaymentMode.credit,
            onTap: () => onChanged(PaymentMode.credit),
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: _ModeCard(
            icon: Icons.call_split,
            label: 'Split',
            isSelected: selected == PaymentMode.split,
            onTap: () => onChanged(PaymentMode.split),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: isSelected ? AppColors.primary : AppColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
