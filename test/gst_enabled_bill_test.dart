// Regression tests for: gstEnabled param propagation in activeGrandTotal
// and completeBill.
//
// Bug fixed: activeGrandTotal() was called without gstEnabled in
//   payment_screen.dart (×3) and create_bill_screen.dart (×2),
//   causing the payment screen to pre-fill amountReceived with a
//   GST-inclusive total even when the business had GST disabled.
//
// Covers:
//   === activeGrandTotal() ===
//   - gstEnabled=false → grandTotal = subtotal only (no GST added)
//   - gstEnabled=true  → grandTotal = subtotal + GST
//   - default param (gstEnabled=true) → includes GST (backward compat)
//
//   === completeBill() ===
//   - gstEnabled=false → cgst=0, sgst=0, igst=0 stored on bill
//   - gstEnabled=false → grandTotal stored = subtotal (no GST)
//   - gstEnabled=true  → cgst>0, sgst>0 stored when product has gstRate
//   - gstEnabled=true  → grandTotal stored = subtotal + CGST + SGST
//   - isInterState=true + gstEnabled=true → igst>0, cgst=0, sgst=0
//   - gstEnabled=false → amountReceived pre-fill = grandTotal without GST
//
//   === activeCgst / activeSgst / activeIgst ===
//   - activeCgst returns 0 when product has no GST
//   - activeCgst returns correct value for 18% product

import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Minimal stubs ──────────────────────────────────────────────────────────────
class _NoOpProductProvider extends ProductProvider {
  @override
  void decrementStock(String productId, double quantity, {String? batchId}) {}
}

class _NoOpCustomerProvider extends CustomerProvider {
  @override
  void addCredit(String customerId, double amount) {}
}

