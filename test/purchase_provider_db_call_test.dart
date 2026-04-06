// Regression tests for: deletePurchase must call dbService.deleteRecord
// Bug fixed: deletePurchase removed the entry locally but never called
//            dbService.deleteRecord — so the purchase reappeared on next sync.
//
// Covers:
//   - calls dbService.deleteRecord('purchases', id) on delete
//   - does NOT call deleteRecord when purchase not found
//   - local list is updated (purchase removed) even with spy dbService
//   - stock is reversed correctly alongside DB call

import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/purchase_entry.dart';
import 'package:billing_app/models/purchase_line_item.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/purchase_provider.dart';
import 'package:billing_app/services/db_service.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Spy DbService ──────────────────────────────────────────────────────────────
class _SpyDbService extends DbService {
  final List<({String table, String id})> deletedRecords = [];

  _SpyDbService() : super('test-business-id');

  @override
  Future<void> deleteRecord(String table, String id) async {
    deletedRecords.add((table: table, id: id));
  }
}

void main() {
  // ── Fixtures ──────────────────────────────────────────────────────────────────

  Product makeProduct({String id = 'p1', int stock = 10}) {
    return Product(
      id: id,
      name: 'Test Product',
      sellingPrice: 100,
      stockQuantity: stock,
    );
  }

  PurchaseEntry makePurchase({
    String id = 'pur1',
    String productId = 'p1',
    double qty = 5,
    PaymentMode mode = PaymentMode.cash,
  }) {
    return PurchaseEntry(
      id: id,
      items: [
        PurchaseLineItem(
          productId: productId,
          productName: 'Test Product',
          quantity: qty,
          purchasePricePerUnit: 50,
        ),
      ],
      paymentMode: mode,
    );
  }

  // ── Group 1: DB persistence (the key regression) ──────────────────────────────
  group('deletePurchase — DB persistence', () {
    test('calls dbService.deleteRecord with table=purchases and correct id', () async {
      // arrange
      final spy = _SpyDbService();
      final productProvider = ProductProvider(initialProducts: [makeProduct()]);
      final purchaseProvider = PurchaseProvider()..dbService = spy;
      final purchase = makePurchase(id: 'del-test-1');
      purchaseProvider.addPurchase(purchase, productProvider: productProvider);

      // act
      purchaseProvider.deletePurchase(
        'del-test-1',
        productProvider: productProvider,
      );
      await Future.microtask(() {}); // allow async to settle

      // assert
      expect(
        spy.deletedRecords.any(
          (r) => r.table == 'purchases' && r.id == 'del-test-1',
        ),
        isTrue,
        reason: 'Expected deleteRecord("purchases", "del-test-1") to be called',
      );
    });

    test('does NOT call deleteRecord when purchase id not found', () async {
      // arrange
      final spy = _SpyDbService();
      final productProvider = ProductProvider(initialProducts: [makeProduct()]);
      final purchaseProvider = PurchaseProvider()..dbService = spy;

      // act — delete non-existent purchase
      purchaseProvider.deletePurchase(
        'nonexistent-id',
        productProvider: productProvider,
      );
      await Future.microtask(() {});

      // assert — no DB calls
      expect(spy.deletedRecords, isEmpty);
    });

    test('local list is updated AND DB call is made together', () async {
      // arrange
      final spy = _SpyDbService();
      final productProvider = ProductProvider(initialProducts: [makeProduct()]);
      final purchaseProvider = PurchaseProvider()..dbService = spy;
      purchaseProvider.addPurchase(makePurchase(id: 'both-1'), productProvider: productProvider);
      purchaseProvider.addPurchase(makePurchase(id: 'both-2'), productProvider: productProvider);
      expect(purchaseProvider.purchases.length, 2);

      // act
      purchaseProvider.deletePurchase('both-1', productProvider: productProvider);
      await Future.microtask(() {});

      // assert — local list updated
      expect(purchaseProvider.purchases.length, 1);
      expect(purchaseProvider.purchases.first.id, 'both-2');

      // assert — DB call made
      expect(
        spy.deletedRecords.any((r) => r.table == 'purchases' && r.id == 'both-1'),
        isTrue,
      );
    });
  });

  // ── Group 2: stock reversal still works with spy ───────────────────────────────
  group('deletePurchase — stock reversal with dbService attached', () {
    test('still reverses stock when dbService is attached', () async {
      // arrange
      final spy = _SpyDbService();
      final productProvider = ProductProvider(
        initialProducts: [makeProduct(stock: 10)],
      );
      final purchaseProvider = PurchaseProvider()..dbService = spy;

      // add purchase → stock goes 10 → 15
      purchaseProvider.addPurchase(
        makePurchase(qty: 5),
        productProvider: productProvider,
      );
      expect(productProvider.findById('p1')!.stockQuantity, 15);

      // act — delete purchase → stock should go 15 → 10
      purchaseProvider.deletePurchase('pur1', productProvider: productProvider);
      await Future.microtask(() {});

      // assert — stock reversed AND DB called
      expect(productProvider.findById('p1')!.stockQuantity, 10);
      expect(
        spy.deletedRecords.any((r) => r.table == 'purchases' && r.id == 'pur1'),
        isTrue,
      );
    });

    test('full cycle: add purchase then delete → stock and DB both consistent', () async {
      // arrange
      final spy = _SpyDbService();
      const originalStock = 20;
      final productProvider = ProductProvider(
        initialProducts: [makeProduct(stock: originalStock)],
      );
      final purchaseProvider = PurchaseProvider()..dbService = spy;

      // add 3 purchases
      for (var i = 1; i <= 3; i++) {
        purchaseProvider.addPurchase(
          makePurchase(id: 'p-$i', qty: 3),
          productProvider: productProvider,
        );
      }
      expect(productProvider.findById('p1')!.stockQuantity, originalStock + 9);

      // delete all 3
      for (var i = 1; i <= 3; i++) {
        purchaseProvider.deletePurchase('p-$i', productProvider: productProvider);
      }
      await Future.microtask(() {});

      // assert — stock back to original
      expect(productProvider.findById('p1')!.stockQuantity, originalStock);

      // assert — 3 DB delete calls made
      final purchaseDeletes =
          spy.deletedRecords.where((r) => r.table == 'purchases').toList();
      expect(purchaseDeletes.length, 3);
    });
  });

  // ── Group 3: onChanged callback ────────────────────────────────────────────────
  group('deletePurchase — onChanged callback', () {
    test('fires onChanged when purchase deleted', () async {
      // arrange
      int callCount = 0;
      final productProvider = ProductProvider(initialProducts: [makeProduct()]);
      final purchaseProvider = PurchaseProvider(onChanged: () => callCount++);
      purchaseProvider.addPurchase(makePurchase(id: 'cb-1'), productProvider: productProvider);
      final countBefore = callCount;

      // act
      purchaseProvider.deletePurchase('cb-1', productProvider: productProvider);

      // assert
      expect(callCount, greaterThan(countBefore));
    });
  });
}
