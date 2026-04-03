import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/services/bill_number_service.dart';
import 'package:billing_app/services/gst_calculator.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/line_item.dart';

void main() {
  group('BillNumberService', () {
    test('generates correct FY format', () {
      final service = BillNumberService();
      final billNumber = service.generateBillNumber();
      expect(billNumber, matches(RegExp(r'^\d{4}-\d{2}/INV-\d{3,}$')));
    });

    test('increments sequentially', () {
      final service = BillNumberService();
      final first = service.generateBillNumber();
      final second = service.generateBillNumber();
      expect(first.endsWith('001'), isTrue);
      expect(second.endsWith('002'), isTrue);
    });

    test('correct FY for current date', () {
      final service = BillNumberService();
      final fy = service.currentFinancialYear;
      final now = DateTime.now();
      if (now.month >= 4) {
        expect(fy, startsWith('${now.year}-'));
      } else {
        expect(fy, startsWith('${now.year - 1}-'));
      }
    });
  });

  group('GstCalculator', () {
    test('calculates CGST and SGST correctly', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        gstRate: 12.0,
      );
      final items = [LineItem(product: product, quantity: 2)];

      expect(GstCalculator.subtotal(items), 200.0);
      expect(GstCalculator.totalCgst(items), 12.0); // 6% of 200
      expect(GstCalculator.totalSgst(items), 12.0); // 6% of 200
    });

    test('handles 0% GST', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        gstRate: 0.0,
      );
      final items = [LineItem(product: product, quantity: 1)];

      expect(GstCalculator.totalCgst(items), 0.0);
      expect(GstCalculator.totalSgst(items), 0.0);
    });

    test('grandTotal with discount', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        gstRate: 0.0,
      );
      final items = [LineItem(product: product, quantity: 2)];

      expect(GstCalculator.grandTotal(items, discount: 50), 150.0);
    });
  });

  group('Product model', () {
    test('isLowStock when stock <= threshold', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 10,
        stockQuantity: 5,
        lowStockThreshold: 10,
      );
      expect(product.isLowStock, isTrue);
      expect(product.isOutOfStock, isFalse);
    });

    test('isOutOfStock when stock is 0', () {
      final product = Product(name: 'Test', sellingPrice: 10, stockQuantity: 0);
      expect(product.isOutOfStock, isTrue);
      expect(product.isLowStock, isFalse);
    });
  });

  group('LineItem model', () {
    test('calculates subtotal correctly', () {
      final product = Product(name: 'Test', sellingPrice: 50);
      final item = LineItem(product: product, quantity: 3);
      expect(item.subtotal, 150.0);
    });

    test('calculates GST correctly for 18% slab', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        gstRate: 18.0,
      );
      final item = LineItem(product: product, quantity: 1);
      expect(item.cgstAmount, 9.0); // 9%
      expect(item.sgstAmount, 9.0); // 9%
      expect(item.totalWithGst, 118.0);
    });
  });
}
