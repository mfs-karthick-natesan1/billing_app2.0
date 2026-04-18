import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'providers/business_config_provider.dart';
import 'screens/add_edit_product_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/bill_done_screen.dart';
import 'screens/bill_history_screen.dart';
import 'screens/create_bill_screen.dart';
import 'screens/csv_import_screen.dart';
import 'screens/cash_book_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/gstr1_export_screen.dart';
import 'screens/eod_summary_screen.dart';
import 'screens/quotation_list_screen.dart';
import 'screens/home_shell.dart';
import 'screens/purchase_list_screen.dart';
import 'screens/reorder_list_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/supplier_list_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/pending_cheques_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/user_login_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/restaurant/table_screen.dart';
import 'screens/restaurant/take_order_screen.dart';
import 'screens/support_tickets_screen.dart';
import 'screens/workshop/job_card_list_screen.dart';
import 'screens/workshop/job_card_detail_screen.dart';

class BillReadyApp extends StatelessWidget {
  const BillReadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<BusinessConfigProvider, ThemeMode>(
      (p) => p.themeMode,
    );
    return MaterialApp(
      title: 'BillReady',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      routes: {
        '/': (_) => const SplashScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/setup': (_) => const SetupScreen(),
        '/home': (_) => const HomeShell(),
        '/create-bill': (_) => const CreateBillScreen(showBack: true),
        '/payment': (_) => const PaymentScreen(),
        '/bill-done': (_) => const BillDoneScreen(),
        '/add-product': (_) => const AddEditProductScreen(),
        '/bill-history': (_) => const BillHistoryScreen(),
        '/csv-import': (_) => const CsvImportScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/login': (_) => const UserLoginScreen(),
        '/users': (_) => const UserManagementScreen(),
        '/expenses': (_) => const ExpenseListScreen(showBack: true),
        '/cash-book': (_) => const CashBookScreen(showBack: true),
        '/gstr1-export': (_) => const Gstr1ExportScreen(),
        '/suppliers': (_) => const SupplierListScreen(showBack: true),
        '/purchases': (_) => const PurchaseListScreen(showBack: true),
        '/reorder': (_) => const ReorderListScreen(),
        '/eod-summary': (_) => const EodSummaryScreen(),
        '/quotations': (_) => const QuotationListScreen(showBack: true),
        '/reports': (_) => const ReportsScreen(),
        '/tables': (_) => const TableScreen(),
        '/take-order': (_) => const TakeOrderScreen(),
        '/jobs': (_) => const JobCardListScreen(),
        '/job-detail': (_) => const JobCardDetailScreen(),
        '/auth-login': (_) => const AuthLoginScreen(),
        '/auth-signup': (_) => const AuthSignupScreen(),
        '/subscription': (_) => const SubscriptionScreen(),
        '/support-tickets': (_) => const SupportTicketsScreen(),
        '/pending-cheques': (_) => const PendingChequesScreen(),
      },
    );
  }
}

ThemeData _buildLightTheme() {
  const primary = AppColors.primary;
  const onSurface = AppColors.onSurface;

  final cs = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    onPrimary: Colors.white,
    secondary: AppColors.info,
    surface: AppColors.surface,
    onSurface: onSurface,
    error: AppColors.error,
    brightness: Brightness.light,
  ).copyWith(
    surfaceContainerLowest: AppColors.background,
    surfaceContainer: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: onSurface,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: onSurface),
    ),

    // Cards
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.06),
    ),

    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    // Outlined buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),

    // Text buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.muted.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.6), fontSize: 14),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primaryLight(0.15),
      labelStyle: const TextStyle(fontSize: 13, color: onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: AppColors.muted.withValues(alpha: 0.2)),
    ),

    // Floating action button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 3,
      shape: CircleBorder(),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: AppColors.muted.withValues(alpha: 0.12),
      thickness: 1,
      space: 1,
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
    ),

    // Navigation rail
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.sidebarBg,
      selectedIconTheme: IconThemeData(color: AppColors.sidebarTextSelected),
      unselectedIconTheme: IconThemeData(color: AppColors.sidebarText),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.sidebarTextSelected,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: AppColors.sidebarText,
        fontSize: 13,
      ),
      indicatorColor: Color(0x330D9488), // primary at 20% opacity
      elevation: 0,
      minWidth: 220,
      minExtendedWidth: 220,
    ),

    // Popup menu
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 14, color: onSurface),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
    ),
  );
}

ThemeData _buildDarkTheme() {
  const primary = AppColors.primary;

  final cs = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
    primary: const Color(0xFF2DD4BF), // teal-300 for dark mode
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 1),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      shape: const CircleBorder(),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
    ),
  );
}
