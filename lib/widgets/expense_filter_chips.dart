import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';

class ExpenseDateFilterChips extends StatelessWidget {
  final ExpenseDateFilter selected;
  final ValueChanged<ExpenseDateFilter> onChanged;

  const ExpenseDateFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: AppStrings.allExpensesFilter,
            selected: selected == ExpenseDateFilter.all,
            onTap: () => onChanged(ExpenseDateFilter.all),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: AppStrings.todayFilter,
            selected: selected == ExpenseDateFilter.today,
            onTap: () => onChanged(ExpenseDateFilter.today),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: AppStrings.thisWeekFilter,
            selected: selected == ExpenseDateFilter.thisWeek,
            onTap: () => onChanged(ExpenseDateFilter.thisWeek),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: AppStrings.thisMonthFilter,
            selected: selected == ExpenseDateFilter.thisMonth,
            onTap: () => onChanged(ExpenseDateFilter.thisMonth),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: AppStrings.customRangeFilter,
            selected: selected == ExpenseDateFilter.customRange,
            onTap: () => onChanged(ExpenseDateFilter.customRange),
          ),
        ],
      ),
    );
  }
}

class ExpenseCategoryChips extends StatelessWidget {
  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onChanged;

  const ExpenseCategoryChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: AppStrings.allExpensesFilter,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final category in ExpenseCategory.values) ...[
            const SizedBox(width: AppSpacing.small),
            _Chip(
              label: category.label,
              selected: selected == category,
              onTap: () => onChanged(category),
            ),
          ],
        ],
      ),
    );
  }
}

class ExpensePaymentModeChips extends StatelessWidget {
  final ExpensePaymentMode? selected;
  final ValueChanged<ExpensePaymentMode?> onChanged;

  const ExpensePaymentModeChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(
          label: AppStrings.allPaymentModes,
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        const SizedBox(width: AppSpacing.small),
        _Chip(
          label: ExpensePaymentMode.cash.label,
          selected: selected == ExpensePaymentMode.cash,
          onTap: () => onChanged(ExpensePaymentMode.cash),
        ),
        const SizedBox(width: AppSpacing.small),
        _Chip(
          label: ExpensePaymentMode.upi.label,
          selected: selected == ExpensePaymentMode.upi,
          onTap: () => onChanged(ExpensePaymentMode.upi),
        ),
        const SizedBox(width: AppSpacing.small),
        _Chip(
          label: ExpensePaymentMode.bankTransfer.label,
          selected: selected == ExpensePaymentMode.bankTransfer,
          onTap: () => onChanged(ExpensePaymentMode.bankTransfer),
        ),
        const SizedBox(width: AppSpacing.small),
        _Chip(
          label: ExpensePaymentMode.credit.label,
          selected: selected == ExpensePaymentMode.credit,
          onTap: () => onChanged(ExpensePaymentMode.credit),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
