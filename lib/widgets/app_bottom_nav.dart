import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/business_config.dart';
import '../providers/business_config_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final productProvider = context.watch<ProductProvider>();
    final businessType = context.watch<BusinessConfigProvider>().businessType;
    final lowStockCount = productProvider.lowStockCount;

    final IconData tab2Icon;
    final String tab2Label;
    if (businessType == BusinessType.restaurant) {
      tab2Icon = Icons.table_restaurant;
      tab2Label = AppStrings.tablesTitle;
    } else if (businessType == BusinessType.workshop ||
        businessType == BusinessType.mobileShop) {
      tab2Icon = Icons.build;
      tab2Label = AppStrings.jobsTitle;
    } else {
      tab2Icon = Icons.payments_outlined;
      tab2Label = AppStrings.expensesTitle;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavTab(
                icon: Icons.home,
                label: AppStrings.homeTitle,
                isActive: navProvider.currentTabIndex == 0,
                onTap: () => navProvider.setTab(0),
              ),
              _NavTab(
                icon: Icons.receipt_long,
                label: AppStrings.newBill,
                isActive: navProvider.currentTabIndex == 1,
                onTap: () => navProvider.setTab(1),
              ),
              _NavTab(
                icon: tab2Icon,
                label: tab2Label,
                isActive: navProvider.currentTabIndex == 2,
                onTap: () => navProvider.setTab(2),
              ),
              _NavTab(
                icon: Icons.inventory_2,
                label: AppStrings.productsTitle,
                isActive: navProvider.currentTabIndex == 3,
                badgeCount: lowStockCount > 0 ? lowStockCount : null,
                onTap: () => navProvider.setTab(3),
              ),
              _NavTab(
                icon: Icons.people,
                label: AppStrings.customersTitle,
                isActive: navProvider.currentTabIndex == 4,
                onTap: () => navProvider.setTab(4),
              ),
              _NavTab(
                icon: Icons.description_outlined,
                label: AppStrings.quotationsTitle,
                isActive: navProvider.currentTabIndex == 5,
                onTap: () => navProvider.setTab(5),
              ),
              if (businessType == BusinessType.restaurant ||
                  businessType == BusinessType.workshop ||
                  businessType == BusinessType.mobileShop)
                _NavTab(
                  icon: Icons.payments_outlined,
                  label: AppStrings.expensesTitle,
                  isActive: navProvider.currentTabIndex == 6,
                  onTap: () => navProvider.setTab(6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int? badgeCount;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.isActive,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.muted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badgeCount != null,
              label: badgeCount != null ? Text('$badgeCount') : null,
              backgroundColor: AppColors.error,
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.label.copyWith(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
