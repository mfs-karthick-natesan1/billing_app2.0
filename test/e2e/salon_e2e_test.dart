import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'helpers/test_fixtures.dart';

void main() {
  group('Salon — Service Billing', () {
    test('service-only bill has no stock changes', () {
      final service = salonService(id: 'salon-svc-1');
      final pp = ProductProvider(initialProducts: [service]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      final stockBefore = pp.products.first.stockQuantity;

      bp.addItemToBill(service);

      bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: pp,
        customerProvider: cp,
      );

      expect(pp.products.first.stockQuantity, equals(stockBefore));
      expect(bp.bills.length, equals(1));
    });

    test('service + retail product — only retail decrements stock', () {
      final service = salonService(id: 'salon-mix-svc');
      final retail = salonRetailProduct(id: 'salon-mix-ret', stockQuantity: 25);
      final pp = ProductProvider(initialProducts: [service, retail]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      final serviceStockBefore = pp.products
          .firstWhere((p) => p.id == 'salon-mix-svc')
          .stockQuantity;

      bp.addItemToBill(service);
      bp.addItemToBill(retail);

      bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: pp,
        customerProvider: cp,
      );

      // Service stock unchanged
      expect(
        pp.products.firstWhere((p) => p.id == 'salon-mix-svc').stockQuantity,
        equals(serviceStockBefore),
      );
      // Retail stock decremented by 1 (default quantity)
      expect(
        pp.products.firstWhere((p) => p.id == 'salon-mix-ret').stockQuantity,
        equals(24),
      );
    });

    test('customer default discount applied to line items', () {
      final service = salonService(id: 'salon-disc-svc', sellingPrice: 200);
      final customer = testCustomer(defaultDiscountPercent: 10);
      final pp = ProductProvider(initialProducts: [service]);
      final cp = CustomerProvider(initialCustomers: [customer]);
      final bp = BillProvider();

      // Set active customer first, then add item
      bp.setActiveCustomer(customer);
      bp.addItemToBill(service);

      // Discount should be applied automatically from customer defaultDiscountPercent
      expect(bp.activeLineItems.first.discountPercent, equals(10));
    });

    test('GST on services calculated correctly', () {
      // salonService has gstRate = 18% by default
      final service = salonService(sellingPrice: 200, gstRate: 18.0);
      final pp = ProductProvider(initialProducts: [service]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      bp.addItemToBill(service);

      final bill = bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: pp,
        customerProvider: cp,
      );

      // Taxable = 200, CGST = 9% of 200 = 18, SGST = 18
      // Grand total = 200 + 18 + 18 = 236
      expect(bill.cgst, closeTo(18.0, 0.02));
      expect(bill.sgst, closeTo(18.0, 0.02));
      expect(bill.grandTotal, closeTo(236.0, 0.02));
    });
  });
}
