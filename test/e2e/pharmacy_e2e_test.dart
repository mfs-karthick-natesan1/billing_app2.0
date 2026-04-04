import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/product_batch.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'helpers/test_fixtures.dart';

void main() {
  late ProductProvider productProvider;
  late BillProvider billProvider;
  late CustomerProvider customerProvider;

  setUp(() {
    productProvider = ProductProvider();
    billProvider = BillProvider();
    customerProvider = CustomerProvider();
  });

  group('Pharmacy — Batch Tracking', () {
    test('bill with batch → specific batch stock decremented', () {
      final product = pharmacyProduct();
      productProvider.addProduct(product);

      // Verify initial batch stocks
      final initialProduct = productProvider.products.first;
      final bn001 =
          initialProduct.batches.firstWhere((b) => b.batchNumber == 'BN-001');
      final bn002 =
          initialProduct.batches.firstWhere((b) => b.batchNumber == 'BN-002');
      expect(bn001.stockQuantity, 20);
      expect(bn002.stockQuantity, 30);
      expect(initialProduct.stockQuantity, 50);

      // addItemToBill with pharmacy business type auto-selects nearestExpiryBatch
      billProvider.addItemToBill(product, businessType: BusinessType.pharmacy);

      // Update quantity to 5
      billProvider.updateQuantity(0, 5);

      // The active line item should have the nearest expiry batch (BN-001, 30d)
      final activeItem = billProvider.activeLineItems.first;
      expect(activeItem.batch, isNotNull);
      expect(activeItem.batch!.batchNumber, 'BN-001');
      expect(activeItem.quantity, 5);

      // Complete the bill
      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(amountReceived: 150),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(bill.lineItems.length, 1);

      // Verify batch BN-001 stock reduced by 5
      final updatedProduct = productProvider.products.first;
      final updatedBn001 =
          updatedProduct.batches.firstWhere((b) => b.batchNumber == 'BN-001');
      final updatedBn002 =
          updatedProduct.batches.firstWhere((b) => b.batchNumber == 'BN-002');
      expect(updatedBn001.stockQuantity, 15); // 20 - 5
      expect(updatedBn002.stockQuantity, 30); // unchanged
      // Product-level stock = sum of all batch stocks
      expect(updatedProduct.stockQuantity, 45); // 15 + 30
    });

    test('batch not found → throws StateError', () {
      final product = pharmacyProduct();
      productProvider.addProduct(product);

      expect(
        () => productProvider.decrementStock(
          product.id,
          5,
          batchId: 'nonexistent',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('insufficient batch stock → throws StateError', () {
      final product = pharmacyProduct();
      productProvider.addProduct(product);

      // BN-001 has stock=20, try to decrement 25
      final bn001 =
          product.batches.firstWhere((b) => b.batchNumber == 'BN-001');

      expect(
        () => productProvider.decrementStock(
          product.id,
          25,
          batchId: bn001.id,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('nearestExpiryBatch is the one expiring soonest', () {
      final now = DateTime.now();
      final pid = 'nearest-test';
      final batch30d = ProductBatch(
        productId: pid,
        batchNumber: 'SOON',
        expiryDate: now.add(const Duration(days: 30)),
        stockQuantity: 10,
      );
      final batch180d = ProductBatch(
        productId: pid,
        batchNumber: 'LATER',
        expiryDate: now.add(const Duration(days: 180)),
        stockQuantity: 10,
      );

      final product = Product(
        id: pid,
        name: 'Test Medicine',
        sellingPrice: 50,
        stockQuantity: 20,
        gstRate: 12.0,
        batches: [batch180d, batch30d], // intentionally out of order
      );

      expect(product.nearestExpiryBatch, isNotNull);
      expect(product.nearestExpiryBatch!.batchNumber, 'SOON');
    });
  });

  group('Pharmacy — Expiry Monitoring', () {
    test('expiringSoonCount reflects batches expiring within 90 days', () {
      final now = DateTime.now();
      final pid = 'expiry-monitor';
      final expiringSoonBatch = ProductBatch(
        productId: pid,
        batchNumber: 'EXP-SOON',
        expiryDate: now.add(const Duration(days: 60)), // within 90 days
        stockQuantity: 10,
      );
      final safeBatch = ProductBatch(
        productId: pid,
        batchNumber: 'SAFE',
        expiryDate: now.add(const Duration(days: 200)), // beyond 90 days
        stockQuantity: 15,
      );

      final product = Product(
        id: pid,
        name: 'Expiry Test Drug',
        sellingPrice: 40,
        stockQuantity: 25,
        gstRate: 12.0,
        batches: [expiringSoonBatch, safeBatch],
      );

      productProvider.addProduct(product);

      // expiringSoonCount counts products that have at least one expiring-soon batch
      expect(productProvider.expiringSoonCount, 1);

      // Add another product with no expiring batches
      final safeProduct = Product(
        id: 'safe-product',
        name: 'Safe Drug',
        sellingPrice: 30,
        stockQuantity: 50,
        batches: [
          ProductBatch(
            productId: 'safe-product',
            batchNumber: 'SAFE-2',
            expiryDate: now.add(const Duration(days: 365)),
            stockQuantity: 50,
          ),
        ],
      );
      productProvider.addProduct(safeProduct);

      // Still only 1 product with expiring-soon batches
      expect(productProvider.expiringSoonCount, 1);
    });
  });

  group('Pharmacy — Full Lifecycle', () {
    test('purchase → bill from batch → return', () {
      // 1. Add product (simulating a purchase)
      final product = pharmacyProduct(
        id: 'lifecycle-pharma',
        stockQuantity: 0,
      );
      productProvider.addProduct(product);

      final initial = productProvider.products.first;
      expect(initial.stockQuantity, 50); // sum of batch stocks (20 + 30)

      // 2. Create a bill from the nearest-expiry batch
      billProvider.addItemToBill(product, businessType: BusinessType.pharmacy);
      billProvider.updateQuantity(0, 3);

      final activeItem = billProvider.activeLineItems.first;
      expect(activeItem.batch!.batchNumber, 'BN-001');

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(amountReceived: 90),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Stock after sale
      final afterSale = productProvider.products.first;
      expect(afterSale.stockQuantity, 47); // 50 - 3
      final bn001After =
          afterSale.batches.firstWhere((b) => b.batchNumber == 'BN-001');
      expect(bn001After.stockQuantity, 17); // 20 - 3

      // 3. Process a return — re-increment stock
      final returnQty = 2;
      productProvider.incrementStock(product.id, returnQty.toDouble());

      final afterReturn = productProvider.products.first;
      // incrementStock adds to product-level stock (not batch-level)
      expect(afterReturn.stockQuantity, 49); // 47 + 2
    });
  });
}
