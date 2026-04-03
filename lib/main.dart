import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app.dart';
import 'app_bootstrap.dart';
import 'models/persisted_app_state.dart';
import 'providers/auth_provider.dart';
import 'providers/bill_provider.dart';
import 'providers/business_config_provider.dart';
import 'providers/cash_book_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/product_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/return_provider.dart';
import 'providers/quotation_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/table_order_provider.dart';
import 'providers/job_card_provider.dart';
import 'providers/serial_number_provider.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/db_service.dart';
import 'services/local_storage_service.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const _AppRoot());
}

/// Root widget — rebuilt (via setState) each time AppBootstrap.restart() is
/// called (e.g., after sign-in / sign-out). runApp() is called exactly once.
class _AppRoot extends StatefulWidget {
  const _AppRoot({super.key});

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late Future<Widget> _appFuture;
  int _restartCount = 0;

  @override
  void initState() {
    super.initState();
    _appFuture = _bootstrap();
    AppBootstrap.restart = () async {
      if (!mounted) return;
      setState(() {
        _restartCount++;
        _appFuture = _bootstrap();
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      // Key changes on every restart → forces full widget tree replacement,
      // discarding the old Navigator so the new initial route takes effect.
      key: ValueKey(_restartCount),
      future: _appFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.data!;
        // Shown while providers are loading (initial start or after restart)
        return const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Color(0xFFF8F9FA),
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}

/// Loads all providers from Supabase (if authenticated) or LocalStorage
/// (mobile offline) and returns the fully-wired MultiProvider + BillReadyApp.
Future<Widget> _bootstrap() async {
  // ── Load initial state ──────────────────────────────────────────────────────
  final session = Supabase.instance.client.auth.currentSession;
  PersistedAppState initialState;
  DbService? dbService;

  if (session != null) {
    await AuthService.loadBusinessId();
    final businessId = AuthService.businessId;
    if (businessId != null) {
      dbService = DbService(businessId);
      try {
        initialState = await dbService.loadAll();
        // First-time migration: if Supabase is empty but local data exists,
        // upload local data to Supabase.
        if (!kIsWeb && !initialState.hasData) {
          final local = LocalStorageService();
          final localState = await local.loadState();
          if (localState.hasData) {
            initialState = localState;
            unawaited(dbService.persistAll(localState));
          }
        }
      } catch (e) {
        debugPrint('BillReady: Supabase load failed: $e');
        // Fall back to local storage so data isn't lost on transient errors
        if (!kIsWeb) {
          try {
            initialState = await LocalStorageService().loadState();
          } catch (_) {
            initialState = const PersistedAppState();
          }
        } else {
          initialState = const PersistedAppState();
        }
      }
    } else {
      initialState = const PersistedAppState();
    }
  } else {
    if (!kIsWeb) {
      final local = LocalStorageService();
      initialState = await local.loadState();
    } else {
      initialState = const PersistedAppState();
    }
  }

  // ── Create providers ────────────────────────────────────────────────────────
  late final BusinessConfigProvider businessConfigProvider;
  late final ProductProvider productProvider;
  late final BillProvider billProvider;
  late final CustomerProvider customerProvider;
  late final ExpenseProvider expenseProvider;
  late final CashBookProvider cashBookProvider;
  late final SupplierProvider supplierProvider;
  late final PurchaseProvider purchaseProvider;
  late final ReturnProvider returnProvider;
  late final QuotationProvider quotationProvider;
  late final UserProvider userProvider;
  late final TableOrderProvider tableOrderProvider;
  late final JobCardProvider jobCardProvider;
  late final SerialNumberProvider serialNumberProvider;
  var providersReady = false;
  Timer? _persistDebounce;

  Future<void> persistAppState() async {
    final state = PersistedAppState(
      businessConfig: businessConfigProvider.config,
      products: productProvider.products,
      stockAdjustments: productProvider.adjustments,
      salesReturns: returnProvider.returns,
      customers: customerProvider.customers,
      bills: billProvider.bills,
      expenses: expenseProvider.expenses,
      customerPaymentEntries: customerProvider.paymentEntries,
      cashBookDays: cashBookProvider.dayLedgers,
      suppliers: supplierProvider.suppliers,
      purchases: purchaseProvider.purchases,
      quotations: quotationProvider.quotations,
      tableOrders: tableOrderProvider.orders,
      jobCards: jobCardProvider.jobCards,
      serialNumbers: serialNumberProvider.all,
      users: userProvider.allUsers,
      currentUserId: userProvider.currentUserId,
      singleUserMode: userProvider.singleUserMode,
      requirePinOnOpen: userProvider.requirePinOnOpen,
      autoLockMinutes: userProvider.autoLockMinutes,
    );
    if (dbService != null) {
      await dbService.persistAll(state);
    } else if (!kIsWeb) {
      await LocalStorageService().saveState(state);
    }
  }

  void schedulePersist() {
    if (!providersReady) return;
    _persistDebounce?.cancel();
    _persistDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(
        persistAppState().catchError(
          (e) => debugPrint('BillReady: persist error: $e'),
        ),
      );
    });
  }

  userProvider = UserProvider(
    initialUsers: initialState.users,
    initialCurrentUserId: initialState.currentUserId,
    singleUserMode: initialState.singleUserMode,
    requirePinOnOpen: initialState.requirePinOnOpen,
    autoLockMinutes: initialState.autoLockMinutes,
    onChanged: schedulePersist,
  );
  businessConfigProvider = BusinessConfigProvider(
    initialConfig: initialState.businessConfig,
    onChanged: schedulePersist,
  )..dbService = dbService;
  productProvider = ProductProvider(
    initialProducts: initialState.products,
    initialAdjustments: initialState.stockAdjustments,
    onChanged: schedulePersist,
  )..dbService = dbService;
  billProvider = BillProvider(
    initialBills: initialState.bills,
    onChanged: schedulePersist,
  )..dbService = dbService;
  customerProvider = CustomerProvider(
    initialCustomers: initialState.customers,
    initialPaymentEntries: initialState.customerPaymentEntries,
    onChanged: schedulePersist,
  )..dbService = dbService;
  expenseProvider = ExpenseProvider(
    initialExpenses: initialState.expenses,
    onChanged: schedulePersist,
  )..dbService = dbService;
  returnProvider = ReturnProvider(
    initialReturns: initialState.salesReturns,
    onChanged: schedulePersist,
  )..dbService = dbService;
  cashBookProvider = CashBookProvider(
    billProvider: billProvider,
    expenseProvider: expenseProvider,
    customerProvider: customerProvider,
    returnProvider: returnProvider,
    initialDays: initialState.cashBookDays,
    onChanged: schedulePersist,
  )..dbService = dbService;
  supplierProvider = SupplierProvider(
    initialSuppliers: initialState.suppliers,
    onChanged: schedulePersist,
  )..dbService = dbService;
  purchaseProvider = PurchaseProvider(
    initialPurchases: initialState.purchases,
    onChanged: schedulePersist,
  )..dbService = dbService;
  quotationProvider = QuotationProvider(
    initialQuotations: initialState.quotations,
    onChanged: schedulePersist,
  )..dbService = dbService;
  tableOrderProvider = TableOrderProvider(
    initialOrders: initialState.tableOrders,
    onChanged: schedulePersist,
  )..dbService = dbService;
  jobCardProvider = JobCardProvider(
    initialJobCards: initialState.jobCards,
    onChanged: schedulePersist,
  )..dbService = dbService;
  serialNumberProvider = SerialNumberProvider()
    ..init(initialState.serialNumbers, schedulePersist);
  providersReady = true;
  unawaited(
    persistAppState().catchError(
      (e) => debugPrint('BillReady: initial persist error: $e'),
    ),
  );

  // Auto-expire overdue quotations on app open
  quotationProvider.expireOverdueQuotations();

  // Process due recurring expenses on app open
  expenseProvider.processDueRecurringExpenses();

  // ── Force update check (Android only) ───────────────────────────────────────
  if (!kIsWeb) {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
      final minBuild = initialState.businessConfig.minBuildNumber;
      if (minBuild > 0 && currentBuild < minBuild) {
        return const _ForceUpdateScreen();
      }
    } catch (_) {}
  }

  // Initialize notifications (mobile only)
  if (!kIsWeb) {
    unawaited(NotificationService.initialize().then((_) {
      NotificationService.scheduleDailyChecks(
        config: businessConfigProvider.config,
        productProvider: productProvider,
        customerProvider: customerProvider,
        expenseProvider: expenseProvider,
      );
    }));
  }

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
      ChangeNotifierProvider<BusinessConfigProvider>.value(
        value: businessConfigProvider,
      ),
      ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
      ChangeNotifierProvider<BillProvider>.value(value: billProvider),
      ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
      ChangeNotifierProvider<ExpenseProvider>.value(value: expenseProvider),
      ChangeNotifierProvider<CashBookProvider>.value(value: cashBookProvider),
      ChangeNotifierProvider<SupplierProvider>.value(value: supplierProvider),
      ChangeNotifierProvider<PurchaseProvider>.value(value: purchaseProvider),
      ChangeNotifierProvider<ReturnProvider>.value(value: returnProvider),
      ChangeNotifierProvider<QuotationProvider>.value(
        value: quotationProvider,
      ),
      ChangeNotifierProvider<UserProvider>.value(value: userProvider),
      ChangeNotifierProvider<TableOrderProvider>.value(
        value: tableOrderProvider,
      ),
      ChangeNotifierProvider<JobCardProvider>.value(value: jobCardProvider),
      ChangeNotifierProvider<SerialNumberProvider>.value(value: serialNumberProvider),
      ChangeNotifierProvider<SubscriptionProvider>(
        create: (_) => SubscriptionProvider(
          businessId: AuthService.businessId,
        ),
      ),
      ChangeNotifierProvider(create: (_) => NavigationProvider()),
    ],
    child: const BillReadyApp(),
  );
}

// ── Force update screen ───────────────────────────────────────────────────────
// Shown when the installed build number is below the minBuildNumber set in
// Supabase. Not dismissible — user must update via Play Store.
const _kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=com.billmaster.app';

class _ForceUpdateScreen extends StatelessWidget {
  const _ForceUpdateScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.system_update_alt, size: 80, color: Color(0xFF0B8B68)),
                const SizedBox(height: 24),
                const Text(
                  'Update Required',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'A new version of the app is available. Please update to continue.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B8B68),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(_kPlayStoreUrl),
                      mode: LaunchMode.platformDefault,
                    ),
                    child: const Text('Update Now', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
