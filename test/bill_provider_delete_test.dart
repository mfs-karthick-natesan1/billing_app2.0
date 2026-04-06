// Regression tests for: deleteBill stock restoration + DB delete call
// Bug fixed: deleteBill was not restoring product stock and did not call
//            dbService.deleteRecord — added in this sprint.
//
// Covers:
//   - removes bill from list
//   - increments stock for each non-service line item (stock restored)
//   - does NOT increment stock for service products
//   - no-op when bill number not found
//   - fires _onChanged callback
//   - calls dbService.deleteRecord('bills', bill.id)
//   - full cycle: create → delete → stock equals original

import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/services/db_service.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Spy DbService ──────────────────────────────────────────────────────────────
// Overrides deleteRecord to track calls without hitting Supabase.
class _SpyDbService extends DbService {
  final List<({String table, String id})> deletedRecords = [];

  _SpyDbService() : super('test-business-id');

  @override
  Future<void> deleteRecord(String table, String id) async {
    deletedRecords.add((table: table, id: id));
  }
}

// ── Minimal stubs ──────────────────────────────────────────────────────────────
class _NoOpCustomerProvider extends CustomerProvider {
  @override
  void addCredit(String customerId, double amount) {}
}

void main() {
  // ── Fixtures ─────────────────────────────────────────────────────────────────

  Product makeProduct({
    String id = 'p1',
    String name = 'Widget',
    double price = 100,
    int stock = 10,
    bool isService = false,
  }) {
    return Product(
      id: id,
      name: name,
      sellingPrice: price,
      stockQuantity: stock,
      isService: isService,
    );
  }

  // Completes a single-item bill and returns the bill number.
  String _completeBillWith({
    required BillProvider billProvider,
    required ProductProvider productProvider,
    required Product product,
    PaymentMode mode = PaymentMode.cash,
  }) {
    billProvider.addItemToBill(product);
    final bill = billProvider.completeBill(
      paymentInfo: PaymentInfo(
        mode: mode,
        amountReceived: mode == PaymentMode.cash ? product.sellingPrice : 0,
        creditAmount: mode == PaymentMode.credit ? product.sellingPrice : 0,
        customer: mode == PaymentMode.credit ? Customer(name: 'Test') : null,
      ),
      gstEnabled: false,
      productProvider: productProvider,
      customerProvider: _NoOpCustomerProvider(),
    );
    return bill.billNumber;
  }

  // ── Group 1: list management ──────────────────────────────────────────────────
  group('deleteBill — list management', () {
    test('removes bill from bills list', () {
      // arrange
      final product = makeProduct();
      final productProvider = ProductProvider(initialProducts: [product]);
      final billProvider = BillProvider();
      final billNumber = _completeBillWith(
        billProvider: billProvider,
        productProvider: productProvider,
        product: product,
      );
      expect(billProvider.allBillCount, 1);

      // act
      billProvider.deleteBill(billNumber, productProvider: productProvider);

      // assert
      expect(billProvider.allBillCount, 0);
    });

    test('no-op when bill number not found', () {
      // arrange
      final product = makeProduct();
      final productProvider = ProductProvider(initialProducts: [product]);
      final billProvider = BillProvider();
      _completeBillWith(
        billProvider: billProvider,
        productProvider: productProvider,
        product: product,
      );

      // act — delete a non-existent bill
      billProvider.deleteBill('INV-DOES-NOT-EXIST', productProvider: productProvider);

      // assert — original bill still present
      expect(billProvider.allBillCount, 1);
      expect(productProvider.findById('p1')!.stockQuantity, 9); // decremented by completeBill, unchanged by no-op delete
    });

    test('fires onChanged callback when bill is deleted', () {
      // arrange
      int callCount = 0;
      final product = makeProduct();
      final productProvider = ProductProvider(initialProducts: [product]);
      final billProvider = BillProvider(onChanged: () => callCount++);
      final billNumber = _completeBillWith(
        billProvider: billProvider,
        productProvider: productProvider,
        product: product,
      );
      final countBefore = callCount;

      // act
      billProvider.deleteBill(billNumber, productProvider: productProvider);

      // assert
      expect(callCount, greaterThan(countBefore));
    });
  });

  // ── Group 2: stock restoration (the key regression) ───────────────────────────
  group('deleteBill — stock restoration', () {
    test('restores stock for non-service product after bill deleted', () {
      // arrange
      final product = makeProduct(stock: 10);
      final productProvider = ProductProvider(initialProducts: [product]);
      final billProvider = BillProvider();
      final billNumber = _completeBillWith(
        billProvider: billProvider,
        productProvider: productProvider,
        product: product,
      );
      // completeBill decrements stock from 10 → 9
      expect(productProvider.findById('p1')!.stockQuantity, 9);

      // act
      billProvider.deleteBill(billNumber, productProvider: productProvider);

      // assert — stock restored to 10
      expect(productProvider.findById('p1')!.stockQuantity, 10);
    });

    test('full cycle: create bill then delete → stock equals original', () {
      // arrange
      const originalStock = 50;
      final product = makeProduct(stock: originalStock);
      final productProvider = ProductProvider(initialProducts: [product]);
      final billProvider = BillProvider();

      // act — create 3 bills then delete them all
      final billNumbers = <String>[];
      for (var i = 0; i < 3; i++) {
        billNumbers.add(_completeBillWith(
          billProvider: billProvider,
          productProvider: productProvider,
          product: product,
        ));
      }
      expect(productProvider.findById('p1')!.stockQuantity, originalStock - 3);

      for (final bn in billNumbers) {
        billProvider.deleteBill(bn, productProvider: productProvider);
      }

      // assert — back to original
      expect(productProvider.findById('p1')!.stockQuantity, originalStock);
    });

    test('does NOT restore stock for service products', () {
      // arrange
      final service = makeProduct(id: 's1', stock: 0, isService: true);
      final productProvider = ProductProvider(initialProducts: [service]);
      final billProvider = BillProvider();

      billProvider.addItemToBill(service);
      final bill = billProvider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: _NoOpCustomerProvider(),
      );
      // service stock unchanged at 0 after bill creation
      expect(productProvider.findById('s1')!.stockQuantity, 0);

      // act
      billProvider.deleteBill(bill.billNumber, productProvider: productProvider);

      // assert — stock remains 0 (not incremented for services)
      expect(productProvider.findById('s1')!.stockQuantity, 0);
    });

    test('restores stock for non-service but ignores service in mixed bill', () {
      // arrange — bill with 1 physical + 1 service product
      final physical = makeProduct(id: 'phy1', stock: 20);
      final service = makeProduct(
        id: 'svc1',
        stock: 0,
        isService: true,
        price: 500,
      );
      final productProvider = ProductProvider(
        initialProducts: [physical, service],
      );
      final billProvider = BillProvider();

      billProvider.addItemToBill(physical);
      billProvider.addItemToBill(service);
      final bill = billProvider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 600,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: _NoOpCustomerProvider(),
      );
      // physical decremented: 20 → 19; service unchanged: 0
      expect(productProvider.findById('phy1')!.stockQuantity, 19);
      expect(productProvider.findById('svc1')!.stockQuantity, 0);

      // act
      billProvider.deleteBill(bill.billNumber, productProvider: productProvider);

      // assert — physical restored: 19 → 20; service unchanged: 0
      expect(productProvider.findById('phy1')!.stockQuantity, 20);
      expect(productProvider.findById('svc1')!.stockQuantity, 0);
    });
  });

  // ── Group 3: DB persistence ───────────────────────────────────────────────────
  group('deleteBill — DB persistence', () {
    test('calls dbService.deleteRecord with correct table and bill id', () async {
      // arrange
      final spy = _SpyDbService();
      final product = makeProduct();
      final productProvider = ProductProvider(initialProducts: [product]);
      final billProvider = BillProvider()..dbService = spy;

      billProvider.addItemToBill(product);
      final bill = billProvider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: _NoOpCustomerProvider(),
      );
      final billId = bill.id;

      // act
      billProvider.deleteBill(bill.billNumber, productProvider: productProvider);
      await Future.microtask(() {}); // allow async deleteRecord to settle

      // assert
      expect(
        spy.deletedRecords.any((r) => r.table == 'bills' && r.id == billId),
        isTrue,
        reason: 'Expected deleteRecord("bills", "$billId") to be called',
      );
    });

    test('does not call deleteRecord when bill number not found', () async {
      // arrange
      final spy = _SpyDbService();
      final productProvider = ProductProvider(
        initialProducts: [makeProduct()],
      );
      final billProvider = BillProvider()..dbService = spy;

      // act — delete non-existent bill
      billProvider.deleteBill('INV-GHOST', productProvider: productProvider);
      await Future.microtask(() {});

      // assert — no DB calls made
      expect(spy.deletedRecords, isEmpty);
    });
  });
}
