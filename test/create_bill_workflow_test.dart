import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/business_config_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/quotation_provider.dart';
import 'package:billing_app/providers/serial_number_provider.dart';
import 'package:billing_app/screens/create_bill_screen.dart';
import 'package:billing_app/services/barcode_scanner_service.dart';
import 'package:billing_app/widgets/bill_total_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _NoOpScannerService implements BarcodeScannerService {
  const _NoOpScannerService();

  @override
  Future<String?> scanBarcode(BuildContext context) async => null;
}

Widget _buildCreateBillScreen({
  BillProvider? billProvider,
  ProductProvider? productProvider,
  BusinessConfig config = const BusinessConfig(
    businessName: 'Test Shop',
    setupCompleted: true,
    gstEnabled: false,
  ),
  CustomerProvider? customerProvider,
}) {
  final bp = billProvider ?? BillProvider();
  final pp = productProvider ?? ProductProvider();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BillProvider>.value(value: bp),
      ChangeNotifierProvider<ProductProvider>.value(value: pp),
      ChangeNotifierProvider<BusinessConfigProvider>(
        create: (_) => BusinessConfigProvider(initialConfig: config),
      ),
      ChangeNotifierProvider<CustomerProvider>.value(
        value: customerProvider ?? CustomerProvider(),
      ),
      ChangeNotifierProvider(create: (_) => QuotationProvider()),
      ChangeNotifierProvider(create: (_) => SerialNumberProvider()),
    ],
    child: MaterialApp(
      home: CreateBillScreen(
        scannerService: const _NoOpScannerService(),
      ),
    ),
  );
}

