import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/supplier.dart';
import 'package:billing_app/providers/supplier_provider.dart';

void main() {
  group('SupplierProvider', () {
    late SupplierProvider provider;

    setUp(() {
      provider = SupplierProvider();
    });

    test('starts with empty supplier list', () {
      expect(provider.suppliers, isEmpty);
      expect(provider.getActiveSuppliers(), isEmpty);
      expect(provider.getTotalPayable(), 0.0);
    });

    test('addSupplier creates a new supplier', () {
      final supplier = provider.addSupplier(
        name: 'ABC Wholesalers',
        phone: '9876543210',
        gstin: '29ABCDE1234F1Z5',
        productCategories: ['Rice', 'Wheat'],
      );

      expect(provider.suppliers.length, 1);
      expect(supplier.name, 'ABC Wholesalers');
      expect(supplier.phone, '9876543210');
      expect(supplier.gstin, '29ABCDE1234F1Z5');
      expect(supplier.productCategories, ['Rice', 'Wheat']);
      expect(supplier.isActive, true);
      expect(supplier.outstandingPayable, 0);
    });

    test('updateSupplier modifies supplier fields', () {
      final supplier = provider.addSupplier(name: 'Old Name');
      final result = provider.updateSupplier(
        supplier.id,
        name: 'New Name',
        phone: '1234567890',
        address: '123 Main St',
      );

      expect(result, true);
      final updated = provider.getSupplierById(supplier.id)!;
      expect(updated.name, 'New Name');
      expect(updated.phone, '1234567890');
      expect(updated.address, '123 Main St');
    });

    test('updateSupplier returns false for non-existent id', () {
      expect(provider.updateSupplier('fake-id', name: 'Test'), false);
    });

    test('deleteSupplier soft-deletes (sets isActive false)', () {
      final supplier = provider.addSupplier(name: 'Test Supplier');
      expect(provider.getActiveSuppliers().length, 1);

      provider.deleteSupplier(supplier.id);

      expect(provider.suppliers.length, 1);
      expect(provider.getActiveSuppliers(), isEmpty);
      expect(provider.getSupplierById(supplier.id)!.isActive, false);
    });

    test('reactivateSupplier restores supplier', () {
      final supplier = provider.addSupplier(name: 'Test');
      provider.deleteSupplier(supplier.id);
      expect(provider.getActiveSuppliers(), isEmpty);

      provider.reactivateSupplier(supplier.id);
      expect(provider.getActiveSuppliers().length, 1);
    });

    test('searchSuppliers matches name', () {
      provider.addSupplier(name: 'ABC Wholesalers');
      provider.addSupplier(name: 'XYZ Traders');

      final results = provider.searchSuppliers('abc');
      expect(results.length, 1);
      expect(results.first.name, 'ABC Wholesalers');
    });

    test('searchSuppliers matches product categories', () {
      provider.addSupplier(
        name: 'Pharma Corp',
        productCategories: ['Medicines', 'Syringes'],
      );
      provider.addSupplier(
        name: 'Grocery King',
        productCategories: ['Rice', 'Wheat'],
      );

      final results = provider.searchSuppliers('medicine');
      expect(results.length, 1);
      expect(results.first.name, 'Pharma Corp');
    });

    test('searchSuppliers excludes inactive suppliers', () {
      final supplier = provider.addSupplier(name: 'Inactive Co');
      provider.deleteSupplier(supplier.id);

      final results = provider.searchSuppliers('Inactive');
      expect(results, isEmpty);
    });

    test('addPayable increases outstanding', () {
      final supplier = provider.addSupplier(name: 'Test');
      provider.addPayable(supplier.id, 5000);

      expect(provider.getSupplierById(supplier.id)!.outstandingPayable, 5000);
      expect(provider.getTotalPayable(), 5000);
    });

    test('recordPayment reduces outstanding', () {
      final supplier = provider.addSupplier(name: 'Test');
      provider.addPayable(supplier.id, 5000);
      provider.recordPayment(supplier.id, 2000);

      expect(provider.getSupplierById(supplier.id)!.outstandingPayable, 3000);
    });

    test('recordPayment does not go below zero', () {
      final supplier = provider.addSupplier(name: 'Test');
      provider.addPayable(supplier.id, 100);
      provider.recordPayment(supplier.id, 200);

      expect(provider.getSupplierById(supplier.id)!.outstandingPayable, 0);
    });

    test('getTotalPayable sums active suppliers only', () {
      final s1 = provider.addSupplier(name: 'Active');
      final s2 = provider.addSupplier(name: 'Inactive');
      provider.addPayable(s1.id, 3000);
      provider.addPayable(s2.id, 2000);
      provider.deleteSupplier(s2.id);

      expect(provider.getTotalPayable(), 3000);
    });

    test('clearAllData removes all suppliers', () {
      provider.addSupplier(name: 'A');
      provider.addSupplier(name: 'B');
      expect(provider.suppliers.length, 2);

      provider.clearAllData();
      expect(provider.suppliers, isEmpty);
    });

    test('replaceAllData swaps supplier list', () {
      provider.addSupplier(name: 'Old');
      provider.replaceAllData(
        suppliers: [Supplier(name: 'New1'), Supplier(name: 'New2')],
      );

      expect(provider.suppliers.length, 2);
      expect(provider.suppliers.first.name, 'New1');
    });

    test('initialSuppliers are loaded', () {
      final loaded = SupplierProvider(
        initialSuppliers: [
          Supplier(name: 'Preloaded', phone: '111'),
        ],
      );

      expect(loaded.suppliers.length, 1);
      expect(loaded.suppliers.first.name, 'Preloaded');
    });

    test('onChanged callback fires on mutations', () {
      var callCount = 0;
      final tracked = SupplierProvider(onChanged: () => callCount++);

      tracked.addSupplier(name: 'Test');
      expect(callCount, 1);

      tracked.updateSupplier(tracked.suppliers.first.id, name: 'Updated');
      expect(callCount, 2);

      tracked.deleteSupplier(tracked.suppliers.first.id);
      expect(callCount, 3);
    });
  });

  group('Supplier model', () {
    test('toJson and fromJson round-trip', () {
      final supplier = Supplier(
        name: 'Test Corp',
        phone: '9999999999',
        gstin: '29ABCDE1234F1Z5',
        address: '42 Trade Lane',
        productCategories: ['Electronics', 'Cables'],
        outstandingPayable: 15000,
        notes: 'Reliable supplier',
      );

      final json = supplier.toJson();
      final restored = Supplier.fromJson(json);

      expect(restored.id, supplier.id);
      expect(restored.name, 'Test Corp');
      expect(restored.phone, '9999999999');
      expect(restored.gstin, '29ABCDE1234F1Z5');
      expect(restored.address, '42 Trade Lane');
      expect(restored.productCategories, ['Electronics', 'Cables']);
      expect(restored.outstandingPayable, 15000);
      expect(restored.notes, 'Reliable supplier');
      expect(restored.isActive, true);
    });

    test('fromJson handles missing fields gracefully', () {
      final supplier = Supplier.fromJson({'name': 'Minimal'});

      expect(supplier.name, 'Minimal');
      expect(supplier.phone, isNull);
      expect(supplier.gstin, isNull);
      expect(supplier.productCategories, isEmpty);
      expect(supplier.outstandingPayable, 0);
      expect(supplier.isActive, true);
    });

    test('copyWith preserves unchanged fields', () {
      final original = Supplier(
        name: 'Original',
        phone: '123',
        productCategories: ['A'],
      );
      final copy = original.copyWith(name: 'Changed');

      expect(copy.id, original.id);
      expect(copy.name, 'Changed');
      expect(copy.phone, '123');
      expect(copy.productCategories, ['A']);
    });
  });
}