void main() {
  // ── Fixtures ──────────────────────────────────────────────────────────────────

  /// Product with 18% GST, price Rs. 1000.
  Product makeGstProduct({
    String id = 'gst-p1',
    double price = 1000,
    double gstRate = 18.0,
    bool inclusive = false,
  }) {
    return Product(
      id: id,
      name: 'GST Product',
      sellingPrice: price,
      stockQuantity: 50,
      gstRate: gstRate,
      gstInclusivePrice: inclusive,
    );
  }

  /// Product with no GST.
  Product makeNoGstProduct({String id = 'no-gst-p1', double price = 500}) {
    return Product(
      id: id,
      name: 'No-GST Product',
      sellingPrice: price,
      stockQuantity: 50,
      gstRate: 0,
    );
  }

  BillProvider _providerWithItem(Product product) {
    final bp = BillProvider();
    bp.addItemToBill(product);
    return bp;
  }

  // ── Group 1: activeGrandTotal() ───────────────────────────────────────────────
  group('activeGrandTotal — gstEnabled flag', () {
    test('gstEnabled=false excludes GST from grand total', () {
      // arrange — 18% GST product at Rs. 1000
      final bp = _providerWithItem(makeGstProduct());

      // act
      final total = bp.activeGrandTotal(gstEnabled: false);

      // assert — no GST: total = 1000
      expect(total, closeTo(1000.0, 0.01));
    });

    test('gstEnabled=true includes GST in grand total', () {
      // arrange — 18% GST product at Rs. 1000
      final bp = _providerWithItem(makeGstProduct());

      // act
      final total = bp.activeGrandTotal(gstEnabled: true);

      // assert — with 18% GST: total = 1000 + 90 (CGST) + 90 (SGST) = 1180
      expect(total, closeTo(1180.0, 0.02));
    });

    test('default gstEnabled=true includes GST (backward compatibility)', () {
      final bp = _providerWithItem(makeGstProduct());
      expect(bp.activeGrandTotal(), closeTo(1180.0, 0.02));
    });

    test('gstEnabled=false with zero-GST product — total equals price', () {
      final bp = _providerWithItem(makeNoGstProduct(price: 500));
      expect(bp.activeGrandTotal(gstEnabled: false), closeTo(500.0, 0.01));
    });

    test('gstEnabled=true with zero-GST product — total still equals price', () {
      final bp = _providerWithItem(makeNoGstProduct(price: 500));
      expect(bp.activeGrandTotal(gstEnabled: true), closeTo(500.0, 0.01));
    });

    test('gstEnabled=false ignores GST even with high-rate product (28%)', () {
      final product = makeGstProduct(price: 1000, gstRate: 28.0);
      final bp = _providerWithItem(product);
      expect(bp.activeGrandTotal(gstEnabled: false), closeTo(1000.0, 0.01));
    });

    test('gstEnabled=true with 28% product — total = 1000 + 280', () {
      final product = makeGstProduct(price: 1000, gstRate: 28.0);
      final bp = _providerWithItem(product);
      expect(bp.activeGrandTotal(gstEnabled: true), closeTo(1280.0, 0.02));
    });

    test('inter-state + gstEnabled=true → IGST (not CGST+SGST)', () {
      final bp = _providerWithItem(makeGstProduct());
      final total = bp.activeGrandTotal(isInterState: true, gstEnabled: true);
      // IGST 18% on 1000 = 180; total = 1180
      expect(total, closeTo(1180.0, 0.02));
    });

    test('gstEnabled=false with bill discount — total is subtotal minus discount only', () {
      final bp = _providerWithItem(makeGstProduct(price: 1000, gstRate: 18.0));
      // 10% bill discount: discounted subtotal = 900
      bp.setDiscount(isPercent: true, value: 10);
      final total = bp.activeGrandTotal(gstEnabled: false);
      expect(total, closeTo(900.0, 0.01));
    });
  });

  // ── Group 2: completeBill — stored values when gstEnabled=false ───────────────
  group('completeBill — gstEnabled=false stores zero GST fields', () {
    test('cgst, sgst, igst all zero when gstEnabled=false', () {
      // arrange
      final product = makeGstProduct(); // 18% product
      final bp = _providerWithItem(product);

      // act
      final bill = bp.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 1000,
        ),
        gstEnabled: false,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      // assert — all GST fields stored as zero
      expect(bill.cgst, 0.0);
      expect(bill.sgst, 0.0);
      expect(bill.igst, 0.0);
    });

    test('grandTotal stored as subtotal (no GST) when gstEnabled=false', () {
      final product = makeGstProduct(price: 1000, gstRate: 18.0);
      final bp = _providerWithItem(product);

      final bill = bp.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 1000,
        ),
        gstEnabled: false,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      // grandTotal must equal subtotal — Rs. 1000, not Rs. 1180
      expect(bill.grandTotal, closeTo(1000.0, 0.01));
    });

    test('grandTotal stored correctly when gstEnabled=false and discount applied', () {
      final product = makeGstProduct(price: 1000, gstRate: 18.0);
      final bp = _providerWithItem(product);
      bp.setDiscount(isPercent: true, value: 10); // 10% → Rs. 900

      final bill = bp.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 900,
        ),
        gstEnabled: false,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      expect(bill.grandTotal, closeTo(900.0, 0.01));
      expect(bill.cgst, 0.0);
      expect(bill.sgst, 0.0);
    });
  });

  // ── Group 3: completeBill — stored values when gstEnabled=true ────────────────
  group('completeBill — gstEnabled=true stores correct GST fields', () {
    test('cgst and sgst calculated for 18% product when gstEnabled=true', () {
      final product = makeGstProduct(price: 1000, gstRate: 18.0);
      final bp = _providerWithItem(product);

      final bill = bp.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 1180,
        ),
        gstEnabled: true,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      // 18% GST split equally: CGST = 9%, SGST = 9%
      // CGST = 1000 * 9% = 90; SGST = 90
      expect(bill.cgst, closeTo(90.0, 0.02));
      expect(bill.sgst, closeTo(90.0, 0.02));
      expect(bill.igst, 0.0); // intra-state → no IGST
    });

    test('grandTotal = subtotal + cgst + sgst when gstEnabled=true', () {
      final product = makeGstProduct(price: 1000, gstRate: 18.0);
      final bp = _providerWithItem(product);

      final bill = bp.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 1180,
        ),
        gstEnabled: true,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      expect(bill.grandTotal, closeTo(1180.0, 0.02));
      expect(bill.grandTotal, closeTo(bill.subtotal + bill.cgst + bill.sgst, 0.02));
    });

    test('inter-state: igst set, cgst and sgst zero when gstEnabled=true', () {
      final product = makeGstProduct(price: 1000, gstRate: 18.0);
      final bp = _providerWithItem(product);

      final bill = bp.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 1180,
        ),
        gstEnabled: true,
        isInterState: true,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      expect(bill.igst, closeTo(180.0, 0.02));
      expect(bill.cgst, 0.0);
      expect(bill.sgst, 0.0);
    });

    test('zero-GST product → cgst=0, sgst=0 even with gstEnabled=true', () {
      final product = makeNoGstProduct(price: 500);
      final bp = _providerWithItem(product);

      final bill = bp.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 500,
        ),
        gstEnabled: true,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      expect(bill.cgst, 0.0);
      expect(bill.sgst, 0.0);
      expect(bill.grandTotal, closeTo(500.0, 0.01));
    });
  });

  // ── Group 4: activeCgst / activeSgst / activeIgst helpers ────────────────────
  group('activeCgst / activeSgst / activeIgst', () {
    test('activeCgst returns 0 when product has no GST rate', () {
      final bp = _providerWithItem(makeNoGstProduct());
      expect(bp.activeCgst(), 0.0);
      expect(bp.activeSgst(), 0.0);
    });

    test('activeCgst returns 9% of subtotal for 18% product', () {
      // 18% split: CGST = 9%, SGST = 9%
      // Product price Rs. 1000 → CGST = Rs. 90
      final bp = _providerWithItem(makeGstProduct(price: 1000, gstRate: 18.0));
      expect(bp.activeCgst(), closeTo(90.0, 0.02));
      expect(bp.activeSgst(), closeTo(90.0, 0.02));
    });

    test('activeIgst returns full 18% for inter-state', () {
      final bp = _providerWithItem(makeGstProduct(price: 1000, gstRate: 18.0));
      expect(bp.activeIgst(isInterState: true), closeTo(180.0, 0.02));
    });

    test('activeCgst returns 0 for inter-state transactions', () {
      final bp = _providerWithItem(makeGstProduct(price: 1000, gstRate: 18.0));
      expect(bp.activeCgst(isInterState: true), 0.0);
      expect(bp.activeSgst(isInterState: true), 0.0);
    });

    test('activeIgst returns 0 for intra-state', () {
      final bp = _providerWithItem(makeGstProduct(price: 1000, gstRate: 18.0));
      expect(bp.activeIgst(isInterState: false), 0.0);
    });
  });

  // ── Group 5: amountReceived pre-fill consistency ──────────────────────────────
  // These tests verify the VALUE that payment_screen.dart should pre-fill.
  // The screen reads: activeGrandTotal(isInterState: isInterState, gstEnabled: gstEnabled)
  // After the bug fix, this must match the grandTotal stored in the bill.
  group('amountReceived pre-fill matches stored grandTotal', () {
    test('gstEnabled=false: pre-fill equals stored grandTotal (no inflation)', () {
      final product = makeGstProduct(price: 1000, gstRate: 18.0);
      final bp = _providerWithItem(product);

      // This is what the payment screen now computes for the pre-fill (after fix)
      final preFill = bp.activeGrandTotal(gstEnabled: false);

      // This is what completeBill stores
      final bill = bp.completeBill(
        paymentInfo: PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: preFill, // using the correct pre-fill value
        ),
        gstEnabled: false,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      // The pre-fill must match the stored grandTotal exactly
      expect(preFill, closeTo(bill.grandTotal, 0.01));

      // And crucially: must NOT be inflated with GST
      expect(preFill, closeTo(1000.0, 0.01));
      expect(preFill, isNot(closeTo(1180.0, 1.0)));
    });

    test('gstEnabled=true: pre-fill equals GST-inclusive stored grandTotal', () {
      final product = makeGstProduct(price: 1000, gstRate: 18.0);
      final bp = _providerWithItem(product);

      final preFill = bp.activeGrandTotal(gstEnabled: true);

      final bill = bp.completeBill(
        paymentInfo: PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: preFill,
        ),
        gstEnabled: true,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      expect(preFill, closeTo(bill.grandTotal, 0.01));
      expect(preFill, closeTo(1180.0, 0.02));
    });

    test('gstEnabled=false: amountReceived in bill must NOT exceed grandTotal', () {
      // Regression: old bug caused amountReceived = 1180 but grandTotal = 1000
      final product = makeGstProduct(price: 1000, gstRate: 18.0);
      final bp = _providerWithItem(product);

      final correctPreFill = bp.activeGrandTotal(gstEnabled: false);
      final bill = bp.completeBill(
        paymentInfo: PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: correctPreFill,
        ),
        gstEnabled: false,
        productProvider: _NoOpProductProvider(),
        customerProvider: _NoOpCustomerProvider(),
      );

      // amountReceived must NOT be greater than grandTotal (the old bug)
      expect(
        bill.amountReceived,
        lessThanOrEqualTo(bill.grandTotal + 0.01),
        reason: 'amountReceived should not exceed grandTotal when gstEnabled=false',
      );
    });
  });

  // ── Group 6: paisa rounding ───────────────────────────────────────────────────
  group('GST rounding — paisa precision', () {
    test('CGST and SGST rounded to 2 decimal places', () {
      // 18% on Rs. 333 → CGST = 333 * 9% = 29.97 (clean)
      // 18% on Rs. 100 → CGST = 9.00 (clean)
      // 18% on Rs. 167 → CGST = 167 * 9% = 15.03 (clean)
      final product = Product(
        id: 'round-p1',
        name: 'Odd Price',
        sellingPrice: 167,
        stockQuantity: 10,
        gstRate: 18.0,
      );
      final bp = _providerWithItem(product);

      final cgst = bp.activeCgst();
      final sgst = bp.activeSgst();

      // Verify rounded to at most 2 decimal places
      expect(cgst, equals((cgst * 100).round() / 100));
      expect(sgst, equals((sgst * 100).round() / 100));
    });

    test('grandTotal with GST rounded to 2 decimal places', () {
      final product = Product(
        id: 'round-p2',
        name: 'Odd Price 2',
        sellingPrice: 333,
        stockQuantity: 10,
        gstRate: 12.0,
      );
      final bp = _providerWithItem(product);
      final total = bp.activeGrandTotal(gstEnabled: true);

      expect(total, equals((total * 100).round() / 100));
    });
  });
}
