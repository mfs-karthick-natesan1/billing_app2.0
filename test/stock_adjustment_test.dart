import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/stock_adjustment.dart';
import 'package:billing_app/providers/product_provider.dart';

void main() {
  late ProductProvider provider;

  Product makeProduct({String? id, int stock = 50}) {
    return Product(
      id: id ?? 'p1',
      name: 'Test Product',
      sellingPrice: 100,
      stockQuantity: stock,
    );
  }

  setUp(() {
    provider = ProductProvider(
      initialProducts: [makeProduct()],
    );
  });

  group('Stock Adjustment', () {
    test('adjustStock updates product stock quantity', () {
      final adj = StockAdjustment(
        productId: 'p1',
        productName: 'Test Product',
        previousStock: 50,
        newStock: 30,
        reason: StockAdjustmentReason.damage,
      );

      provider.adjustStock(adj);

      expect(provider.findById('p1')!.stockQuantity, 30);
    });

    test('adjustStock adds to adjustments list', () {
      final adj = StockAdjustment(
        productId: 'p1',
        productName: 'Test Product',
        previousStock: 50,
        newStock: 45,
        reason: StockAdjustmentReason.theft,
      );

      provider.adjustStock(adj);

      expect(provider.adjustments.length, 1);
      expect(provider.adjustments.first.reason, StockAdjustmentReason.theft);
    });

    test('getAdjustments returns sorted by date desc', () {
      final older = StockAdjustment(
        productId: 'p1',
        productName: 'Test Product',
        previousStock: 50,
        newStock: 45,
        reason: StockAdjustmentReason.damage,
        date: DateTime(2025, 1, 1),
      );
      final newer = StockAdjustment(
        productId: 'p1',
        productName: 'Test Product',
        previousStock: 45,
        newStock: 40,
        reason: StockAdjustmentReason.expiry,
        date: DateTime(2025, 6, 1),
      );

      provider.adjustStock(older);
      provider.adjustStock(newer);

      final history = provider.getAdjustments('p1');
      expect(history.length, 2);
      expect(history.first.reason, StockAdjustmentReason.expiry);
    });

    test('getAdjustments filters by productId', () {
      provider = ProductProvider(
        initialProducts: [makeProduct(id: 'p1'), makeProduct(id: 'p2')],
      );

      provider.adjustStock(StockAdjustment(
        productId: 'p1',
        productName: 'A',
        previousStock: 50,
        newStock: 40,
        reason: StockAdjustmentReason.damage,
      ));
      provider.adjustStock(StockAdjustment(
        productId: 'p2',
        productName: 'B',
        previousStock: 50,
        newStock: 30,
        reason: StockAdjustmentReason.theft,
      ));

      expect(provider.getAdjustments('p1').length, 1);
      expect(provider.getAdjustments('p2').length, 1);
    });

    test('adjustStock ignores unknown product', () {
      final adj = StockAdjustment(
        productId: 'unknown',
        productName: 'X',
        previousStock: 50,
        newStock: 30,
        reason: StockAdjustmentReason.other,
      );

      provider.adjustStock(adj);

      expect(provider.adjustments, isEmpty);
      expect(provider.findById('p1')!.stockQuantity, 50);
    });

    test('clearProducts also clears adjustments', () {
      provider.adjustStock(StockAdjustment(
        productId: 'p1',
        productName: 'Test',
        previousStock: 50,
        newStock: 40,
        reason: StockAdjustmentReason.countCorrection,
      ));

      provider.clearProducts();

      expect(provider.products, isEmpty);
      expect(provider.adjustments, isEmpty);
    });

    test('onChanged callback fires on adjustStock', () {
      int callCount = 0;
      final p = ProductProvider(
        initialProducts: [makeProduct()],
        onChanged: () => callCount++,
      );

      p.adjustStock(StockAdjustment(
        productId: 'p1',
        productName: 'Test',
        previousStock: 50,
        newStock: 45,
        reason: StockAdjustmentReason.damage,
      ));

      expect(callCount, 1);
    });

    test('initialAdjustments are loaded', () {
      final adj = StockAdjustment(
        id: 'adj-1',
        productId: 'p1',
        productName: 'Test',
        previousStock: 50,
        newStock: 40,
        reason: StockAdjustmentReason.damage,
      );

      final p = ProductProvider(
        initialProducts: [makeProduct()],
        initialAdjustments: [adj],
      );

      expect(p.adjustments.length, 1);
      expect(p.adjustments.first.id, 'adj-1');
    });
  });

  group('StockAdjustment model', () {
    test('adjustmentQty defaults to newStock - previousStock', () {
      final adj = StockAdjustment(
        productId: 'p1',
        productName: 'Test',
        previousStock: 50,
        newStock: 30,
        reason: StockAdjustmentReason.damage,
      );

      expect(adj.adjustmentQty, -20);
    });

    test('toJson and fromJson round-trip', () {
      final adj = StockAdjustment(
        id: 'test-id',
        productId: 'p1',
        productName: 'Test Product',
        previousStock: 100,
        newStock: 80,
        reason: StockAdjustmentReason.theft,
        notes: 'Stolen items',
        adjustedBy: 'user-1',
      );

      final json = adj.toJson();
      final restored = StockAdjustment.fromJson(json);

      expect(restored.id, 'test-id');
      expect(restored.productId, 'p1');
      expect(restored.productName, 'Test Product');
      expect(restored.previousStock, 100);
      expect(restored.newStock, 80);
      expect(restored.adjustmentQty, -20);
      expect(restored.reason, StockAdjustmentReason.theft);
      expect(restored.notes, 'Stolen items');
      expect(restored.adjustedBy, 'user-1');
    });

    test('fromJson handles missing fields', () {
      final adj = StockAdjustment.fromJson({});

      expect(adj.productId, '');
      expect(adj.previousStock, 0);
      expect(adj.newStock, 0);
      expect(adj.reason, StockAdjustmentReason.other);
    });

    test('reason label returns readable string', () {
      expect(StockAdjustmentReason.damage.label, 'Damage');
      expect(StockAdjustmentReason.countCorrection.label, 'Count Correction');
      expect(
        StockAdjustmentReason.returnFromCustomer.label,
        'Customer Return',
      );
    });
  });
}
