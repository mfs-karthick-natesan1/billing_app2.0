import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/screens/bill_history_screen.dart';
import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/return_provider.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/providers/business_config_provider.dart';

Widget _buildTestApp(BillProvider billProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BillProvider>.value(value: billProvider),
      ChangeNotifierProvider<ProductProvider>(create: (_) => ProductProvider()),
      ChangeNotifierProvider<CustomerProvider>(
        create: (_) => CustomerProvider(),
      ),
      ChangeNotifierProvider<ReturnProvider>(create: (_) => ReturnProvider()),
      ChangeNotifierProvider<BusinessConfigProvider>(
        create: (_) => BusinessConfigProvider(initialConfig: const BusinessConfig()),
      ),
    ],
    child: const MaterialApp(home: BillHistoryScreen()),
  );
}

class _MockProductProvider extends ProductProvider {
  @override
  void decrementStock(String productId, double quantity, {String? batchId}) {}
}

class _MockCustomerProvider extends CustomerProvider {
  @override
  void addCredit(String customerId, double amount) {}
}

void main() {
  group('BillHistoryScreen', () {
    testWidgets('shows empty state when no bills exist', (tester) async {
      final provider = BillProvider();
      await tester.pumpWidget(_buildTestApp(provider));

      expect(find.text(AppStrings.billHistoryTitle), findsOneWidget);
      expect(find.text(AppStrings.noBillsYet), findsOneWidget);
      expect(find.text(AppStrings.noBillsDesc), findsOneWidget);
    });

    testWidgets('shows search bar and filter chips', (tester) async {
      final provider = BillProvider();
      await tester.pumpWidget(_buildTestApp(provider));

      // Search bar
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text(AppStrings.searchBills), findsOneWidget);

      // Filter chips — check visible ones
      expect(find.text('All (0)'), findsOneWidget);
      expect(find.text('Today (0)'), findsOneWidget);
    });

    testWidgets('shows bills when provider has data', (tester) async {
      final provider = BillProvider();
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();
      final product = Product(
        name: 'Test Item',
        sellingPrice: 200,
        stockQuantity: 50,
      );

      provider.addItemToBill(product);
      provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 200,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      await tester.pumpWidget(_buildTestApp(provider));

      // Should show the bill card instead of empty state
      expect(find.text(AppStrings.noBillsYet), findsNothing);
      expect(find.text('All (1)'), findsOneWidget);
      expect(find.text('Cash (1)'), findsOneWidget);
      expect(find.text('Credit (0)'), findsOneWidget);
    });

    testWidgets('search filters bills', (tester) async {
      final provider = BillProvider();
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();
      final product = Product(
        name: 'Widget',
        sellingPrice: 100,
        stockQuantity: 50,
      );

      provider.addItemToBill(product);
      provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      await tester.pumpWidget(_buildTestApp(provider));

      // Type a search that won't match
      await tester.enterText(find.byType(TextField), 'NONEXISTENT');
      await tester.pump();

      // Should show no results empty state
      expect(find.text(AppStrings.noBillsFound), findsOneWidget);

      // Clear search and type matching query
      await tester.enterText(find.byType(TextField), 'INV');
      await tester.pump();

      // Should show results again
      expect(find.text(AppStrings.noBillsFound), findsNothing);
    });

    testWidgets('tapping filter chip changes active filter', (tester) async {
      final provider = BillProvider();
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();
      final product = Product(
        name: 'Item',
        sellingPrice: 100,
        stockQuantity: 50,
      );

      provider.addItemToBill(product);
      provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      await tester.pumpWidget(_buildTestApp(provider));

      // Tap Credit filter — need to scroll it into view first since chips are scrollable
      await tester.scrollUntilVisible(
        find.text('Credit (0)'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Credit (0)'));
      await tester.pump();

      expect(find.text(AppStrings.noBillsFound), findsOneWidget);

      // Tap Cash filter
      await tester.scrollUntilVisible(
        find.text('Cash (1)'),
        -100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Cash (1)'));
      await tester.pump();

      expect(find.text(AppStrings.noBillsFound), findsNothing);
    });

    testWidgets('tapping bill card opens detail sheet', (tester) async {
      final provider = BillProvider();
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();
      final product = Product(
        name: 'Test Product',
        sellingPrice: 150,
        stockQuantity: 50,
      );

      provider.addItemToBill(product);
      final bill = provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 150,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      await tester.pumpWidget(_buildTestApp(provider));

      // Tap the bill card
      await tester.tap(find.text(bill.billNumber));
      await tester.pumpAndSettle();

      // Bottom sheet should show bill details
      expect(find.text(AppStrings.billDetails), findsOneWidget);
      expect(find.text('Test Product'), findsOneWidget);
    });
  });
}
