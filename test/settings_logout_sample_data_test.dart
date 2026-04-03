import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/cash_book_entry.dart';
import 'package:billing_app/models/expense.dart';
import 'package:billing_app/models/expense_category.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/business_config_provider.dart';
import 'package:billing_app/providers/cash_book_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/expense_provider.dart';
import 'package:billing_app/providers/navigation_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/purchase_provider.dart';
import 'package:billing_app/providers/return_provider.dart';
import 'package:billing_app/providers/supplier_provider.dart';
import 'package:billing_app/providers/user_provider.dart';
import 'package:billing_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'logout and load sample data resets state and navigates to setup',
    (tester) async {
      final businessConfigProvider = BusinessConfigProvider(
        initialConfig: const BusinessConfig(
          setupCompleted: true,
          businessName: 'Demo Shop',
          phone: '9876543210',
          businessType: BusinessType.salon,
        ),
      );
      final productProvider = ProductProvider(
        initialProducts: [
          Product(name: 'Custom Item', sellingPrice: 99, stockQuantity: 1),
        ],
      );
      final billProvider = BillProvider(
        initialBills: [
          Bill(
            billNumber: '2026-27/INV-001',
            lineItems: const [],
            subtotal: 99,
            grandTotal: 99,
            paymentMode: PaymentMode.cash,
            amountReceived: 99,
          ),
        ],
      );
      final customerProvider = CustomerProvider();
      customerProvider.addCustomer(name: 'Ravi', phone: '9999999999');
      customerProvider.addCredit(customerProvider.customers.first.id, 120);

      final expenseProvider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'exp-1',
            amount: 400,
            category: ExpenseCategory.rent,
            paymentMode: ExpensePaymentMode.cash,
          ),
        ],
      );
      final navigationProvider = NavigationProvider()..setTab(3);
      final cashBookProvider = CashBookProvider(
        billProvider: billProvider,
        expenseProvider: expenseProvider,
        customerProvider: customerProvider,
        initialDays: [
          CashBookDay(
            date: DateTime.now().subtract(const Duration(days: 1)),
            openingBalance: 500,
            closingBalance: 620,
          ),
        ],
      );

      final purchaseProvider = PurchaseProvider();
      final supplierProvider = SupplierProvider();
      final returnProvider = ReturnProvider();
      final userProvider = UserProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BusinessConfigProvider>.value(
              value: businessConfigProvider,
            ),
            ChangeNotifierProvider<ProductProvider>.value(
              value: productProvider,
            ),
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
            ChangeNotifierProvider<ReturnProvider>.value(
              value: returnProvider,
            ),
            ChangeNotifierProvider<UserProvider>.value(
              value: userProvider,
            ),
          ],
          child: MaterialApp(
            home: const SettingsScreen(),
            routes: {
              '/setup': (_) => const Scaffold(body: Text('SETUP_SCREEN')),
            },
          ),
        ),
      );

      final logoutActionFinder = find.widgetWithText(
        OutlinedButton,
        AppStrings.logoutAndLoadSampleData,
      );
      await tester.scrollUntilVisible(
        logoutActionFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(logoutActionFinder);
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.logoutAndLoadSampleDataConfirm),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.logoutAction));
      await tester.pumpAndSettle();

      expect(find.text('SETUP_SCREEN'), findsOneWidget);
      expect(businessConfigProvider.isSetupCompleted, isFalse);
      expect(businessConfigProvider.businessType, BusinessType.salon);
      expect(productProvider.products.length, greaterThan(1));
      expect(
        productProvider.products.any(
          (product) => product.name == 'Custom Item',
        ),
        isFalse,
      );
      expect(billProvider.bills.length, 100);
      expect(customerProvider.customers.length, 50);
      expect(expenseProvider.expenses, isEmpty);
      expect(cashBookProvider.dayLedgers, isNotEmpty);
      expect(navigationProvider.currentTabIndex, 0);
    },
  );
}
