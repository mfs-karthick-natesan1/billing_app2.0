import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'helpers/test_fixtures.dart';

void main() {
  group('Clinic — Diagnosis & Visit Notes', () {
    test('bill stores diagnosis and visitNotes', () {
      final service = clinicService();
      final pp = ProductProvider(initialProducts: [service]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      bp.setVisitNotes(
        diagnosis: 'Fever',
        visitNotes: 'Follow up in 3 days',
      );
      bp.addItemToBill(service);

      final bill = bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: pp,
        customerProvider: cp,
      );

      expect(bill.diagnosis, equals('Fever'));
      expect(bill.visitNotes, equals('Follow up in 3 days'));
    });

    test('service products (isService=true) skip stock decrement', () {
      final service = clinicService(id: 'clinic-svc-1');
      final pp = ProductProvider(initialProducts: [service]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      // Service products have stockQuantity = 0 by default and isService = true
      final stockBefore = pp.products.first.stockQuantity;

      bp.addItemToBill(service);

      bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: pp,
        customerProvider: cp,
      );

      // Stock should remain unchanged for services
      expect(pp.products.first.stockQuantity, equals(stockBefore));
    });

    test('mix of services and supplies — only supplies decrement stock', () {
      final service = clinicService(id: 'clinic-mix-svc');
      final supply = clinicSupply(id: 'clinic-mix-sup', stockQuantity: 100);
      final pp = ProductProvider(initialProducts: [service, supply]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      final serviceStockBefore = pp.products
          .firstWhere((p) => p.id == 'clinic-mix-svc')
          .stockQuantity;
      final supplyStockBefore = pp.products
          .firstWhere((p) => p.id == 'clinic-mix-sup')
          .stockQuantity;

      bp.addItemToBill(service);
      bp.addItemToBill(supply);
      bp.updateQuantity(1, 5); // 5 bandage rolls

      bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: pp,
        customerProvider: cp,
      );

      // Service stock unchanged
      expect(
        pp.products.firstWhere((p) => p.id == 'clinic-mix-svc').stockQuantity,
        equals(serviceStockBefore),
      );
      // Supply stock decremented by 5
      expect(
        pp.products.firstWhere((p) => p.id == 'clinic-mix-sup').stockQuantity,
        equals(supplyStockBefore - 5),
      );
    });

    test('GST on consultation services calculated correctly', () {
      // clinicService has gstRate = 18% by default
      final service = clinicService(sellingPrice: 500, gstRate: 18.0);
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

      // Taxable = 500, CGST = 9% of 500 = 45, SGST = 45
      // Grand total = 500 + 45 + 45 = 590
      expect(bill.cgst, closeTo(45.0, 0.02));
      expect(bill.sgst, closeTo(45.0, 0.02));
      expect(bill.grandTotal, closeTo(590.0, 0.02));
    });
  });
}
