import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../providers/bill_provider.dart';

class BillHistoryFilterChips extends StatelessWidget {
  final BillFilter selected;
  final int allCount;
  final int todayCount;
  final int thisWeekCount;
  final int thisMonthCount;
  final int cashCount;
  final int creditCount;
  final ValueChanged<BillFilter> onChanged;

  const BillHistoryFilterChips({
    super.key,
    required this.selected,
    required this.allCount,
    required this.todayCount,
    required this.thisWeekCount,
    required this.thisMonthCount,
    required this.cashCount,
    required this.creditCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      child: Row(
        children: [
          _Chip(
            label: '${AppStrings.all} ($allCount)',
            selected: selected == BillFilter.all,
            onTap: () => onChanged(BillFilter.all),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: '${AppStrings.today} ($todayCount)',
            selected: selected == BillFilter.today,
            onTap: () => onChanged(BillFilter.today),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: '${AppStrings.thisWeek} ($thisWeekCount)',
            selected: selected == BillFilter.thisWeek,
            onTap: () => onChanged(BillFilter.thisWeek),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: '${AppStrings.thisMonth} ($thisMonthCount)',
            selected: selected == BillFilter.thisMonth,
            onTap: () => onChanged(BillFilter.thisMonth),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: '${AppStrings.cash} ($cashCount)',
            selected: selected == BillFilter.cash,
            onTap: () => onChanged(BillFilter.cash),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: '${AppStrings.credit} ($creditCount)',
            selected: selected == BillFilter.credit,
            onTap: () => onChanged(BillFilter.credit),
          ),
        ],
      ),
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
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight(0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
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
