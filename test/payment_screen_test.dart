import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/business_config_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/serial_number_provider.dart';
import 'package:billing_app/providers/subscription_provider.dart';
import 'package:billing_app/screens/payment_screen.dart';
import 'package:billing_app/widgets/payment_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _buildPaymentScreen({
  BillProvider? billProvider,
  BusinessConfigProvider? businessConfigProvider,
  CustomerProvider? customerProvider,
  ProductProvider? productProvider,
}) {
  final bp = billProvider ?? BillProvider();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BillProvider>.value(value: bp),
      ChangeNotifierProvider<BusinessConfigProvider>.value(
        value: businessConfigProvider ??
            BusinessConfigProvider(
              initialConfig: const BusinessConfig(
                businessName: 'Test Shop',
                gstEnabled: false,
                setupCompleted: true,
              ),
            ),
      ),
      ChangeNotifierProvider<CustomerProvider>.value(
        value: customerProvider ?? CustomerProvider(),
      ),
      ChangeNotifierProvider<ProductProvider>.value(
        value: productProvider ?? ProductProvider(),
      ),
      ChangeNotifierProvider(create: (_) => SerialNumberProvider()),
      ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
    ],
    child: const MaterialApp(home: PaymentScreen()),
  );
}

// PaymentModeSelector cards have a fixed height of 72px. On the default 800×600
// test surface, "Credit (Udhar)" wraps and causes a layout overflow. Use a wide
// surface so all four labels fit on a single line within the card height.
void _useWideScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1600, 3000);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  group('PaymentScreen — layout', () {
    setUp(() {});

    testWidgets('renders Payment title and summary rows', (tester) async {
      _useWideScreen(tester);
      addTearDown(tester.view.reset);

      final product = Product(
        name: 'Rice 5kg',
        sellingPrice: 500,
        stockQuantity: 10,
      );
      final bp = BillProvider();
      bp.addItemToBill(product);

      await tester.pumpWidget(_buildPaymentScreen(billProvider: bp));
      await tester.pump();

      expect(find.text(AppStrings.payment), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Grand Total'), findsOneWidget);
    });

    testWidgets('payment mode selector renders all four modes', (
      tester,
    ) async {
      _useWideScreen(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildPaymentScreen());
      await tester.pump();

      expect(find.byType(PaymentModeSelector), findsOneWidget);
      expect(find.text(AppStrings.cash), findsOneWidget);
      expect(find.text(AppStrings.upi), findsOneWidget);
      expect(find.text(AppStrings.creditUdhar), findsOneWidget);
      expect(find.text('Split'), findsOneWidget);
    });

    testWidgets('Cash mode selected by default', (tester) async {
      _useWideScreen(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildPaymentScreen());
      await tester.pump();

      final selector = tester.widget<PaymentModeSelector>(
        find.byType(PaymentModeSelector),
      );
      expect(selector.selected, PaymentMode.cash);
    });
  });

  group('PaymentScreen — mode switching', () {
    testWidgets('tapping UPI switches mode', (tester) async {
      _useWideScreen(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildPaymentScreen());
      await tester.pump();

      await tester.tap(find.text(AppStrings.upi));
      await tester.pump();

      final selector = tester.widget<PaymentModeSelector>(
        find.byType(PaymentModeSelector),
      );
      expect(selector.selected, PaymentMode.upi);
    });

    testWidgets('tapping Credit switches mode', (tester) async {
      _useWideScreen(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildPaymentScreen());
      await tester.pump();

      await tester.tap(find.text(AppStrings.creditUdhar));
      await tester.pump();

      final selector = tester.widget<PaymentModeSelector>(
        find.byType(PaymentModeSelector),
      );
      expect(selector.selected, PaymentMode.credit);
    });

    testWidgets('tapping Split switches mode', (tester) async {
      _useWideScreen(tester);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildPaymentScreen());
      await tester.pump();

      await tester.tap(find.text('Split'));
      await tester.pump();

      final selector = tester.widget<PaymentModeSelector>(
        find.byType(PaymentModeSelector),
      );
      expect(selector.selected, PaymentMode.split);
    });
  });

  group('PaymentScreen — GST summary', () {
    testWidgets('CGST and SGST rows visible when GST enabled', (tester) async {
      _useWideScreen(tester);
      addTearDown(tester.view.reset);

      final product = Product(
        name: 'Shampoo',
        sellingPrice: 200,
        stockQuantity: 10,
        gstRate: 18.0,
      );
      final bp = BillProvider();
      bp.addItemToBill(product);

      final configProvider = BusinessConfigProvider(
        initialConfig: const BusinessConfig(
          businessName: 'Test Shop',
          gstEnabled: true,
          setupCompleted: true,
        ),
      );

      await tester.pumpWidget(
        _buildPaymentScreen(
          billProvider: bp,
          businessConfigProvider: configProvider,
        ),
      );
      await tester.pump();

      expect(find.text('CGST'), findsOneWidget);
      expect(find.text('SGST'), findsOneWidget);
    });

    testWidgets('CGST/SGST rows hidden when GST disabled', (tester) async {
      _useWideScreen(tester);
      addTearDown(tester.view.reset);

      final product = Product(
        name: 'Rice',
        sellingPrice: 500,
        stockQuantity: 10,
        gstRate: 5.0,
      );
      final bp = BillProvider();
      bp.addItemToBill(product);

      await tester.pumpWidget(_buildPaymentScreen(billProvider: bp));
      await tester.pump();

      expect(find.text('CGST'), findsNothing);
      expect(find.text('SGST'), findsNothing);
    });
  });

  group('PaymentScreen — pre-selected customer', () {
    testWidgets('pre-selected customer shown in credit mode', (
      tester,
    ) async {
      _useWideScreen(tester);
      addTearDown(tester.view.reset);

      final customer = Customer(name: 'Ravi Kumar', phone: '9876543210');
      final cp = CustomerProvider(initialCustomers: [customer]);
      final bp = BillProvider();
      bp.setActiveCustomer(customer);

      await tester.pumpWidget(
        _buildPaymentScreen(billProvider: bp, customerProvider: cp),
      );
      await tester.pump();

      // Switch to credit mode — customer name is shown in the credit section
      await tester.tap(find.text(AppStrings.creditUdhar));
      await tester.pump();

      expect(find.textContaining('Ravi Kumar'), findsOneWidget);
    });
  });
}
