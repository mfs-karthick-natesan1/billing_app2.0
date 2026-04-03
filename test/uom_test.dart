import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/constants/uom_constants.dart';
import 'package:billing_app/constants/units.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/line_item.dart';

void main() {
  group('UomConstants', () {
    test('standardUnits contains all expected units', () {
      expect(UomConstants.standardUnits, contains('pcs'));
      expect(UomConstants.standardUnits, contains('kg'));
      expect(UomConstants.standardUnits, contains('g'));
      expect(UomConstants.standardUnits, contains('ltr'));
      expect(UomConstants.standardUnits, contains('ml'));
      expect(UomConstants.standardUnits, contains('dozen'));
      expect(UomConstants.standardUnits, contains('pack'));
      expect(UomConstants.standardUnits, contains('box'));
      expect(UomConstants.standardUnits, contains('bottle'));
    });

    test('label returns full label for known UOM', () {
      expect(UomConstants.label('kg'), 'Kilogram');
      expect(UomConstants.label('pcs'), 'Pieces');
      expect(UomConstants.label('ltr'), 'Litre');
      expect(UomConstants.label('ml'), 'Millilitre');
    });

    test('label returns code itself for unknown UOM', () {
      expect(UomConstants.label('xyz'), 'xyz');
    });

    test('display formats integer quantities cleanly', () {
      expect(UomConstants.display('kg', 2), '2 kg');
      expect(UomConstants.display('pcs', 10), '10 pcs');
      expect(UomConstants.display('ltr', 1), '1 ltr');
    });

    test('display formats decimal quantities cleanly', () {
      expect(UomConstants.display('kg', 0.5), '0.5 kg');
      expect(UomConstants.display('kg', 1.25), '1.25 kg');
      expect(UomConstants.display('kg', 2.50), '2.5 kg');
    });

    test('display handles null UOM', () {
      expect(UomConstants.display(null, 3), '3');
    });

    test('display handles empty UOM', () {
      expect(UomConstants.display('', 5), '5');
    });

    test('formatQty strips trailing zeroes', () {
      expect(UomConstants.formatQty(1.0), '1');
      expect(UomConstants.formatQty(2.50), '2.5');
      expect(UomConstants.formatQty(0.25), '0.25');
      expect(UomConstants.formatQty(10.10), '10.1');
    });

    test('isDecimalUnit identifies weight/volume units', () {
      expect(UomConstants.isDecimalUnit('kg'), true);
      expect(UomConstants.isDecimalUnit('g'), true);
      expect(UomConstants.isDecimalUnit('ltr'), true);
      expect(UomConstants.isDecimalUnit('ml'), true);
      expect(UomConstants.isDecimalUnit('pcs'), false);
      expect(UomConstants.isDecimalUnit('dozen'), false);
      expect(UomConstants.isDecimalUnit(null), false);
    });
  });

  group('Units', () {
    test('all includes custom option', () {
      expect(Units.all, contains('custom'));
      expect(Units.all, contains('bottle'));
    });

    test('label delegates to UomConstants', () {
      expect(Units.label('kg'), 'Kilogram');
      expect(Units.label('custom'), 'Custom');
    });
  });

  group('Product UOM fields', () {
    test('default values for new product', () {
      final product = Product(name: 'Test', sellingPrice: 100);
      expect(product.unit, 'pcs');
      expect(product.customUomLabel, isNull);
      expect(product.minQuantity, 1.0);
      expect(product.quantityStep, 1.0);
    });

    test('displayUom returns unit for standard units', () {
      final product = Product(name: 'Test', sellingPrice: 100, unit: 'kg');
      expect(product.displayUom, 'kg');
    });

    test('displayUom returns customUomLabel for custom unit', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        unit: 'custom',
        customUomLabel: 'plate',
      );
      expect(product.displayUom, 'plate');
    });

    test('displayUom falls back to unit when custom but no label', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        unit: 'custom',
      );
      expect(product.displayUom, 'custom');
    });

    test('copyWith preserves UOM fields', () {
      final product = Product(
        name: 'Test',
        sellingPrice: 100,
        unit: 'kg',
        minQuantity: 0.5,
        quantityStep: 0.25,
        customUomLabel: null,
      );
      final updated = product.copyWith(name: 'Updated');
      expect(updated.unit, 'kg');
      expect(updated.minQuantity, 0.5);
      expect(updated.quantityStep, 0.25);
      expect(updated.customUomLabel, isNull);
    });

    test('toJson/fromJson round-trips UOM fields', () {
      final product = Product(
        name: 'Rice',
        sellingPrice: 85,
        unit: 'kg',
        customUomLabel: null,
        minQuantity: 0.5,
        quantityStep: 0.25,
      );
      final json = product.toJson();
      final restored = Product.fromJson(json);
      expect(restored.unit, 'kg');
      expect(restored.minQuantity, 0.5);
      expect(restored.quantityStep, 0.25);
      expect(restored.customUomLabel, isNull);
    });

    test('fromJson defaults for missing UOM fields', () {
      final json = {
        'name': 'Old Product',
        'sellingPrice': 50,
      };
      final product = Product.fromJson(json);
      expect(product.unit, 'pcs');
      expect(product.minQuantity, 1.0);
      expect(product.quantityStep, 1.0);
    });
  });

  group('LineItem with double quantity', () {
    test('subtotal with decimal quantity', () {
      final product = Product(name: 'Rice', sellingPrice: 85, unit: 'kg');
      final item = LineItem(product: product, quantity: 2.5);
      expect(item.subtotal, closeTo(212.5, 0.01));
    });

    test('default quantity is 1.0', () {
      final product = Product(name: 'Test', sellingPrice: 100);
      final item = LineItem(product: product);
      expect(item.quantity, 1.0);
    });

    test('toJson/fromJson round-trips double quantity', () {
      final product = Product(name: 'Dal', sellingPrice: 140, unit: 'kg');
      final item = LineItem(product: product, quantity: 0.75);
      final json = item.toJson();
      final restored = LineItem.fromJson(json);
      expect(restored.quantity, 0.75);
      expect(restored.subtotal, closeTo(105.0, 0.01));
    });

    test('fromJson handles int quantity from old data', () {
      final json = {
        'product': {'name': 'Test', 'sellingPrice': 100},
        'quantity': 3,
      };
      final item = LineItem.fromJson(json);
      expect(item.quantity, 3.0);
    });
  });
}
