import 'dart:convert';

import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/services/image_invoice_service.dart';
import 'package:billing_app/services/pdf_invoice_service.dart';
import 'package:flutter_test/flutter_test.dart';

Bill _buildBill() {
  return Bill(
    billNumber: '2025-26/INV-001',
    lineItems: [
      LineItem(
        product: Product(name: 'Rice 1kg', sellingPrice: 85, stockQuantity: 50),
        quantity: 2,
      ),
    ],
    subtotal: 170,
    grandTotal: 170,
    paymentMode: PaymentMode.cash,
    amountReceived: 200,
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  test('PdfInvoiceService returns non-empty PDF bytes', () async {
    final bytes = await PdfInvoiceService.generateInvoicePdf(
      bill: _buildBill(),
      config: const BusinessConfig(
        businessName: 'Test Shop',
        phone: '9876543210',
      ),
    );

    expect(bytes.length, greaterThan(100));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });

  test(
    'ImageInvoiceService returns PNG bytes',
    () async {
      final bytes = await ImageInvoiceService.generateInvoiceImage(
        bill: _buildBill(),
        config: const BusinessConfig(businessName: 'Test Shop'),
      );

      expect(bytes.length, greaterThan(100));
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    },
    skip: 'Requires platform channel (printing package uses MethodChannel.invokeMethod)',
  );
}
