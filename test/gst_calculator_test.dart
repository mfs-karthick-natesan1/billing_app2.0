import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/services/gst_calculator.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/line_item.dart';

void main() {
  group('GstCalculator static methods', () {
    test('taxableAmount for exclusive pricing', () {
      final result = GstCalculator.taxableAmount(
        100,
        2,
        inclusive: false,
        gstRate: 18.0,
      );
      expect(result, 200.0);
    });

    test('taxableAmount for inclusive pricing', () {
      // Price 118, qty 1, GST 18% inclusive
      // taxable = 118 / 1.18 = 100
      final result = GstCalculator.taxableAmount(
        118,
        1,
        inclusive: true,
        gstRate: 18.0,
      );
      expect(result, closeTo(100.0, 0.01));
    });

    test('taxableAmount with 0% GST returns line total', () {
      final result = GstCalculator.taxableAmount(
        100,
        3,
        inclusive: false,
        gstRate: 0.0,
      );
      expect(result, 300.0);
    });

    test('cgst is half of GST rate on taxable amount', () {
      expect(GstCalculator.cgst(100, 18.0), closeTo(9.0, 0.01));
      expect(GstCalculator.cgst(100, 12.0), closeTo(6.0, 0.01));
      expect(GstCalculator.cgst(100, 5.0), closeTo(2.5, 0.01));
    });

    test('sgst equals cgst', () {
      expect(GstCalculator.sgst(100, 18.0), GstCalculator.cgst(100, 18.0));
    });

    test('igst is full GST rate on taxable amount', () {
      expect(GstCalculator.igst(100, 18.0), closeTo(18.0, 0.01));
      expect(GstCalculator.igst(100, 5.0), closeTo(5.0, 0.01));
    });
  });

  group('GstCalculator with LineItems', () {
    late Product product18;
    late Product product5;
    late Product product0;

    setUp(() {
      product18 = Product(
        name: 'Widget A',
        sellingPrice: 100,
        stockQuantity: 50,
        gstRate: 18.0,
      );
      product5 = Product(
        name: 'Widget B',
        sellingPrice: 200,
        stockQuantity: 50,
        gstRate: 5.0,
      );
      product0 = Product(
        name: 'Exempt Item',
        sellingPrice: 50,
        stockQuantity: 50,
        gstRate: 0.0,
      );
    });

    test('subtotal sums line item prices × qty', () {
      final items = [
        LineItem(product: product18, quantity: 2),
        LineItem(product: product5, quantity: 1),
      ];
      expect(GstCalculator.subtotal(items), 400.0);
    });

    test('totalCgst sums per-item CGST', () {
      final items = [
        LineItem(product: product18, quantity: 1), // taxable=100, CGST=9
        LineItem(product: product5, quantity: 1),  // taxable=200, CGST=5
      ];
      expect(GstCalculator.totalCgst(items), closeTo(14.0, 0.01));
    });

    test('totalIgst sums per-item IGST', () {
      final items = [
        LineItem(product: product18, quantity: 1), // IGST=18
        LineItem(product: product5, quantity: 1),  // IGST=10
      ];
      expect(GstCalculator.totalIgst(items), closeTo(28.0, 0.01));
    });

    test('totalGst intra-state = CGST + SGST', () {
      final items = [LineItem(product: product18, quantity: 1)];
      expect(
        GstCalculator.totalGst(items, isInterState: false),
        closeTo(18.0, 0.01),
      );
    });

    test('totalGst inter-state = IGST', () {
      final items = [LineItem(product: product18, quantity: 1)];
      expect(
        GstCalculator.totalGst(items, isInterState: true),
        closeTo(18.0, 0.01),
      );
    });

    test('0% GST product contributes no tax', () {
      final items = [LineItem(product: product0, quantity: 3)];
      expect(GstCalculator.totalCgst(items), 0.0);
      expect(GstCalculator.totalSgst(items), 0.0);
      expect(GstCalculator.totalIgst(items), 0.0);
    });

    test('grandTotal with discount applies proportional GST', () {
      final items = [LineItem(product: product18, quantity: 1)];
      // subtotal=100, GST=18, grandTotal without discount=118
      expect(
        GstCalculator.grandTotal(items),
        closeTo(118.0, 0.01),
      );
      // 10% discount: discountedSub=90, ratio=0.9, GST=18*0.9=16.2
      // grandTotal = 90 + 16.2 = 106.2
      expect(
        GstCalculator.grandTotal(items, discount: 10),
        closeTo(106.2, 0.01),
      );
    });

    test('grandTotal with full discount is 0', () {
      final items = [LineItem(product: product18, quantity: 1)];
      expect(GstCalculator.grandTotal(items, discount: 100), 0);
    });
  });

  group('LineItem GST fields', () {
    test('snapshots product gstRate', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        stockQuantity: 10,
        gstRate: 12.0,
      );
      final item = LineItem(product: product);
      expect(item.gstRate, 12.0);
      expect(item.gstInclusivePrice, false);
    });

    test('can override gstRate at billing time', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        stockQuantity: 10,
        gstRate: 12.0,
      );
      final item = LineItem(product: product, gstRate: 18.0);
      expect(item.gstRate, 18.0);
    });

    test('GST inclusive calculates correct taxableAmount', () {
      final product = Product(
        name: 'Inclusive',
        sellingPrice: 118,
        stockQuantity: 10,
        gstRate: 18.0,
        gstInclusivePrice: true,
      );
      final item = LineItem(product: product, quantity: 1);
      expect(item.taxableAmount, closeTo(100.0, 0.01));
      expect(item.cgstAmount, closeTo(9.0, 0.01));
      expect(item.sgstAmount, closeTo(9.0, 0.01));
      expect(item.igstAmount, closeTo(18.0, 0.01));
      expect(item.totalWithGst, closeTo(118.0, 0.01));
    });

    test('GST exclusive calculates correct amounts', () {
      final product = Product(
        name: 'Exclusive',
        sellingPrice: 100,
        stockQuantity: 10,
        gstRate: 18.0,
        gstInclusivePrice: false,
      );
      final item = LineItem(product: product, quantity: 2);
      expect(item.taxableAmount, 200.0);
      expect(item.subtotal, 200.0);
      expect(item.cgstAmount, closeTo(18.0, 0.01));
      expect(item.sgstAmount, closeTo(18.0, 0.01));
      expect(item.igstAmount, closeTo(36.0, 0.01));
      expect(item.totalWithGst, closeTo(236.0, 0.01));
    });

    test('LineItem serialization includes GST fields', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        stockQuantity: 10,
        gstRate: 5.0,
        gstInclusivePrice: true,
      );
      final item = LineItem(product: product, quantity: 3);
      final json = item.toJson();
      expect(json['gstRate'], 5.0);
      expect(json['gstInclusivePrice'], true);

      final restored = LineItem.fromJson(json);
      expect(restored.gstRate, 5.0);
      expect(restored.gstInclusivePrice, true);
      expect(restored.quantity, 3);
    });
  });
}
