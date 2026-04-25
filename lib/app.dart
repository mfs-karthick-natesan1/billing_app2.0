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
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = switch (themeMode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => platformBrightness,
    };
    AppColors.setBrightness(brightness);
    return MaterialApp(
      title: 'BillReady',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      builder: (context, child) {
        AppColors.setBrightness(Theme.of(context).brightness);
        return child!;
      },
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
  const primary = Color(0xFF0D9488);    // teal-600
  const surface = Color(0xFFFFFFFF);
  const background = Color(0xFFF1F5F9); // slate-100
  const onSurface = Color(0xFF0F172A);  // slate-900
  const muted = Color(0xFF64748B);      // slate-500
  const error = Color(0xFFDC2626);      // red-600
  const info = Color(0xFF2563EB);       // blue-600

  final cs = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    onPrimary: Colors.white,
    secondary: info,
    surface: surface,
    onSurface: onSurface,
    error: error,
    brightness: Brightness.light,
  ).copyWith(
    surfaceContainerLowest: background,
    surfaceContainer: surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      surfaceTintColor: surface,
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
      color: surface,
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
      fillColor: background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: muted.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: muted.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: const TextStyle(color: muted, fontSize: 14),
      hintStyle: TextStyle(color: muted.withValues(alpha: 0.6), fontSize: 14),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: background,
      selectedColor: primary.withValues(alpha: 0.15),
      labelStyle: const TextStyle(fontSize: 13, color: onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: muted.withValues(alpha: 0.2)),
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
      color: muted.withValues(alpha: 0.12),
      thickness: 1,
      space: 1,
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: surface,
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
      indicatorColor: Color(0x330D9488),
      elevation: 0,
      minWidth: 220,
      minExtendedWidth: 220,
    ),

    // Popup menu
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
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

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? primary : muted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.4)
              : muted.withValues(alpha: 0.2)),
    ),
  );
}

ThemeData _buildDarkTheme() {
  const primary = Color(0xFF2DD4BF);   // teal-300
  const surface = Color(0xFF1E293B);   // slate-800
  const background = Color(0xFF0F172A); // slate-900
  const onSurface = Color(0xFFE2E8F0); // slate-200
  const muted = Color(0xFF94A3B8);     // slate-400
  const error = Color(0xFFF87171);     // red-400

  final cs = ColorScheme.dark(
    primary: primary,
    onPrimary: const Color(0xFF0F172A),
    secondary: const Color(0xFF60A5FA),
    surface: surface,
    onSurface: onSurface,
    error: error,
    onError: const Color(0xFF0F172A),
    outline: muted,
    surfaceContainerLowest: background,
    surfaceContainer: surface,
    surfaceContainerHighest: const Color(0xFF334155), // slate-700
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      surfaceTintColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.3),
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
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Elevated buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: const Color(0xFF0F172A),
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
        side: BorderSide(color: primary, width: 1.5),
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
      fillColor: const Color(0xFF334155), // slate-700
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: muted.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: muted.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      labelStyle: const TextStyle(color: muted, fontSize: 14),
      hintStyle: TextStyle(color: muted.withValues(alpha: 0.6), fontSize: 14),
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF334155),
      selectedColor: primary.withValues(alpha: 0.2),
      labelStyle: const TextStyle(fontSize: 13, color: onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: muted.withValues(alpha: 0.2)),
    ),

    // FAB
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Color(0xFF0F172A),
      elevation: 3,
      shape: CircleBorder(),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: muted.withValues(alpha: 0.15),
      thickness: 1,
      space: 1,
    ),

    // BottomSheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
    ),

    // Popup menu
    popupMenuTheme: PopupMenuThemeData(
      color: surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 14, color: onSurface),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF334155),
      contentTextStyle: const TextStyle(color: onSurface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      surfaceTintColor: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? primary : muted),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.4)
              : muted.withValues(alpha: 0.2)),
    ),
  );
}
