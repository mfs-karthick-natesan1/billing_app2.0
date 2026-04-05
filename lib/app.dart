import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
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
    return MaterialApp(
      title: 'BillReady',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          surfaceTintColor: AppColors.surface,
          elevation: 0,
        ),
      ),
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
      },
    );
  }
}
