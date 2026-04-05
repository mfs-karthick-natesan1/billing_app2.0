import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/services/gst_calculator.dart';

void main() {
  group('Product defaultDiscountPercent', () {
    test('defaults to 0', () {
      final p = Product(name: 'Test', sellingPrice: 100);
      expect(p.defaultDiscountPercent, 0);
    });

    test('stores value', () {
      final p = Product(
        name: 'Test',
        sellingPrice: 100,
        defaultDiscountPercent: 10,
      );
      expect(p.defaultDiscountPercent, 10);
    });

    test('copyWith updates', () {
      final p = Product(name: 'Test', sellingPrice: 100);
      final updated = p.copyWith(defaultDiscountPercent: 15);
      expect(updated.defaultDiscountPercent, 15);
    });

    test('toJson/fromJson round-trip', () {
      final p = Product(
        name: 'Test',
        sellingPrice: 100,
        defaultDiscountPercent: 7.5,
      );
      final json = p.toJson();
      final restored = Product.fromJson(json);
      expect(restored.defaultDiscountPercent, 7.5);
    });
  });

  group('Customer defaultDiscountPercent', () {
    test('defaults to 0', () {
      final c = Customer(name: 'John');
      expect(c.defaultDiscountPercent, 0);
    });

    test('stores value', () {
      final c = Customer(name: 'John', defaultDiscountPercent: 5);
      expect(c.defaultDiscountPercent, 5);
    });

    test('copyWith updates', () {
      final c = Customer(name: 'John');
      final updated = c.copyWith(defaultDiscountPercent: 10);
      expect(updated.defaultDiscountPercent, 10);
    });

    test('toJson/fromJson round-trip', () {
      final c = Customer(name: 'John', defaultDiscountPercent: 12.5);
      final json = c.toJson();
      final restored = Customer.fromJson(json);
      expect(restored.defaultDiscountPercent, 12.5);
    });
  });

  group('LineItem discount', () {
    test('discountPercent defaults to 0', () {
      final item = LineItem(
        product: Product(name: 'P', sellingPrice: 100),
      );
      expect(item.discountPercent, 0);
      expect(item.lineDiscountAmount, 0);
      expect(item.discountedSubtotal, 100);
    });

    test('lineDiscountAmount calculated correctly', () {
      final item = LineItem(
        product: Product(name: 'P', sellingPrice: 200),
        quantity: 2,
        discountPercent: 10,
      );
      // subtotal = 400, discount = 40
      expect(item.subtotal, 400);
      expect(item.lineDiscountAmount, 40);
      expect(item.discountedSubtotal, 360);
    });

    test('taxableAmount uses discountedSubtotal', () {
      final item = LineItem(
        product: Product(name: 'P', sellingPrice: 100, gstRate: 18),
        quantity: 1,
        discountPercent: 10,
      );
      // subtotal = 100, discounted = 90, taxable = 90 (GST exclusive)
      expect(item.discountedSubtotal, 90);
      expect(item.taxableAmount, 90);
    });

    test('taxableAmount with GST inclusive uses discountedSubtotal', () {
      final item = LineItem(
        product: Product(
          name: 'P',
          sellingPrice: 118,
          gstRate: 18,
          gstInclusivePrice: true,
        ),
        quantity: 1,
        discountPercent: 0,
      );
      // subtotal = 118, discounted = 118, taxable = 118 / 1.18 = 100
      expect(item.taxableAmount, closeTo(100, 0.01));
    });

    test('toJson/fromJson preserves discountPercent', () {
      final item = LineItem(
        product: Product(name: 'P', sellingPrice: 50),
        quantity: 3,
        discountPercent: 15,
      );
      final json = item.toJson();
      final restored = LineItem.fromJson(json);
      expect(restored.discountPercent, 15);
    });
  });

  group('Bill discount fields', () {
    test('totalDiscount sums bill and line discounts', () {
      final bill = Bill(
        billNumber: 'INV-001',
        lineItems: [],
        subtotal: 1000,
        discount: 50,
        totalLineDiscount: 30,
        grandTotal: 920,
        paymentMode: PaymentMode.cash,
      );
      expect(bill.totalDiscount, 80);
    });

    test('toJson/fromJson preserves discount fields', () {
      final bill = Bill(
        billNumber: 'INV-002',
        lineItems: [],
        subtotal: 500,
        discount: 25,
        billDiscountPercent: 5,
        totalLineDiscount: 10,
        grandTotal: 465,
        paymentMode: PaymentMode.cash,
      );
      final json = bill.toJson();
      final restored = Bill.fromJson(json);
      expect(restored.discount, 25);
      expect(restored.billDiscountPercent, 5);
      expect(restored.totalLineDiscount, 10);
      expect(restored.totalDiscount, 35);
    });
  });

  group('GstCalculator with line discounts', () {
    test('discountedSubtotal aggregates line discounts', () {
      final items = [
        LineItem(
          product: Product(name: 'A', sellingPrice: 100),
          quantity: 2,
          discountPercent: 10,
        ),
        LineItem(
          product: Product(name: 'B', sellingPrice: 50),
          quantity: 1,
          discountPercent: 0,
        ),
      ];
      // A: 200 - 20 = 180, B: 50 - 0 = 50 → total = 230
      expect(GstCalculator.discountedSubtotal(items), 230);
    });

    test('grandTotal applies bill discount on discounted subtotal', () {
      final items = [
        LineItem(
          product: Product(name: 'A', sellingPrice: 100),
          quantity: 1,
          discountPercent: 10,
        ),
      ];
      // discountedSubtotal = 90, bill discount = 10 → 80
      final total = GstCalculator.grandTotal(items, discount: 10);
      expect(total, 80);
    });
  });

  group('BillProvider discount management', () {
    late BillProvider billProvider;
    late ProductProvider productProvider;
    late CustomerProvider customerProvider;

    setUp(() {
      productProvider = ProductProvider();
      customerProvider = CustomerProvider();
      billProvider = BillProvider();
    });

    test('addItemToBill applies product default discount', () {
      final product = Product(
        name: 'Prod',
        sellingPrice: 100,
        defaultDiscountPercent: 5,
      );
      productProvider.addProduct(product);
      billProvider.addItemToBill(product);

      expect(billProvider.activeLineItems.first.discountPercent, 5);
    });

    test('addItemToBill applies customer discount over product default', () {
      final product = Product(
        name: 'Prod',
        sellingPrice: 100,
        defaultDiscountPercent: 5,
      );
      final customer = Customer(name: 'VIP', defaultDiscountPercent: 15);
      productProvider.addProduct(product);

      billProvider.setActiveCustomer(customer);
      billProvider.addItemToBill(product);

      expect(billProvider.activeLineItems.first.discountPercent, 15);
    });

    test('setActiveCustomer applies discount to existing items', () {
      final product = Product(name: 'Prod', sellingPrice: 100);
      productProvider.addProduct(product);
      billProvider.addItemToBill(product);

      expect(billProvider.activeLineItems.first.discountPercent, 0);

      final customer = Customer(name: 'VIP', defaultDiscountPercent: 10);
      billProvider.setActiveCustomer(customer);

      expect(billProvider.activeLineItems.first.discountPercent, 10);
    });

    test('clearing customer reverts to product defaults', () {
      final product = Product(
        name: 'Prod',
        sellingPrice: 100,
        defaultDiscountPercent: 3,
      );
      productProvider.addProduct(product);
      billProvider.addItemToBill(product);

      final customer = Customer(name: 'VIP', defaultDiscountPercent: 10);
      billProvider.setActiveCustomer(customer);
      expect(billProvider.activeLineItems.first.discountPercent, 10);

      billProvider.setActiveCustomer(null);
      expect(billProvider.activeLineItems.first.discountPercent, 3);
    });

    test('updateLineDiscount changes individual line discount', () {
      final product = Product(name: 'Prod', sellingPrice: 100);
      productProvider.addProduct(product);
      billProvider.addItemToBill(product);

      billProvider.updateLineDiscount(0, 20);
      expect(billProvider.activeLineItems.first.discountPercent, 20);
    });

    test('updateLineDiscount clamps to 0-100', () {
      final product = Product(name: 'Prod', sellingPrice: 100);
      productProvider.addProduct(product);
      billProvider.addItemToBill(product);

      billProvider.updateLineDiscount(0, 150);
      expect(billProvider.activeLineItems.first.discountPercent, 100);

      billProvider.updateLineDiscount(0, -5);
      expect(billProvider.activeLineItems.first.discountPercent, 0);
    });

    test('activeTotalLineDiscount sums all line discounts', () {
      final p1 = Product(name: 'A', sellingPrice: 100);
      final p2 = Product(name: 'B', sellingPrice: 200);
      productProvider.addProduct(p1);
      productProvider.addProduct(p2);
      billProvider.addItemToBill(p1);
      billProvider.addItemToBill(p2);

      billProvider.updateLineDiscount(0, 10); // 100 * 10% = 10
      billProvider.updateLineDiscount(1, 5); // 200 * 5% = 10

      expect(billProvider.activeTotalLineDiscount, 20);
    });

    test('completeBill stores discount fields', () {
      final product = Product(name: 'Prod', sellingPrice: 100, stockQuantity: 10);
      productProvider.addProduct(product);
      billProvider.addItemToBill(product);
      billProvider.updateLineDiscount(0, 10);
      billProvider.setDiscount(isPercent: true, value: 5);

      final bill = billProvider.completeBill(
        paymentInfo: PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(bill.totalLineDiscount, 10); // 100 * 10%
      expect(bill.billDiscountPercent, 5);
      expect(bill.discount, closeTo(4.5, 0.01)); // 90 * 5% = 4.5
    });
  });

  group('CustomerProvider discount support', () {
    test('addCustomer accepts defaultDiscountPercent', () {
      final provider = CustomerProvider();
      final customer = provider.addCustomer(
        name: 'Test',
        defaultDiscountPercent: 8,
      );
      expect(customer.defaultDiscountPercent, 8);
    });

    test('updateCustomer updates defaultDiscountPercent', () {
      final provider = CustomerProvider();
      final customer = provider.addCustomer(name: 'Test');
      expect(customer.defaultDiscountPercent, 0);

      provider.updateCustomer(
        customer.id,
        defaultDiscountPercent: 12,
      );

      final updated = provider.findById(customer.id);
      expect(updated?.defaultDiscountPercent, 12);
    });
  });
}
