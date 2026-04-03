import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/purchase_entry.dart';
import 'package:billing_app/models/purchase_line_item.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/purchase_provider.dart';
import 'package:billing_app/providers/supplier_provider.dart';
import 'package:billing_app/models/supplier.dart';

void main() {
  late PurchaseProvider purchaseProvider;
  late ProductProvider productProvider;
  late SupplierProvider supplierProvider;

  Product makeProduct({String? id, String name = 'Test', int stock = 10}) {
    return Product(
      id: id ?? 'p1',
      name: name,
      sellingPrice: 100,
      stockQuantity: stock,
    );
  }

  PurchaseLineItem makeLine({
    String productId = 'p1',
    double qty = 5,
    double price = 50,
  }) {
    return PurchaseLineItem(
      productId: productId,
      productName: 'Test',
      quantity: qty,
      purchasePricePerUnit: price,
    );
  }

  PurchaseEntry makeEntry({
    String? id,
    String? supplierId,
    List<PurchaseLineItem>? items,
    PaymentMode mode = PaymentMode.cash,
    DateTime? date,
  }) {
    return PurchaseEntry(
      id: id,
      supplierId: supplierId,
      items: items ?? [makeLine()],
      paymentMode: mode,
      date: date,
    );
  }

  setUp(() {
    productProvider = ProductProvider(
      initialProducts: [makeProduct()],
    );
    supplierProvider = SupplierProvider(
      initialSuppliers: [
        Supplier(id: 's1', name: 'Supplier A'),
      ],
    );
    purchaseProvider = PurchaseProvider();
  });

  group('PurchaseProvider', () {
    test('addPurchase adds entry and increments stock', () {
      final entry = makeEntry();
      purchaseProvider.addPurchase(
        entry,
        productProvider: productProvider,
      );

      expect(purchaseProvider.purchases.length, 1);
      expect(productProvider.findById('p1')!.stockQuantity, 15);
    });

    test('addPurchase with credit increments supplier payable', () {
      final entry = makeEntry(
        supplierId: 's1',
        mode: PaymentMode.credit,
      );
      purchaseProvider.addPurchase(
        entry,
        productProvider: productProvider,
        supplierProvider: supplierProvider,
      );

      expect(
        supplierProvider.getSupplierById('s1')!.outstandingPayable,
        250.0,
      );
    });

    test('deletePurchase reverses stock', () {
      final entry = makeEntry(id: 'del1');
      purchaseProvider.addPurchase(
        entry,
        productProvider: productProvider,
      );
      expect(productProvider.findById('p1')!.stockQuantity, 15);

      purchaseProvider.deletePurchase(
        'del1',
        productProvider: productProvider,
      );
      expect(productProvider.findById('p1')!.stockQuantity, 10);
      expect(purchaseProvider.purchases.length, 0);
    });

    test('deletePurchase reverses supplier payable for credit', () {
      final entry = makeEntry(
        id: 'del2',
        supplierId: 's1',
        mode: PaymentMode.credit,
      );
      purchaseProvider.addPurchase(
        entry,
        productProvider: productProvider,
        supplierProvider: supplierProvider,
      );
      purchaseProvider.deletePurchase(
        'del2',
        productProvider: productProvider,
        supplierProvider: supplierProvider,
      );

      expect(
        supplierProvider.getSupplierById('s1')!.outstandingPayable,
        0.0,
      );
    });

    test('getPurchasesByDateRange returns correct entries', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      purchaseProvider.addPurchase(
        makeEntry(id: 'a', date: today),
        productProvider: productProvider,
      );
      purchaseProvider.addPurchase(
        makeEntry(id: 'b', date: yesterday),
        productProvider: productProvider,
      );

      final results = purchaseProvider.getPurchasesByDateRange(today, today);
      expect(results.length, 1);
      expect(results.first.id, 'a');
    });

    test('getPurchasesBySupplier filters correctly', () {
      purchaseProvider.addPurchase(
        makeEntry(id: 'x', supplierId: 's1'),
        productProvider: productProvider,
      );
      purchaseProvider.addPurchase(
        makeEntry(id: 'y', supplierId: 's2'),
        productProvider: productProvider,
      );

      final results = purchaseProvider.getPurchasesBySupplier('s1');
      expect(results.length, 1);
      expect(results.first.id, 'x');
    });

    test('getProductPurchaseHistory returns line items for product', () {
      purchaseProvider.addPurchase(
        makeEntry(
          items: [
            makeLine(productId: 'p1', qty: 3, price: 40),
            makeLine(productId: 'p2', qty: 2, price: 60),
          ],
        ),
        productProvider: productProvider,
      );

      final history = purchaseProvider.getProductPurchaseHistory('p1');
      expect(history.length, 1);
      expect(history.first.quantity, 3);
    });

    test('getAverageCostPrice computes weighted average', () {
      purchaseProvider.addPurchase(
        makeEntry(items: [makeLine(productId: 'p1', qty: 10, price: 50)]),
        productProvider: productProvider,
      );
      purchaseProvider.addPurchase(
        makeEntry(items: [makeLine(productId: 'p1', qty: 10, price: 100)]),
        productProvider: productProvider,
      );

      expect(purchaseProvider.getAverageCostPrice('p1'), 75.0);
    });

    test('getLastPurchasePrice returns most recent', () {
      purchaseProvider.addPurchase(
        makeEntry(items: [makeLine(productId: 'p1', qty: 1, price: 30)]),
        productProvider: productProvider,
      );
      purchaseProvider.addPurchase(
        makeEntry(items: [makeLine(productId: 'p1', qty: 1, price: 60)]),
        productProvider: productProvider,
      );

      expect(purchaseProvider.getLastPurchasePrice('p1'), 60.0);
    });

    test('getLastPurchasePrice returns null for unknown product', () {
      expect(purchaseProvider.getLastPurchasePrice('unknown'), isNull);
    });

    test('todayPurchaseTotal sums today entries', () {
      purchaseProvider.addPurchase(
        makeEntry(items: [makeLine(qty: 2, price: 100)]),
        productProvider: productProvider,
      );
      purchaseProvider.addPurchase(
        makeEntry(items: [makeLine(qty: 3, price: 50)]),
        productProvider: productProvider,
      );

      expect(purchaseProvider.todayPurchaseTotal, 350.0);
    });

    test('clearAllData removes all purchases', () {
      purchaseProvider.addPurchase(
        makeEntry(),
        productProvider: productProvider,
      );
      purchaseProvider.clearAllData();
      expect(purchaseProvider.purchases.isEmpty, true);
    });

    test('replaceAllData replaces all data', () {
      purchaseProvider.addPurchase(
        makeEntry(id: 'old'),
        productProvider: productProvider,
      );
      purchaseProvider.replaceAllData(
        purchases: [makeEntry(id: 'new1'), makeEntry(id: 'new2')],
      );
      expect(purchaseProvider.purchases.length, 2);
      expect(purchaseProvider.purchases.first.id, 'new1');
    });

    test('onChanged callback fires on add', () {
      int callCount = 0;
      final provider = PurchaseProvider(onChanged: () => callCount++);
      provider.addPurchase(
        makeEntry(),
        productProvider: productProvider,
      );
      expect(callCount, 1);
    });

    test('initialPurchases are loaded', () {
      final provider = PurchaseProvider(
        initialPurchases: [makeEntry(id: 'init1')],
      );
      expect(provider.purchases.length, 1);
      expect(provider.purchases.first.id, 'init1');
    });
  });

  group('PurchaseEntry model', () {
    test('toJson and fromJson round-trip', () {
      final entry = PurchaseEntry(
        id: 'test-id',
        supplierId: 's1',
        supplierName: 'Supplier A',
        items: [
          PurchaseLineItem(
            productId: 'p1',
            productName: 'Product A',
            quantity: 5,
            purchasePricePerUnit: 50,
            unitOfMeasure: 'kg',
          ),
        ],
        paymentMode: PaymentMode.credit,
        invoiceNumber: 'INV-001',
        notes: 'Test notes',
      );

      final json = entry.toJson();
      final restored = PurchaseEntry.fromJson(json);

      expect(restored.id, 'test-id');
      expect(restored.supplierId, 's1');
      expect(restored.supplierName, 'Supplier A');
      expect(restored.items.length, 1);
      expect(restored.items.first.productId, 'p1');
      expect(restored.items.first.quantity, 5);
      expect(restored.items.first.purchasePricePerUnit, 50);
      expect(restored.items.first.unitOfMeasure, 'kg');
      expect(restored.totalAmount, 250.0);
      expect(restored.paymentMode, PaymentMode.credit);
      expect(restored.invoiceNumber, 'INV-001');
      expect(restored.notes, 'Test notes');
    });

    test('fromJson handles missing fields gracefully', () {
      final entry = PurchaseEntry.fromJson({});
      expect(entry.items, isEmpty);
      expect(entry.totalAmount, 0);
      expect(entry.paymentMode, PaymentMode.cash);
    });

    test('totalAmount defaults to sum of items', () {
      final entry = PurchaseEntry(
        items: [
          PurchaseLineItem(
            productId: 'p1',
            productName: 'A',
            quantity: 2,
            purchasePricePerUnit: 30,
          ),
          PurchaseLineItem(
            productId: 'p2',
            productName: 'B',
            quantity: 3,
            purchasePricePerUnit: 20,
          ),
        ],
      );
      expect(entry.totalAmount, 120.0);
    });
  });

  group('PurchaseLineItem model', () {
    test('totalCost computes correctly', () {
      final item = PurchaseLineItem(
        productId: 'p1',
        productName: 'Test',
        quantity: 4,
        purchasePricePerUnit: 25,
      );
      expect(item.totalCost, 100.0);
    });

    test('toJson and fromJson round-trip', () {
      final item = PurchaseLineItem(
        productId: 'p1',
        productName: 'Test',
        quantity: 3,
        purchasePricePerUnit: 40,
        unitOfMeasure: 'pcs',
        batchNumber: 'BN-001',
      );

      final json = item.toJson();
      final restored = PurchaseLineItem.fromJson(json);

      expect(restored.productId, 'p1');
      expect(restored.productName, 'Test');
      expect(restored.quantity, 3);
      expect(restored.purchasePricePerUnit, 40);
      expect(restored.unitOfMeasure, 'pcs');
      expect(restored.batchNumber, 'BN-001');
    });
  });
}
