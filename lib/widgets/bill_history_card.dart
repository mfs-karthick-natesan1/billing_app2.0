import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/bill.dart';
import '../models/payment_info.dart';

class BillHistoryCard extends StatelessWidget {
  final Bill bill;
  final VoidCallback? onTap;

  const BillHistoryCard({super.key, required this.bill, this.onTap});

  @override
  Widget build(BuildContext context) {
    final mode = bill.paymentMode;
    final chipBg = switch (mode) {
      PaymentMode.cash => AppColors.muted.withValues(alpha: 0.10),
      PaymentMode.upi => AppColors.primaryLight(0.12),
      PaymentMode.credit => AppColors.errorLight(0.10),
      PaymentMode.split => AppColors.success.withValues(alpha: 0.12),
      PaymentMode.bankTransfer => AppColors.muted.withValues(alpha: 0.10),
    };
    final chipColor = switch (mode) {
      PaymentMode.cash => AppColors.muted,
      PaymentMode.upi => AppColors.primary,
      PaymentMode.credit => AppColors.error,
      PaymentMode.split => AppColors.success,
      PaymentMode.bankTransfer => AppColors.muted,
    };

    return Semantics(
      label: '${bill.billNumber}, ${Formatters.currency(bill.grandTotal)}, ${mode.label}',
      button: onTap != null,
      child: InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bill.billNumber,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    Formatters.time(bill.timestamp),
                    style: AppTypography.label,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Formatters.currency(bill.grandTotal),
                  style: AppTypography.currency,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.buttonRadius,
                    ),
                  ),
                  child: Text(
                    mode.label,
                    style: AppTypography.label.copyWith(
                      fontSize: 12,
                      color: chipColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
