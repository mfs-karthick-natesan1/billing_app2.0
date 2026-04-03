import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../providers/cash_book_provider.dart';

class CashBookMonthlySheet extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onDateSelected;

  const CashBookMonthlySheet({
    super.key,
    required this.month,
    required this.onDateSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime month,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CashBookProvider>(),
        child: CashBookMonthlySheet(
          month: month,
          onDateSelected: onDateSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashBookProvider>();
    final year = month.year;
    final monthValue = month.month;
    final firstDay = DateTime(year, monthValue, 1);
    final daysInMonth = DateTime(year, monthValue + 1, 0).day;
    final firstWeekdayOffset = firstDay.weekday % 7;
    final totalTiles = firstWeekdayOffset + daysInMonth;
    final summary = provider.getMonthSummary(monthValue, year);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.monthlyView, style: AppTypography.heading),
          const SizedBox(height: AppSpacing.small),
          Text('${_monthName(monthValue)} $year', style: AppTypography.body),
          const SizedBox(height: AppSpacing.medium),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalTiles,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekdayOffset) {
                return const SizedBox.shrink();
              }
              final dayNumber = index - firstWeekdayOffset + 1;
              final date = DateTime(year, monthValue, dayNumber);
              final day = provider.getCashBookDay(date);
              final isNegative = day.closingBalance < 0;

              return InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () {
                  Navigator.pop(context);
                  onDateSelected(date);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: day.isClosed
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: day.isClosed
                          ? AppColors.success.withValues(alpha: 0.35)
                          : AppColors.muted.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$dayNumber',
                        style: AppTypography.label.copyWith(
                          fontSize: 11,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _compactCurrency(day.closingBalance),
                        style: AppTypography.label.copyWith(
                          fontSize: 10,
                          color: isNegative
                              ? AppColors.error
                              : AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Icon(
                        day.isClosed ? Icons.check_circle : Icons.pending,
                        size: 10,
                        color: day.isClosed
                            ? AppColors.success
                            : AppColors.muted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: AppColors.muted.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.monthSummary,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: AppStrings.totalInflows,
                  value: Formatters.currency(summary.totalInflows),
                  color: AppColors.success,
                ),
                _SummaryRow(
                  label: AppStrings.totalOutflows,
                  value: Formatters.currency(summary.totalOutflows),
                  color: AppColors.error,
                ),
                _SummaryRow(
                  label: AppStrings.netCashFlow,
                  value: Formatters.currency(summary.net),
                  color: summary.net >= 0 ? AppColors.success : AppColors.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }

  String _compactCurrency(double amount) {
    if (amount.abs() >= 1000) {
      return 'Rs.${(amount / 1000).toStringAsFixed(1)}k';
    }
    return 'Rs.${amount.round()}';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.label)),
          Text(
            value,
            style: AppTypography.label.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
