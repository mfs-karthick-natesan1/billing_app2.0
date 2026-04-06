// Regression tests covering Sprint 1 security and correctness fixes on
// branch claude/fix-workflow-issues-UixLc. Each group guards against a
// specific bug that was just fixed so it cannot silently regress.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/return_line_item.dart';
import 'package:billing_app/models/sales_return.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/return_provider.dart';
import 'package:billing_app/providers/user_provider.dart';
import 'package:billing_app/services/db_service.dart';

void main() {
  group('Sprint 1 #9 — return GST proration', () {
    test('partial return pro-rates CGST/SGST from original bill', () {
      final product = Product(
        id: 'p1',
        name: 'Widget',
        sellingPrice: 1000,
        gstRate: 18,
      );
      final line = LineItem(product: product, quantity: 4);
      final bill = Bill(
        billNumber: 'INV-1',
        lineItems: [line],
        subtotal: line.subtotal,
        grandTotal: line.totalWithGst,
        paymentMode: PaymentMode.cash,
      );

      final provider = ReturnProvider();
      final rawReturn = SalesReturn(
        originalBillId: bill.id,
        returnNumber: 'RET-1',
        items: [
          ReturnLineItem(
            productId: 'p1',
            productName: 'Widget',
            quantityReturned: 1,
            pricePerUnit: 1000,
            // Intentionally pass a bogus tax value. The provider must
            // ignore it and pro-rate from the original bill instead.
            cgstAmount: 999,
            sgstAmount: 999,
          ),
        ],
        refundMode: RefundMode.cash,
      );

      provider.addReturn(rawReturn, originalBill: bill);

      final stored = provider.returns.single.items.single;
      // 1/4 of the bill: cgstAmount = 1000*9% = 90 per unit, 90 for 1 unit
      expect(stored.cgstAmount, closeTo(line.cgstAmount / 4, 0.001));
      expect(stored.sgstAmount, closeTo(line.sgstAmount / 4, 0.001));
      expect(stored.refundAmount, closeTo(line.totalWithGst / 4, 0.001));
    });
  });

  group('Sprint 1 #3 — PBKDF2 PIN hashing', () {
    test('hashPin produces pbkdf2-prefixed hash with random salt', () {
      final h1 = UserProvider.hashPin('1234', phone: '9999999999');
      final h2 = UserProvider.hashPin('1234', phone: '9999999999');
      expect(h1, startsWith(r'pbkdf2$'));
      expect(h2, startsWith(r'pbkdf2$'));
      // Random salt → same pin must not produce the same hash.
      expect(h1, isNot(equals(h2)));
    });

    test('verifyPin accepts correct pin and rejects wrong pin', () {
      final stored = UserProvider.hashPin('4321', phone: '9000000000');
      expect(
        UserProvider.verifyPin('4321', stored, phone: '9000000000'),
        isTrue,
      );
      expect(
        UserProvider.verifyPin('0000', stored, phone: '9000000000'),
        isFalse,
      );
    });

    test('verifyPin still accepts legacy sha256(phone|pin|billmaster)', () {
      const phone = '9123456789';
      const pin = '5678';
      final legacy = sha256
          .convert(utf8.encode('$phone|$pin|billmaster'))
          .toString();
      expect(UserProvider.verifyPin(pin, legacy, phone: phone), isTrue);
      expect(UserProvider.verifyPin('0000', legacy, phone: phone), isFalse);
    });
  });

  group('Sprint 1 #21 — BillProvider pendingSave chain', () {
    test('pendingSave chains serial saves without dropping earlier ones',
        () async {
      final provider = BillProvider();
      final fake = _RecordingDbService();
      provider.dbService = fake;

      // Drive two quick saves through the public completeBill entry point.
      final productProvider = _NoopProductProvider();
      final customerProvider = _NoopCustomerProvider();
      final product = Product(name: 'A', sellingPrice: 100, stockQuantity: 5);

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

      // Awaiting pendingSave must drain BOTH queued saves, not just the
      // most recent one (the bug before the fix).
      await provider.pendingSave;
      expect(fake.saveCallCount, 2);
    });
  });
}

class _NoopProductProvider extends ProductProvider {
  @override
  void decrementStock(
    String productId,
    double quantity, {
    String? batchId,
    bool persist = true,
  }) {}
}

class _NoopCustomerProvider extends CustomerProvider {
  @override
  void addCredit(String customerId, double amount, {bool persist = true}) {}
}

// Subclass so we only override the one method under test while skipping
// Supabase initialisation. _client is a getter and is never invoked when
// we don't call super.
class _RecordingDbService extends DbService {
  _RecordingDbService() : super('test-business');

  int saveCallCount = 0;

  @override
  Future<void> saveBills(List<Bill> bills) async {
    // Simulate network latency so two concurrent saves would collide
    // if pendingSave weren't chained.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    saveCallCount++;
  }
}
