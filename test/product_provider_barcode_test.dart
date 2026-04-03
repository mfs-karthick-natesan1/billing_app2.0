import 'package:billing_app/models/product.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductProvider barcode lookup', () {
    test('findByBarcode matches exact barcode with trim', () {
      final provider = ProductProvider(
        initialProducts: [
          Product(
            id: 'p-1',
            name: 'Rice',
            barcode: '890100000001',
            sellingPrice: 50,
            stockQuantity: 10,
          ),
        ],
      );

      final found = provider.findByBarcode(' 890100000001 ');
      expect(found, isNotNull);
      expect(found!.id, 'p-1');
    });

    test('barcodeExists respects excludeId when editing', () {
      final provider = ProductProvider(
        initialProducts: [
          Product(
            id: 'p-1',
            name: 'Rice',
            barcode: '890100000001',
            sellingPrice: 50,
            stockQuantity: 10,
          ),
          Product(
            id: 'p-2',
            name: 'Dal',
            barcode: '890100000002',
            sellingPrice: 60,
            stockQuantity: 8,
          ),
        ],
      );

      expect(provider.barcodeExists('890100000001', excludeId: 'p-1'), isFalse);
      expect(provider.barcodeExists('890100000001', excludeId: 'p-2'), isTrue);
    });

    test('searchProducts also matches barcode text', () {
      final provider = ProductProvider(
        initialProducts: [
          Product(
            name: 'Rice',
            barcode: '890100000001',
            sellingPrice: 50,
            stockQuantity: 10,
          ),
          Product(
            name: 'Dal',
            barcode: '890100000002',
            sellingPrice: 60,
            stockQuantity: 8,
          ),
        ],
      );

      final results = provider.searchProducts('000002');
      expect(results.length, 1);
      expect(results.first.name, 'Dal');
    });
  });
}
