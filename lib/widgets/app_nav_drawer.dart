import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/business_config.dart';
import '../providers/business_config_provider.dart';
import '../providers/navigation_provider.dart';

class AppNavDrawer extends StatelessWidget {
  const AppNavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final configProvider = context.watch<BusinessConfigProvider>();
    final businessType = configProvider.businessType;
    final businessName = configProvider.businessName;

    final isRestaurantOrWorkshop = businessType == BusinessType.restaurant ||
        businessType == BusinessType.workshop;

    final String tab2Label;
    final IconData tab2Icon;
    if (businessType == BusinessType.restaurant) {
      tab2Label = AppStrings.tablesTitle;
      tab2Icon = Icons.table_restaurant_outlined;
    } else if (businessType == BusinessType.workshop) {
      tab2Label = AppStrings.jobsTitle;
      tab2Icon = Icons.build_outlined;
    } else {
      tab2Label = AppStrings.expensesTitle;
      tab2Icon = Icons.payments_outlined;
    }

    void selectTab(int index) {
      Navigator.pop(context); // close drawer
      navProvider.setTab(index);
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.receipt_long, color: Colors.white, size: 32),
                  const SizedBox(height: 10),
                  Text(
                    businessName.isNotEmpty ? businessName : AppStrings.appName,
                    style: AppTypography.heading.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Nav items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    label: AppStrings.homeTitle,
                    isActive: navProvider.currentTabIndex == 0,
                    onTap: () => selectTab(0),
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: AppStrings.newBill,
                    isActive: navProvider.currentTabIndex == 1,
                    onTap: () => selectTab(1),
                  ),
                  _DrawerItem(
                    icon: tab2Icon,
                    label: tab2Label,
                    isActive: navProvider.currentTabIndex == 2,
                    onTap: () => selectTab(2),
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_outlined,
                    label: AppStrings.productsTitle,
                    isActive: navProvider.currentTabIndex == 3,
                    onTap: () => selectTab(3),
                  ),
                  _DrawerItem(
                    icon: Icons.people_outline,
                    label: AppStrings.customersTitle,
                    isActive: navProvider.currentTabIndex == 4,
                    onTap: () => selectTab(4),
                  ),
                  _DrawerItem(
                    icon: Icons.description_outlined,
                    label: AppStrings.quotationsTitle,
                    isActive: navProvider.currentTabIndex == 5,
                    onTap: () => selectTab(5),
                  ),
                  if (isRestaurantOrWorkshop)
                    _DrawerItem(
                      icon: Icons.payments_outlined,
                      label: AppStrings.expensesTitle,
                      isActive: navProvider.currentTabIndex == 6,
                      onTap: () => selectTab(6),
                    ),
                  _DrawerItem(
                    icon: Icons.shopping_cart_outlined,
                    label: AppStrings.purchasesTitle,
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/purchases');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.store_outlined,
                    label: AppStrings.suppliersTitle,
                    isActive: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/suppliers');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Settings at bottom
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: AppStrings.settingsTitle,
              isActive: false,
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? AppColors.primary : AppColors.onSurface,
        size: 22,
      ),
      title: Text(
        label,
        style: AppTypography.body.copyWith(
          color: isActive ? AppColors.primary : AppColors.onSurface,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      tileColor: isActive ? AppColors.primaryLight(0.08) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      onTap: onTap,
    );
  }
}
