import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/expense.dart';
import '../services/expense_icon_service.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;

  const ExpenseCard({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight(0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                ExpenseIconService.iconForKey(expense.categoryIconKey),
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.categoryLabel,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (expense.description != null &&
                      expense.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      expense.description!,
                      style: AppTypography.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: 4,
                    children: [
                      _MetaChip(
                        icon: Icons.calendar_today,
                        label: Formatters.date(expense.date),
                      ),
                      _MetaChip(
                        icon: Icons.account_balance_wallet,
                        label: expense.paymentMode.label,
                      ),
                      if (expense.vendorName != null &&
                          expense.vendorName!.trim().isNotEmpty)
                        _MetaChip(
                          icon: Icons.storefront,
                          label: expense.vendorName!,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              Formatters.currency(expense.amount),
              style: AppTypography.currency.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.muted),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.label.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
