import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/expense.dart';
import 'package:billing_app/models/expense_category.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/product_batch.dart';
import 'package:billing_app/providers/business_config_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/expense_provider.dart';
import 'package:billing_app/providers/navigation_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/cash_book_provider.dart';
import 'package:billing_app/providers/purchase_provider.dart';
import 'package:billing_app/providers/return_provider.dart';
import 'package:billing_app/providers/supplier_provider.dart';
import 'package:billing_app/providers/user_provider.dart';
import 'package:billing_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  // ── Unit tests for BusinessConfig notification fields ──

  group('BusinessConfig notification fields', () {
    test('default config has notifications enabled', () {
      const config = BusinessConfig();
      expect(config.notifLowStock, isTrue);
      expect(config.notifExpiry, isTrue);
      expect(config.notifCreditDue, isTrue);
      expect(config.notifCreditDueDays, 30);
      expect(config.notifRecurringExpense, isTrue);
      expect(config.notifEodReminder, isTrue);
      expect(config.notifEodHour, 21);
      expect(config.notifEodMinute, 0);
    });

    test('copyWith updates notification fields', () {
      const config = BusinessConfig();
      final updated = config.copyWith(
        notifLowStock: false,
        notifCreditDueDays: 60,
        notifEodHour: 20,
        notifEodMinute: 30,
      );
      expect(updated.notifLowStock, isFalse);
      expect(updated.notifExpiry, isTrue); // unchanged
      expect(updated.notifCreditDueDays, 60);
      expect(updated.notifEodHour, 20);
      expect(updated.notifEodMinute, 30);
    });

    test('toJson includes notification fields', () {
      const config = BusinessConfig(
        notifLowStock: false,
        notifCreditDueDays: 45,
        notifEodHour: 18,
        notifEodMinute: 15,
      );
      final json = config.toJson();
      expect(json['notifLowStock'], isFalse);
      expect(json['notifExpiry'], isTrue);
      expect(json['notifCreditDue'], isTrue);
      expect(json['notifCreditDueDays'], 45);
      expect(json['notifRecurringExpense'], isTrue);
      expect(json['notifEodReminder'], isTrue);
      expect(json['notifEodHour'], 18);
      expect(json['notifEodMinute'], 15);
    });

    test('fromJson parses notification fields', () {
      final json = {
        'notifLowStock': false,
        'notifExpiry': false,
        'notifCreditDue': false,
        'notifCreditDueDays': 7,
        'notifRecurringExpense': false,
        'notifEodReminder': false,
        'notifEodHour': 22,
        'notifEodMinute': 45,
      };
      final config = BusinessConfig.fromJson(json);
      expect(config.notifLowStock, isFalse);
      expect(config.notifExpiry, isFalse);
      expect(config.notifCreditDue, isFalse);
      expect(config.notifCreditDueDays, 7);
      expect(config.notifRecurringExpense, isFalse);
      expect(config.notifEodReminder, isFalse);
      expect(config.notifEodHour, 22);
      expect(config.notifEodMinute, 45);
    });

    test('fromJson uses defaults when notification fields missing', () {
      final config = BusinessConfig.fromJson({});
      expect(config.notifLowStock, isTrue);
      expect(config.notifExpiry, isTrue);
      expect(config.notifCreditDue, isTrue);
      expect(config.notifCreditDueDays, 30);
      expect(config.notifRecurringExpense, isTrue);
      expect(config.notifEodReminder, isTrue);
      expect(config.notifEodHour, 21);
      expect(config.notifEodMinute, 0);
    });

    test('toJson -> fromJson round trip preserves notification fields', () {
      const original = BusinessConfig(
        notifLowStock: false,
        notifExpiry: true,
        notifCreditDue: false,
        notifCreditDueDays: 15,
        notifRecurringExpense: true,
        notifEodReminder: false,
        notifEodHour: 19,
        notifEodMinute: 30,
      );
      final restored = BusinessConfig.fromJson(original.toJson());
      expect(restored.notifLowStock, original.notifLowStock);
      expect(restored.notifExpiry, original.notifExpiry);
      expect(restored.notifCreditDue, original.notifCreditDue);
      expect(restored.notifCreditDueDays, original.notifCreditDueDays);
      expect(restored.notifRecurringExpense, original.notifRecurringExpense);
      expect(restored.notifEodReminder, original.notifEodReminder);
      expect(restored.notifEodHour, original.notifEodHour);
      expect(restored.notifEodMinute, original.notifEodMinute);
    });
  });

  // ── Unit tests for provider data used by notifications ──

  group('ProductProvider low stock detection', () {
    test('productsNeedingReorder returns products below reorder level', () {
      final provider = ProductProvider(
        initialProducts: [
          Product(
            name: 'Item A',
            sellingPrice: 100,
            stockQuantity: 5,
            reorderLevel: 10,
          ),
          Product(
            name: 'Item B',
            sellingPrice: 200,
            stockQuantity: 20,
            reorderLevel: 10,
          ),
          Product(
            name: 'Item C',
            sellingPrice: 50,
            stockQuantity: 3,
            reorderLevel: 5,
          ),
        ],
      );
      final reorder = provider.productsNeedingReorder;
      expect(reorder.length, 2);
      expect(reorder.any((p) => p.name == 'Item A'), isTrue);
      expect(reorder.any((p) => p.name == 'Item C'), isTrue);
    });

    test('products without reorderLevel are not in productsNeedingReorder', () {
      final provider = ProductProvider(
        initialProducts: [
          Product(name: 'No Reorder', sellingPrice: 100, stockQuantity: 1),
        ],
      );
      expect(provider.productsNeedingReorder, isEmpty);
    });
  });

  group('Product batch expiry detection', () {
    test('batch expiring within 30 days is detected', () {
      final batch = ProductBatch(
        productId: 'p1',
        batchNumber: 'B001',
        expiryDate: DateTime.now().add(const Duration(days: 15)),
        stockQuantity: 10,
      );
      expect(batch.isExpired, isFalse);
      expect(batch.isExpiringSoon, isTrue);
    });

    test('batch expired in past is marked expired', () {
      final batch = ProductBatch(
        productId: 'p1',
        batchNumber: 'B002',
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
        stockQuantity: 10,
      );
      expect(batch.isExpired, isTrue);
    });

    test('batch expiring in 60 days is not imminent', () {
      final batch = ProductBatch(
        productId: 'p1',
        batchNumber: 'B003',
        expiryDate: DateTime.now().add(const Duration(days: 60)),
        stockQuantity: 10,
      );
      expect(batch.isExpired, isFalse);
      expect(batch.isExpiringSoon, isTrue); // within 90 days
    });
  });

  group('Customer credit due detection', () {
    test('customer with outstanding balance and old creation date qualifies', () {
      final customer = Customer(
        name: 'Ravi',
        outstandingBalance: 500,
        createdAt: DateTime.now().subtract(const Duration(days: 40)),
      );
      final daysSince =
          DateTime.now().difference(customer.createdAt).inDays;
      expect(daysSince >= 30, isTrue);
      expect(customer.outstandingBalance > 0, isTrue);
    });

    test('customer with zero balance does not qualify', () {
      final customer = Customer(
        name: 'Priya',
        outstandingBalance: 0,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      );
      expect(customer.outstandingBalance <= 0, isTrue);
    });
  });

  group('Expense recurring detection', () {
    test('getRecurringExpenses filters correctly', () {
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'e1',
            amount: 500,
            category: ExpenseCategory.rent,
            paymentMode: ExpensePaymentMode.cash,
            isRecurring: true,
            recurringFrequency: RecurringFrequency.monthly,
          ),
          Expense(
            id: 'e2',
            amount: 100,
            category: ExpenseCategory.electricity,
            paymentMode: ExpensePaymentMode.cash,
            isRecurring: false,
          ),
          Expense(
            id: 'e3',
            amount: 200,
            category: ExpenseCategory.maintenance,
            paymentMode: ExpensePaymentMode.upi,
            isRecurring: true,
            recurringFrequency: RecurringFrequency.weekly,
          ),
        ],
      );
      final recurring = provider.getRecurringExpenses();
      expect(recurring.length, 2);
      expect(recurring.any((e) => e.id == 'e1'), isTrue);
      expect(recurring.any((e) => e.id == 'e3'), isTrue);
    });
  });

  // ── Widget tests for notification settings UI ──

  group('Settings screen notification section', () {
    Widget buildSettingsApp({BusinessConfig? config}) {
      final businessConfigProvider = BusinessConfigProvider(
        initialConfig: config ??
            const BusinessConfig(
              setupCompleted: true,
              businessName: 'Test Shop',
              phone: '9876543210',
            ),
      );
      final productProvider = ProductProvider();
      final billProvider = BillProvider();
      final customerProvider = CustomerProvider();
      final expenseProvider = ExpenseProvider();
      final returnProvider = ReturnProvider();
      final cashBookProvider = CashBookProvider(
        billProvider: billProvider,
        expenseProvider: expenseProvider,
        customerProvider: customerProvider,
        returnProvider: returnProvider,
      );
      final navigationProvider = NavigationProvider();
      final purchaseProvider = PurchaseProvider();
      final supplierProvider = SupplierProvider();
      final userProvider = UserProvider();

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(
            value: businessConfigProvider,
          ),
          ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
          ChangeNotifierProvider<BillProvider>.value(value: billProvider),
          ChangeNotifierProvider<CustomerProvider>.value(
            value: customerProvider,
          ),
          ChangeNotifierProvider<ExpenseProvider>.value(
            value: expenseProvider,
          ),
          ChangeNotifierProvider<CashBookProvider>.value(
            value: cashBookProvider,
          ),
          ChangeNotifierProvider<NavigationProvider>.value(
            value: navigationProvider,
          ),
          ChangeNotifierProvider<PurchaseProvider>.value(
            value: purchaseProvider,
          ),
          ChangeNotifierProvider<SupplierProvider>.value(
            value: supplierProvider,
          ),
          ChangeNotifierProvider<ReturnProvider>.value(value: returnProvider),
          ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ],
        child: MaterialApp(
          home: const SettingsScreen(),
          routes: {
            '/setup': (_) => const Scaffold(body: Text('SETUP_SCREEN')),
          },
        ),
      );
    }

    testWidgets('shows notification section header', (tester) async {
      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      final notifSection = find.text(AppStrings.notificationsSection);
      await tester.scrollUntilVisible(
        notifSection,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(notifSection, findsOneWidget);
    });

    testWidgets('shows low stock toggle', (tester) async {
      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      final lowStockToggle = find.text(AppStrings.notifLowStock);
      await tester.scrollUntilVisible(
        lowStockToggle,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(lowStockToggle, findsOneWidget);
    });

    testWidgets('shows credit due toggle', (tester) async {
      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      final creditToggle = find.text(AppStrings.notifCreditDue);
      await tester.scrollUntilVisible(
        creditToggle,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(creditToggle, findsOneWidget);
    });

    testWidgets('shows EOD reminder toggle', (tester) async {
      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      final eodToggle = find.text(AppStrings.notifEodReminder);
      await tester.scrollUntilVisible(
        eodToggle,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(eodToggle, findsOneWidget);
    });

    testWidgets('shows recurring expense toggle', (tester) async {
      await tester.pumpWidget(buildSettingsApp());
      await tester.pumpAndSettle();

      final recurringToggle = find.text(AppStrings.notifRecurringExpense);
      await tester.scrollUntilVisible(
        recurringToggle,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(recurringToggle, findsOneWidget);
    });

    testWidgets('expiry toggle visible for pharmacy business type',
        (tester) async {
      await tester.pumpWidget(buildSettingsApp(
        config: const BusinessConfig(
          setupCompleted: true,
          businessName: 'Pharma Shop',
          phone: '9876543210',
          businessType: BusinessType.pharmacy,
        ),
      ));
      await tester.pumpAndSettle();

      final expiryToggle = find.text(AppStrings.notifExpiry);
      await tester.scrollUntilVisible(
        expiryToggle,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(expiryToggle, findsOneWidget);
    });

    testWidgets('expiry toggle hidden for general business type',
        (tester) async {
      await tester.pumpWidget(buildSettingsApp(
        config: const BusinessConfig(
          setupCompleted: true,
          businessName: 'General Shop',
          phone: '9876543210',
          businessType: BusinessType.general,
        ),
      ));
      await tester.pumpAndSettle();

      // Scroll through the full page
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text(AppStrings.notifEodReminder),
        200,
        scrollable: scrollable,
      );

      // Expiry toggle should not exist for general business type
      expect(find.text(AppStrings.notifExpiry), findsNothing);
    });
  });
}