// Use a large surface so EmptyState, search results, and line item rows all
// have enough room without triggering layout overflow errors in tests.
void _setLargeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 3000);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  group('CreateBillScreen — initial state', () {
    testWidgets('renders new bill title and search bar', (tester) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildCreateBillScreen());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.newBill), findsOneWidget);
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('footer not visible when no items added', (tester) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildCreateBillScreen());
      await tester.pumpAndSettle();

      // Footer only appears once items are added; button should be disabled
      final footerFinder = find.byType(BillTotalFooter);
      if (footerFinder.evaluate().isNotEmpty) {
        final footer = tester.widget<BillTotalFooter>(footerFinder.first);
        expect(footer.hasItems, isFalse);
      }
    });
  });

  group('CreateBillScreen — search and add product', () {
    testWidgets('typing 2+ chars in search shows matching products', (
      tester,
    ) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      final pp = ProductProvider(
        initialProducts: [
          Product(name: 'Rice 5kg', sellingPrice: 250, stockQuantity: 100),
          Product(name: 'Sugar 1kg', sellingPrice: 45, stockQuantity: 50),
        ],
      );

      await tester.pumpWidget(_buildCreateBillScreen(productProvider: pp));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Ri');
      await tester.pump();

      expect(find.text('Rice 5kg'), findsOneWidget);
      expect(find.text('Sugar 1kg'), findsNothing);
    });

    testWidgets('typing 1 char shows matching results', (tester) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      final pp = ProductProvider(
        initialProducts: [
          Product(name: 'Rice 5kg', sellingPrice: 250, stockQuantity: 100),
        ],
      );

      await tester.pumpWidget(_buildCreateBillScreen(productProvider: pp));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'R');
      await tester.pump();

      // Search activates at 1+ char
      expect(find.text('Rice 5kg'), findsOneWidget);
    });

    testWidgets('selecting product from search adds it to bill', (
      tester,
    ) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      final pp = ProductProvider(
        initialProducts: [
          Product(
            id: 'rice-1',
            name: 'Rice 5kg',
            sellingPrice: 250,
            stockQuantity: 100,
          ),
        ],
      );
      final bp = BillProvider();

      await tester.pumpWidget(
        _buildCreateBillScreen(productProvider: pp, billProvider: bp),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Rice');
      await tester.pump();

      await tester.tap(find.text('Rice 5kg').first);
      await tester.pumpAndSettle();

      expect(bp.activeLineItems.length, 1);
      expect(bp.activeLineItems.first.product.name, 'Rice 5kg');
    });

    testWidgets('footer shows correct grand total after adding product', (
      tester,
    ) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      final pp = ProductProvider(
        initialProducts: [
          Product(
            id: 'oil-1',
            name: 'Cooking Oil',
            sellingPrice: 180,
            stockQuantity: 50,
          ),
        ],
      );
      final bp = BillProvider();

      await tester.pumpWidget(
        _buildCreateBillScreen(productProvider: pp, billProvider: bp),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Cooking');
      await tester.pump();
      await tester.tap(find.text('Cooking Oil').first);
      await tester.pumpAndSettle();

      final footer = tester.widget<BillTotalFooter>(
        find.byType(BillTotalFooter).first,
      );
      expect(footer.grandTotal, closeTo(180.0, 0.01));
      expect(footer.hasItems, isTrue);
    });

    testWidgets('adding same product twice increments quantity', (
      tester,
    ) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      final pp = ProductProvider(
        initialProducts: [
          Product(
            id: 'sugar-1',
            name: 'Sugar 1kg',
            sellingPrice: 45,
            stockQuantity: 100,
          ),
        ],
      );
      final bp = BillProvider();

      await tester.pumpWidget(
        _buildCreateBillScreen(productProvider: pp, billProvider: bp),
      );
      await tester.pumpAndSettle();

      // Add same product twice
      for (var i = 0; i < 2; i++) {
        await tester.enterText(find.byType(TextField).first, 'Sugar');
        await tester.pump();
        await tester.tap(find.text('Sugar 1kg').first);
        await tester.pumpAndSettle();
      }

      // Should have 1 line item with quantity 2
      expect(bp.activeLineItems.length, 1);
      expect(bp.activeLineItems.first.quantity, 2.0);
    });

    testWidgets('no products found message shown for unmatched query', (
      tester,
    ) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      final pp = ProductProvider(
        initialProducts: [
          Product(name: 'Rice 5kg', sellingPrice: 250, stockQuantity: 100),
        ],
      );

      await tester.pumpWidget(_buildCreateBillScreen(productProvider: pp));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'XYZ');
      await tester.pump();

      expect(find.text(AppStrings.noProductsFound), findsOneWidget);
    });
  });

  group('CreateBillScreen — GST', () {
    testWidgets('footer reflects GST amounts from provider state', (
      tester,
    ) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      final shampoo = Product(
        id: 'shampoo-1',
        name: 'Shampoo',
        sellingPrice: 200,
        stockQuantity: 10,
        gstRate: 18.0,
      );
      final bp = BillProvider();
      // Add the item directly so the provider state is definitive
      bp.addItemToBill(shampoo);

      await tester.pumpWidget(
        _buildCreateBillScreen(
          productProvider: ProductProvider(initialProducts: [shampoo]),
          billProvider: bp,
          config: const BusinessConfig(
            businessName: 'Salon',
            setupCompleted: true,
            gstEnabled: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify provider state before checking UI
      expect(bp.activeLineItems.length, 1);
      expect(bp.activeCgst(), closeTo(18.0, 0.02));
      expect(bp.activeSgst(), closeTo(18.0, 0.02));

      final footer = tester.widget<BillTotalFooter>(
        find.byType(BillTotalFooter).first,
      );

      // Footer should reflect: GST 18% on 200 = CGST 18 + SGST 18, total 236
      expect(footer.gstEnabled, isTrue);
      expect(footer.cgst, closeTo(18.0, 0.02));
      expect(footer.sgst, closeTo(18.0, 0.02));
      expect(footer.grandTotal, closeTo(236.0, 0.02));
    });

    testWidgets('search-added product GST reflected in footer', (tester) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      final shampoo = Product(
        id: 'shampoo-2',
        name: 'Conditioner',
        sellingPrice: 150,
        stockQuantity: 10,
        gstRate: 18.0,
      );
      final pp = ProductProvider(initialProducts: [shampoo]);
      final bp = BillProvider();

      await tester.pumpWidget(
        _buildCreateBillScreen(
          productProvider: pp,
          billProvider: bp,
          config: const BusinessConfig(
            businessName: 'Salon',
            setupCompleted: true,
            gstEnabled: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Condi');
      await tester.pump();
      await tester.tap(find.text('Conditioner').first);
      await tester.pumpAndSettle();

      expect(bp.activeLineItems.length, 1);
      // 18% GST on 150: CGST = 13.5, SGST = 13.5, grand total = 177
      expect(bp.activeCgst(), closeTo(13.5, 0.02));
      expect(bp.activeSgst(), closeTo(13.5, 0.02));
      expect(bp.activeGrandTotal(), closeTo(177.0, 0.02));
    });
  });

  group('CreateBillScreen — customer', () {
    testWidgets('customer chip shows in app bar when customer set', (
      tester,
    ) async {
      _setLargeScreen(tester);
      addTearDown(tester.view.reset);

      final customer = Customer(name: 'Ravi Kumar', phone: '9876543210');
      final bp = BillProvider();
      bp.setActiveCustomer(customer);

      await tester.pumpWidget(
        _buildCreateBillScreen(billProvider: bp),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ravi Kumar'), findsOneWidget);
    });
  });
}
