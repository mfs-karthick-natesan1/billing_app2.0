import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../models/business_config.dart';
import '../providers/business_config_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/app_nav_drawer.dart';
import 'dashboard_screen.dart';
import 'create_bill_screen.dart';
import 'expense_list_screen.dart';
import 'product_list_screen.dart';
import 'customer_tab_screen.dart';
import 'quotation_list_screen.dart';
import 'restaurant/table_screen.dart';
import 'workshop/job_card_list_screen.dart';

/// Lazy-loading alternative to [IndexedStack].
/// Tabs are only built the first time they are visited, avoiding
/// unnecessary widget construction and provider reads on app startup.
class _LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _LazyIndexedStack({required this.index, required this.children});

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late final List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activated = List.filled(widget.children.length, false);
    _activated[widget.index] = true;
  }

  @override
  void didUpdateWidget(_LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final i = widget.index;
    if (i < _activated.length && !_activated[i]) {
      setState(() => _activated[i] = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(
        widget.children.length,
        (i) => _activated[i] ? widget.children[i] : const SizedBox.shrink(),
      ),
    );
  }
}

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final currentIndex = navProvider.currentTabIndex;
    final businessType = context.watch<BusinessConfigProvider>().businessType;
    final lowStockCount = context.watch<ProductProvider>().lowStockCount;

    Widget tab2;
    if (businessType == BusinessType.restaurant) {
      tab2 = const TableScreen();
    } else if (businessType == BusinessType.workshop ||
        businessType == BusinessType.mobileShop) {
      tab2 = const JobCardListScreen();
    } else {
      tab2 = const ExpenseListScreen();
    }

    final isRestaurantOrWorkshop = businessType == BusinessType.restaurant ||
        businessType == BusinessType.workshop ||
        businessType == BusinessType.mobileShop;

    final tabs = [
      const DashboardScreen(),
      const CreateBillScreen(),
      tab2,
      const ProductListScreen(),
      const CustomerTabScreen(),
      const QuotationListScreen(),
      if (isRestaurantOrWorkshop) const ExpenseListScreen(),
    ];

    return CallbackShortcuts(
      bindings: {
        // Alt+1…6 — jump to tab
        for (var i = 0; i < tabs.length && i < 6; i++)
          SingleActivator(
            LogicalKeyboardKey(0x00100000030 + i), // LogicalKeyboardKey.digit1..6
            alt: true,
          ): () => navProvider.setTab(i),
        // Alt+N — new bill (tab 1)
        const SingleActivator(LogicalKeyboardKey.keyN, alt: true):
            () => navProvider.setTab(1),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 768;

            if (isWide) {
              return _WideLayout(
                currentIndex: currentIndex,
                tabs: tabs,
                businessType: businessType,
                lowStockCount: lowStockCount,
                onTabSelected: navProvider.setTab,
              );
            }

            return _NarrowLayout(
              currentIndex: currentIndex,
              tabs: tabs,
              businessType: businessType,
              lowStockCount: lowStockCount,
              onTabSelected: navProvider.setTab,
            );
          },
        ),
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final int currentIndex;
  final List<Widget> tabs;
  final BusinessType businessType;
  final int lowStockCount;
  final void Function(int) onTabSelected;

  const _NarrowLayout({
    required this.currentIndex,
    required this.tabs,
    required this.businessType,
    required this.lowStockCount,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final navProvider = context.read<NavigationProvider>();
    return Scaffold(
      key: navProvider.scaffoldKey,
      drawer: const AppNavDrawer(),
      body: _LazyIndexedStack(index: currentIndex, children: tabs),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final int currentIndex;
  final List<Widget> tabs;
  final BusinessType businessType;
  final int lowStockCount;
  final void Function(int) onTabSelected;

  const _WideLayout({
    required this.currentIndex,
    required this.tabs,
    required this.businessType,
    required this.lowStockCount,
    required this.onTabSelected,
  });

  NavigationRailDestination _dest(
    IconData icon,
    String label, {
    int? badge,
  }) {
    return NavigationRailDestination(
      icon: badge != null && badge > 0
          ? Badge(label: Text('$badge'), child: Icon(icon))
          : Icon(icon),
      label: Text(label),
    );
  }

  String get _tab2Label {
    if (businessType == BusinessType.restaurant) return AppStrings.tablesTitle;
    if (businessType == BusinessType.workshop ||
        businessType == BusinessType.mobileShop) return AppStrings.jobsTitle;
    return AppStrings.expensesTitle;
  }

  IconData get _tab2Icon {
    if (businessType == BusinessType.restaurant) return Icons.table_restaurant;
    if (businessType == BusinessType.workshop ||
        businessType == BusinessType.mobileShop) return Icons.build;
    return Icons.payments_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.read<NavigationProvider>();

    // How many tab destinations come before the route-only items
    final tabCount = 6 +
        (businessType == BusinessType.restaurant ||
                businessType == BusinessType.workshop ||
                businessType == BusinessType.mobileShop
            ? 1
            : 0);

    void handleDestination(int index) {
      if (index < tabCount) {
        onTabSelected(index);
      } else if (index == tabCount) {
        Navigator.pushNamed(context, '/purchases');
      } else {
        Navigator.pushNamed(context, '/suppliers');
      }
    }

    return Scaffold(
      key: navProvider.scaffoldKey,
      drawer: const AppNavDrawer(),
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Extended sidebar — shows label beside icon
          NavigationRail(
            extended: true,
            selectedIndex: currentIndex < tabCount ? currentIndex : 0,
            onDestinationSelected: handleDestination,
            destinations: [
              _dest(Icons.home_outlined, AppStrings.homeTitle),
              _dest(Icons.receipt_long_outlined, AppStrings.newBill),
              _dest(_tab2Icon, _tab2Label),
              _dest(Icons.inventory_2_outlined, AppStrings.productsTitle,
                  badge: lowStockCount),
              _dest(Icons.people_outline, AppStrings.customersTitle),
              _dest(Icons.description_outlined, AppStrings.quotationsTitle),
              if (businessType == BusinessType.restaurant ||
                  businessType == BusinessType.workshop ||
                  businessType == BusinessType.mobileShop)
                _dest(Icons.payments_outlined, AppStrings.expensesTitle),
              _dest(Icons.shopping_cart_outlined, AppStrings.purchasesTitle),
              _dest(Icons.store_outlined, AppStrings.suppliersTitle),
            ],
          ),
          // Content area — centered with max-width so it doesn't over-stretch
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: _LazyIndexedStack(index: currentIndex, children: tabs),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
