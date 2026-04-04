import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/supplier.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/purchase_provider.dart';
import 'package:billing_app/providers/supplier_provider.dart';
import 'package:billing_app/providers/return_provider.dart';
import 'helpers/test_fixtures.dart';

// ── Local test helper for Supplier ──────────────────────────────────────────

Supplier testSupplier({
  String? id,
  String name = 'Test Supplier',
  String? phone,
}) {
  return Supplier(
    id: id,
    name: name,
    phone: phone ?? '9999999999',
  );
}

void main() {
  group('General Store — Full Bill Lifecycle', () {
    test('create product, add to bill, completeBill with cash, verify stock decremented', () {
      final product = generalProduct(stockQuantity: 50);
      final pp = ProductProvider(initialProducts: [product]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      bp.addItemToBill(product);
      bp.updateQuantity(0, 3);

      bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: pp,
        customerProvider: cp,
      );

      expect(pp.products.first.stockQuantity, equals(47));
      expect(bp.bills.length, equals(1));
    });

    test('cash payment works correctly', () {
      final product = generalProduct(sellingPrice: 100, stockQuantity: 20, gstRate: 0);
      final pp = ProductProvider(initialProducts: [product]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      bp.addItemToBill(product);
      bp.updateQuantity(0, 2);

      final bill = bp.completeBill(
        paymentInfo: cashPayment(amountReceived: 200),
        gstEnabled: false,
        productProvider: pp,
        customerProvider: cp,
      );

      expect(bill.paymentMode, equals(PaymentMode.cash));
      expect(bill.grandTotal, equals(200));
      expect(bill.amountReceived, equals(200));
      expect(bill.creditAmount, equals(0));
    });

    test('credit payment increases customer outstandingBalance', () {
      final product = generalProduct(sellingPrice: 500, stockQuantity: 10, gstRate: 0);
      final customer = testCustomer();
      final pp = ProductProvider(initialProducts: [product]);
      final cp = CustomerProvider(initialCustomers: [customer]);
      final bp = BillProvider();

      bp.addItemToBill(product);

      final bill = bp.completeBill(
        paymentInfo: creditPayment(customer: customer, creditAmount: 500),
        gstEnabled: false,
        productProvider: pp,
        customerProvider: cp,
      );

      expect(bill.paymentMode, equals(PaymentMode.credit));
      expect(bill.creditAmount, equals(500));
      expect(cp.customers.first.outstandingBalance, equals(500));
    });

    test('split payment (cash + UPI)', () {
      final product = generalProduct(sellingPrice: 1000, stockQuantity: 10, gstRate: 0);
      final pp = ProductProvider(initialProducts: [product]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      bp.addItemToBill(product);

      final bill = bp.completeBill(
        paymentInfo: splitPayment(cashAmount: 600, upiAmount: 400, amountReceived: 1000),
        gstEnabled: false,
        productProvider: pp,
        customerProvider: cp,
      );

      expect(bill.paymentMode, equals(PaymentMode.split));
      expect(bill.splitCashAmount, equals(600));
      expect(bill.splitUpiAmount, equals(400));
      expect(bill.grandTotal, equals(1000));
    });

    test('bill with GST 18% has correct CGST and SGST', () {
      final product = generalProduct(sellingPrice: 1000, stockQuantity: 10, gstRate: 18.0);
      final pp = ProductProvider(initialProducts: [product]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      bp.addItemToBill(product);

      final bill = bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: pp,
        customerProvider: cp,
      );

      // GST exclusive: taxable = 1000, CGST = 9% of 1000 = 90, SGST = 90
      expect(bill.cgst, closeTo(90.0, 0.02));
      expect(bill.sgst, closeTo(90.0, 0.02));
      expect(bill.grandTotal, closeTo(1180.0, 0.02));
    });

    test('bill with line discount calculates GST on discounted subtotal', () {
      final product = generalProduct(sellingPrice: 1000, stockQuantity: 10, gstRate: 18.0);
      final pp = ProductProvider(initialProducts: [product]);
      final cp = CustomerProvider();
      final bp = BillProvider();

      bp.addItemToBill(product);
      // Apply 10% line discount
      bp.updateLineDiscount(0, 10.0);

      final bill = bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: pp,
        customerProvider: cp,
      );

      // Subtotal = 1000, line discount = 10% = 100, discounted subtotal = 900
      // CGST = 9% of 900 = 81, SGST = 81
      // Grand total = 900 + 81 + 81 = 1062
      expect(bill.cgst, closeTo(81.0, 0.02));
      expect(bill.sgst, closeTo(81.0, 0.02));
      expect(bill.grandTotal, closeTo(1062.0, 0.02));
    });

    test('return validates qty, then increment stock manually', () {
      final product = generalProduct(id: 'ret-prod-1', stockQuantity: 50);
      final pp = ProductProvider(initialProducts: [product]);
      final cp = CustomerProvider();
      final bp = BillProvider();
      final rp = ReturnProvider();

      // Sell 3 units
      bp.addItemToBill(product);
      bp.updateQuantity(0, 3);

      final bill = bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: false,
        productProvider: pp,
        customerProvider: cp,
      );

      expect(pp.products.first.stockQuantity, equals(47));

      // Return 2 units (valid)
      final salesReturn = testReturn(
        billId: bill.id,
        returnNumber: rp.generateReturnNumber(),
        items: [
          returnItem(
            productId: product.id,
            productName: product.name,
            qty: 2,
            pricePerUnit: product.sellingPrice,
          ),
        ],
      );

      rp.addReturn(salesReturn, originalBill: bill);
      pp.incrementStock(product.id, 2);

      expect(pp.products.first.stockQuantity, equals(49));
      expect(rp.returns.length, equals(1));

      // Attempt to return more than remaining (should fail)
      final excessReturn = testReturn(
        billId: bill.id,
        returnNumber: rp.generateReturnNumber(),
        items: [
          returnItem(
            productId: product.id,
            productName: product.name,
            qty: 2,
            pricePerUnit: product.sellingPrice,
          ),
        ],
      );

      expect(
        () => rp.addReturn(excessReturn, originalBill: bill),
        throwsA(isA<StateError>()),
      );
    });

    test('purchase increases stock, supplier payable updates for credit purchase', () {
      final product = generalProduct(id: 'purch-prod-1', stockQuantity: 10);
      final pp = ProductProvider(initialProducts: [product]);
      final sp = SupplierProvider(
        initialSuppliers: [
          testSupplier(id: 'sup-1'),
        ],
      );
      final purchaseProvider = PurchaseProvider();

      final entry = testPurchase(
        productId: product.id,
        productName: product.name,
        qty: 20,
        pricePerUnit: 200,
        paymentMode: PaymentMode.credit,
        supplierId: 'sup-1',
        supplierName: 'Test Supplier',
      );

      purchaseProvider.addPurchase(entry, productProvider: pp, supplierProvider: sp);

      expect(pp.products.first.stockQuantity, equals(30));
      expect(sp.suppliers.first.outstandingPayable, equals(4000));
    });

    test('full cycle: purchase 100, sell 30, return 5, stock = 75', () {
      final product = generalProduct(id: 'cycle-prod-1', stockQuantity: 0, gstRate: 0);
      final pp = ProductProvider(initialProducts: [product]);
      final cp = CustomerProvider();
      final bp = BillProvider();
      final rp = ReturnProvider();
      final purchaseProvider = PurchaseProvider();

      // Purchase 100 units
      final entry = testPurchase(
        productId: product.id,
        productName: product.name,
        qty: 100,
        pricePerUnit: 200,
      );
      purchaseProvider.addPurchase(entry, productProvider: pp);
      expect(pp.products.first.stockQuantity, equals(100));

      // Sell 30 units
      bp.addItemToBill(pp.products.first);
      bp.updateQuantity(0, 30);

      final bill = bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: false,
        productProvider: pp,
        customerProvider: cp,
      );
      expect(pp.products.first.stockQuantity, equals(70));

      // Return 5 units
      final salesReturn = testReturn(
        billId: bill.id,
        returnNumber: rp.generateReturnNumber(),
        items: [
          returnItem(
            productId: product.id,
            productName: product.name,
            qty: 5,
            pricePerUnit: product.sellingPrice,
          ),
        ],
      );
      rp.addReturn(salesReturn, originalBill: bill);
      pp.incrementStock(product.id, 5);

      expect(pp.products.first.stockQuantity, equals(75));
    });
  });
}
