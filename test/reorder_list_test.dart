import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/product_provider.dart';

void main() {
  Product makeProduct({
    String? id,
    int stock = 50,
    double? reorderLevel,
    double? reorderQuantity,
    String? preferredSupplierId,
    bool isService = false,
  }) {
    return Product(
      id: id ?? 'p1',
      name: 'Test Product',
      sellingPrice: 100,
      stockQuantity: stock,
      reorderLevel: reorderLevel,
      reorderQuantity: reorderQuantity,
      preferredSupplierId: preferredSupplierId,
      isService: isService,
    );
  }

  group('Product reorder fields', () {
    test('needsReorder is true when stock <= reorderLevel', () {
      final p = makeProduct(stock: 5, reorderLevel: 10);
      expect(p.needsReorder, true);
    });

    test('needsReorder is true when stock equals reorderLevel', () {
      final p = makeProduct(stock: 10, reorderLevel: 10);
      expect(p.needsReorder, true);
    });

    test('needsReorder is false when stock > reorderLevel', () {
      final p = makeProduct(stock: 15, reorderLevel: 10);
      expect(p.needsReorder, false);
    });

    test('needsReorder is false when reorderLevel is null', () {
      final p = makeProduct(stock: 5);
      expect(p.needsReorder, false);
    });

    test('needsReorder is false for services', () {
      final p = makeProduct(stock: 0, reorderLevel: 10, isService: true);
      expect(p.needsReorder, false);
    });

    test('toJson includes reorder fields', () {
      final p = makeProduct(
        reorderLevel: 10,
        reorderQuantity: 50,
        preferredSupplierId: 'sup-1',
      );
      final json = p.toJson();
      expect(json['reorderLevel'], 10.0);
      expect(json['reorderQuantity'], 50.0);
      expect(json['preferredSupplierId'], 'sup-1');
    });

    test('fromJson restores reorder fields', () {
      final p = makeProduct(
        reorderLevel: 10,
        reorderQuantity: 50,
        preferredSupplierId: 'sup-1',
      );
      final restored = Product.fromJson(p.toJson());
      expect(restored.reorderLevel, 10.0);
      expect(restored.reorderQuantity, 50.0);
      expect(restored.preferredSupplierId, 'sup-1');
    });

    test('fromJson handles missing reorder fields', () {
      final restored = Product.fromJson({'name': 'Test', 'sellingPrice': 100});
      expect(restored.reorderLevel, isNull);
      expect(restored.reorderQuantity, isNull);
      expect(restored.preferredSupplierId, isNull);
    });

    test('copyWith updates reorder fields', () {
      final p = makeProduct();
      final updated = p.copyWith(
        reorderLevel: 20.0,
        reorderQuantity: 100.0,
        preferredSupplierId: 'sup-2',
      );
      expect(updated.reorderLevel, 20.0);
      expect(updated.reorderQuantity, 100.0);
      expect(updated.preferredSupplierId, 'sup-2');
    });

    test('copyWith can clear reorder fields', () {
      final p = makeProduct(
        reorderLevel: 10,
        reorderQuantity: 50,
        preferredSupplierId: 'sup-1',
      );
      final updated = p.copyWith(
        reorderLevel: null,
        reorderQuantity: null,
        preferredSupplierId: null,
      );
      expect(updated.reorderLevel, isNull);
      expect(updated.reorderQuantity, isNull);
      expect(updated.preferredSupplierId, isNull);
    });
  });

  group('ProductProvider reorder', () {
    test('productsNeedingReorder returns products at or below reorder level',
        () {
      final provider = ProductProvider(
        initialProducts: [
          makeProduct(id: 'p1', stock: 5, reorderLevel: 10),
          makeProduct(id: 'p2', stock: 50, reorderLevel: 10),
          makeProduct(id: 'p3', stock: 10, reorderLevel: 10),
          makeProduct(id: 'p4', stock: 20), // no reorder level
        ],
      );

      final reorder = provider.productsNeedingReorder;
      expect(reorder.length, 2);
      expect(reorder.map((p) => p.id).toSet(), {'p1', 'p3'});
    });

    test('reorderRequiredCount matches productsNeedingReorder length', () {
      final provider = ProductProvider(
        initialProducts: [
          makeProduct(id: 'p1', stock: 5, reorderLevel: 10),
          makeProduct(id: 'p2', stock: 50),
        ],
      );

      expect(provider.reorderRequiredCount, 1);
    });

    test('productsNeedingReorder excludes services', () {
      final provider = ProductProvider(
        initialProducts: [
          makeProduct(
            id: 'p1',
            stock: 0,
            reorderLevel: 10,
            isService: true,
          ),
        ],
      );

      expect(provider.productsNeedingReorder, isEmpty);
    });
  });
}
