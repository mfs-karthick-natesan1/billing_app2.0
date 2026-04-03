import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/business_config_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/return_provider.dart';
import 'package:billing_app/screens/bill_done_screen.dart';
import 'package:billing_app/widgets/bill_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Bill _sampleBill() {
  return Bill(
    billNumber: '2025-26/INV-010',
    lineItems: [
      LineItem(
        product: Product(name: 'Milk 1L', sellingPrice: 60, stockQuantity: 10),
        quantity: 2,
      ),
    ],
    subtotal: 120,
    grandTotal: 120,
    paymentMode: PaymentMode.cash,
    amountReceived: 120,
    timestamp: DateTime(2026, 2, 15, 9, 30),
  );
}

void main() {
  testWidgets('BillDoneScreen shows invoice action chips', (tester) async {
    final bill = _sampleBill();
    final configProvider = BusinessConfigProvider(
      initialConfig: const BusinessConfig(businessName: 'Test Shop'),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<BusinessConfigProvider>.value(
        value: configProvider,
        child: MaterialApp(
          initialRoute: '/bill-done',
          onGenerateRoute: (settings) {
            if (settings.name == '/bill-done') {
              return MaterialPageRoute(
                settings: RouteSettings(name: '/bill-done', arguments: bill),
                builder: (_) => const BillDoneScreen(),
              );
            }
            if (settings.name == '/home') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/home'),
                builder: (_) => const Scaffold(body: Text('HOME')),
              );
            }
            if (settings.name == '/create-bill') {
              return MaterialPageRoute(
                settings: const RouteSettings(name: '/create-bill'),
                builder: (_) => const Scaffold(body: Text('CREATE_BILL')),
              );
            }
            return null;
          },
        ),
      ),
    );

    expect(find.text(AppStrings.invoiceActions), findsOneWidget);
    expect(find.text(AppStrings.shareWhatsApp), findsOneWidget);
    expect(find.text(AppStrings.shareSystem), findsOneWidget);
    expect(find.text(AppStrings.copyInvoice), findsOneWidget);
  });

  testWidgets('BillDetailSheet shows invoice action chips', (tester) async {
    final bill = _sampleBill();
    final configProvider = BusinessConfigProvider(
      initialConfig: const BusinessConfig(businessName: 'Test Shop'),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<BusinessConfigProvider>.value(
            value: configProvider,
          ),
          ChangeNotifierProvider<ReturnProvider>(
            create: (_) => ReturnProvider(),
          ),
          ChangeNotifierProvider<ProductProvider>(
            create: (_) => ProductProvider(),
          ),
          ChangeNotifierProvider<CustomerProvider>(
            create: (_) => CustomerProvider(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => BillDetailSheet.show(context, bill),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.invoiceActions),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.invoiceActions), findsOneWidget);
    expect(find.text(AppStrings.shareWhatsApp), findsOneWidget);
    expect(find.text(AppStrings.shareSystem), findsOneWidget);
  });
}
