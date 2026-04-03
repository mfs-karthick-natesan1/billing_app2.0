import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/product_batch.dart';
import 'package:billing_app/services/invoice_service.dart';
import 'package:billing_app/services/invoice_share_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InvoiceService', () {
    test('builds whatsapp invoice text with credit due and customer phone', () {
      final config = const BusinessConfig(
        businessName: 'Karthick Stores',
        phone: '9876543210',
        gstEnabled: true,
        gstin: '29ABCDE1234F1Z5',
        showGstinOnInvoice: true,
        showCustomerPhoneOnInvoice: true,
      );

      final bill = Bill(
        billNumber: '2025-26/INV-001',
        lineItems: [
          LineItem(
            product: Product(
              name: 'Rice Bag',
              sellingPrice: 1200,
              stockQuantity: 10,
            ),
            quantity: 1,
          ),
        ],
        subtotal: 1200,
        grandTotal: 1200,
        paymentMode: PaymentMode.credit,
        creditAmount: 1200,
        customer: Customer(name: 'Ravi', phone: '9999999999'),
        timestamp: DateTime(2026, 2, 15, 10, 45),
      );

      final text = InvoiceService.buildWhatsappInvoiceText(
        bill: bill,
        config: config,
      );

      expect(text, contains('*Karthick Stores*'));
      expect(text, contains('GSTIN: 29ABCDE1234F1Z5'));
      expect(text, contains('Customer: Ravi (9999999999)'));
      expect(text, contains('*BALANCE DUE: Rs. 1,200*'));
    });

    test('hides customer phone and includes pharmacy batch details', () {
      final product = Product(
        id: 'prod-1',
        name: 'Paracetamol',
        sellingPrice: 25,
        stockQuantity: 20,
      );
      final batch = ProductBatch(
        productId: product.id,
        batchNumber: 'B-100',
        expiryDate: DateTime(2027, 1, 1),
        stockQuantity: 10,
      );
      final config = const BusinessConfig(
        businessName: 'MediCare',
        businessType: BusinessType.pharmacy,
        showCustomerPhoneOnInvoice: false,
      );
      final bill = Bill(
        billNumber: '2025-26/INV-002',
        lineItems: [LineItem(product: product, quantity: 2, batch: batch)],
        subtotal: 50,
        grandTotal: 50,
        paymentMode: PaymentMode.cash,
        amountReceived: 50,
        customer: Customer(name: 'Asha', phone: '8888888888'),
      );

      final text = InvoiceService.buildWhatsappInvoiceText(
        bill: bill,
        config: config,
      );

      expect(text, contains('Customer: Asha'));
      expect(text, isNot(contains('(8888888888)')));
      expect(text, contains('Batch: B-100'));
      expect(text, contains('Exp:'));
    });

    test('shows UPI payment label for UPI bills', () {
      final config = const BusinessConfig(businessName: 'UPI Mart');
      final bill = Bill(
        billNumber: '2025-26/INV-003',
        lineItems: [
          LineItem(
            product: Product(name: 'Milk', sellingPrice: 30, stockQuantity: 5),
            quantity: 2,
          ),
        ],
        subtotal: 60,
        grandTotal: 60,
        paymentMode: PaymentMode.upi,
        amountReceived: 60,
      );

      final text = InvoiceService.buildWhatsappInvoiceText(
        bill: bill,
        config: config,
      );

      expect(text, contains('Paid: UPI - Rs. 60'));
      expect(text, isNot(contains('BALANCE DUE')));
    });
  });

  group('InvoiceShareService', () {
    test(
      'buildWhatsappUri includes normalized Indian phone and encoded text',
      () {
        final uri = InvoiceShareService.buildWhatsappUri(
          text: 'Invoice total Rs. 100',
          customerPhone: '98765 43210',
        );

        expect(uri.toString(), contains('https://wa.me/919876543210?text='));
        expect(uri.toString(), contains('Invoice%20total%20Rs.%20100'));
      },
    );

    test('buildWhatsappUri omits phone when not available', () {
      final uri = InvoiceShareService.buildWhatsappUri(text: 'Hello');

      expect(uri.toString(), startsWith('https://wa.me/?text='));
    });
  });
}
