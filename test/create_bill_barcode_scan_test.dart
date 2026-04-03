import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/business_config_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/screens/create_bill_screen.dart';
import 'package:billing_app/services/barcode_scanner_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeScannerService implements BarcodeScannerService {
  final String? code;

  const _FakeScannerService(this.code);

  @override
  Future<String?> scanBarcode(BuildContext context) async => code;
}

void main() {
  Widget buildTestApp({
    required BillProvider billProvider,
    required ProductProvider productProvider,
    required BarcodeScannerService scannerService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BillProvider>.value(value: billProvider),
        ChangeNotifierProvider<ProductProvider>.value(value: productProvider),
        ChangeNotifierProvider(
          create: (_) => BusinessConfigProvider(
            initialConfig: const BusinessConfig(
              businessName: 'Demo',
              phone: '9876543210',
              setupCompleted: true,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        home: CreateBillScreen(scannerService: scannerService),
      ),
    );
  }

  testWidgets('barcode scan adds matched product to active bill', (
    tester,
  ) async {
    final billProvider = BillProvider();
    final productProvider = ProductProvider(
      initialProducts: [
        Product(
          id: 'p-1',
          name: 'Rice',
          barcode: '890100000001',
          sellingPrice: 50,
          stockQuantity: 10,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        billProvider: billProvider,
        productProvider: productProvider,
        scannerService: const _FakeScannerService('890100000001'),
      ),
    );

    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pumpAndSettle();

    expect(billProvider.activeLineItems.length, 1);
    expect(find.text('Rice'), findsOneWidget);
    expect(
      find.textContaining(AppStrings.productAddedByBarcode),
      findsOneWidget,
    );
  });

  testWidgets('unknown barcode shows error and does not add item', (
    tester,
  ) async {
    final billProvider = BillProvider();
    final productProvider = ProductProvider(
      initialProducts: [
        Product(
          id: 'p-1',
          name: 'Rice',
          barcode: '890100000001',
          sellingPrice: 50,
          stockQuantity: 10,
        ),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(
        billProvider: billProvider,
        productProvider: productProvider,
        scannerService: const _FakeScannerService('890199999999'),
      ),
    );

    await tester.tap(find.byIcon(Icons.qr_code_scanner));
    await tester.pumpAndSettle();

    expect(billProvider.activeLineItems, isEmpty);
    expect(find.text(AppStrings.barcodeNotFound), findsOneWidget);
  });
}
