import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../services/search_service.dart';

class FilterChips extends StatelessWidget {
  final ProductFilter selected;
  final int allCount;
  final int lowStockCount;
  final int outOfStockCount;
  final int expiringSoonCount;
  final bool showExpiringSoon;
  final int serviceCount;
  final bool showServices;
  final ValueChanged<ProductFilter> onChanged;

  const FilterChips({
    super.key,
    required this.selected,
    required this.allCount,
    required this.lowStockCount,
    required this.outOfStockCount,
    this.expiringSoonCount = 0,
    this.showExpiringSoon = false,
    this.serviceCount = 0,
    this.showServices = false,
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
            label: 'All ($allCount)',
            selected: selected == ProductFilter.all,
            onTap: () => onChanged(ProductFilter.all),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: 'Low Stock ($lowStockCount)',
            selected: selected == ProductFilter.lowStock,
            onTap: () => onChanged(ProductFilter.lowStock),
          ),
          const SizedBox(width: AppSpacing.small),
          _Chip(
            label: 'Out of Stock ($outOfStockCount)',
            selected: selected == ProductFilter.outOfStock,
            onTap: () => onChanged(ProductFilter.outOfStock),
          ),
          if (showExpiringSoon) ...[
            const SizedBox(width: AppSpacing.small),
            _Chip(
              label: 'Expiring Soon ($expiringSoonCount)',
              selected: selected == ProductFilter.expiringSoon,
              onTap: () => onChanged(ProductFilter.expiringSoon),
            ),
          ],
          if (showServices) ...[
            const SizedBox(width: AppSpacing.small),
            _Chip(
              label: 'Services ($serviceCount)',
              selected: selected == ProductFilter.services,
              onTap: () => onChanged(ProductFilter.services),
            ),
          ],
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
