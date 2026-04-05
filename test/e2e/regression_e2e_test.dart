import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/return_line_item.dart';
import 'package:billing_app/models/sales_return.dart';
import 'package:billing_app/models/app_user.dart';
import 'package:billing_app/models/user_role.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/return_provider.dart';
import 'package:billing_app/providers/user_provider.dart';
import 'package:billing_app/services/gst_calculator.dart';
import 'helpers/test_fixtures.dart';

void main() {
  // ── Issue #6 — Negative stock prevention ─────────────────────────────────

  group('Issue #6 — Negative stock prevention', () {
    late ProductProvider productProvider;

    setUp(() {
      productProvider = ProductProvider();
    });

    test('decrementStock with qty > available throws StateError', () {
      final product = generalProduct(stockQuantity: 5);
      productProvider.addProduct(product);

      expect(
        () => productProvider.decrementStock(product.id!, 10),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Insufficient stock'),
        )),
      );

      // Stock should remain unchanged
      expect(productProvider.findById(product.id!)!.stockQuantity, equals(5));
    });

    test('decrementStock with exact qty succeeds (stock = 0)', () {
      final product = generalProduct(stockQuantity: 5);
      productProvider.addProduct(product);

      productProvider.decrementStock(product.id!, 5);

      expect(productProvider.findById(product.id!)!.stockQuantity, equals(0));
    });

    test('decrementStock with qty = 0 is a no-op', () {
      final product = generalProduct(stockQuantity: 10);
      productProvider.addProduct(product);

      productProvider.decrementStock(product.id!, 0);

      expect(productProvider.findById(product.id!)!.stockQuantity, equals(10));
    });
  });

  // ── Issue #7 — PIN rate limiting ─────────────────────────────────────────

  group('Issue #7 — PIN rate limiting', () {
    late UserProvider userProvider;
    late String userId;
    const correctPin = '1234';
    const wrongPin = '9999';

    setUp(() {
      userProvider = UserProvider();
      // Create owner first to enable multi-user mode
      userProvider.createOwnerAndEnableManagement(
        name: 'Owner',
        phone: '9000000001',
        pin: correctPin,
      );
      userId = userProvider.currentUser!.id;
      // Logout so we can test login
      userProvider.logout();
    });

    test('5 failed login attempts → account locked out', () {
      for (var i = 0; i < 5; i++) {
        userProvider.loginByUserId(userId, wrongPin);
      }

      expect(userProvider.isAccountLockedOut(userId), isTrue);
      expect(userProvider.remainingAttempts(userId), equals(0));

      // Even correct PIN should fail while locked
      final result = userProvider.loginByUserId(userId, correctPin);
      expect(result, isFalse);
    });

    test('successful login resets failed attempts', () {
      // Fail 3 times
      for (var i = 0; i < 3; i++) {
        userProvider.loginByUserId(userId, wrongPin);
      }
      expect(userProvider.remainingAttempts(userId), equals(2));

      // Successful login
      userProvider.loginByUserId(userId, correctPin);
      expect(userProvider.remainingAttempts(userId), equals(5));
    });

    test('remainingAttempts decreases on each failure', () {
      expect(userProvider.remainingAttempts(userId), equals(5));

      userProvider.loginByUserId(userId, wrongPin);
      expect(userProvider.remainingAttempts(userId), equals(4));

      userProvider.loginByUserId(userId, wrongPin);
      expect(userProvider.remainingAttempts(userId), equals(3));

      userProvider.loginByUserId(userId, wrongPin);
      expect(userProvider.remainingAttempts(userId), equals(2));
    });

    test('unlockApp also rate-limited', () {
      // Login first so we have a current user, then lock
      userProvider.loginByUserId(userId, correctPin);
      userProvider.lockApp();

      // Fail 5 unlock attempts
      for (var i = 0; i < 5; i++) {
        userProvider.unlockApp(wrongPin);
      }

      expect(userProvider.isAccountLockedOut(userId), isTrue);
      // Even correct PIN should fail while locked out
      expect(userProvider.unlockApp(correctPin), isFalse);
    });
  });

  // ── Issue #9 — Batch not found throws error ──────────────────────────────

  group('Issue #9 — Batch not found throws error', () {
    late ProductProvider productProvider;

    setUp(() {
      productProvider = ProductProvider();
    });

    test('decrementStock with invalid batchId throws StateError', () {
      final product = pharmacyProduct();
      productProvider.addProduct(product);

      expect(
        () => productProvider.decrementStock(
          product.id!,
          1,
          batchId: 'nonexistent-batch',
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Batch nonexistent-batch not found'),
        )),
      );
    });

    test('decrementStock with insufficient batch stock throws StateError', () {
      final product = pharmacyProduct();
      productProvider.addProduct(product);

      final batch = product.batches.first;

      expect(
        () => productProvider.decrementStock(
          product.id!,
          batch.stockQuantity + 10,
          batchId: batch.id,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Insufficient batch stock'),
        )),
      );
    });

    test('decrementStock with valid batchId succeeds', () {
      final product = pharmacyProduct();
      productProvider.addProduct(product);

      final batch = product.batches.first;
      final originalStock = batch.stockQuantity;

      productProvider.decrementStock(product.id!, 5, batchId: batch.id);

      final updated = productProvider.findById(product.id!)!;
      final updatedBatch = updated.batches.firstWhere((b) => b.id == batch.id);
      expect(updatedBatch.stockQuantity, equals(originalStock - 5));
    });
  });

  // ── Issue #11 — GST rounding ─────────────────────────────────────────────

  group('Issue #11 — GST rounding', () {
    late BillProvider billProvider;
    late ProductProvider productProvider;
    late CustomerProvider customerProvider;

    setUp(() {
      billProvider = BillProvider();
      productProvider = ProductProvider();
      customerProvider = CustomerProvider();
    });

    test('cgst/sgst/igst rounded to 2 decimals', () {
      // Use a price that causes floating-point drift: 33.33 * 3 * 18%
      final product = generalProduct(
        sellingPrice: 33.33,
        stockQuantity: 100,
        gstRate: 18.0,
      );
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      billProvider.updateQuantity(0, 3);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Verify 2-decimal rounding (multiply by 100, round, divide by 100 = same value)
      expect(_isRoundedTo2Decimals(bill.cgst), isTrue,
          reason: 'CGST ${bill.cgst} not rounded to 2 decimals');
      expect(_isRoundedTo2Decimals(bill.sgst), isTrue,
          reason: 'SGST ${bill.sgst} not rounded to 2 decimals');
      expect(_isRoundedTo2Decimals(bill.grandTotal), isTrue,
          reason: 'grandTotal ${bill.grandTotal} not rounded to 2 decimals');
    });

    test('grandTotal rounded to 2 decimals for high-value items', () {
      // Jewellery: Rs 59,999.99 * 1 @ 3% GST
      final product = jewelleryProduct(
        sellingPrice: 59999.99,
        stockQuantity: 5,
      );
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(_isRoundedTo2Decimals(bill.cgst), isTrue);
      expect(_isRoundedTo2Decimals(bill.sgst), isTrue);
      expect(_isRoundedTo2Decimals(bill.grandTotal), isTrue);
    });

    test('GstCalculator methods return 2-decimal values', () {
      final product = generalProduct(
        sellingPrice: 99.99,
        stockQuantity: 50,
        gstRate: 18.0,
      );
      final items = [LineItem(product: product, quantity: 7)];

      final cgst = GstCalculator.totalCgst(items);
      final sgst = GstCalculator.totalSgst(items);
      final igst = GstCalculator.totalIgst(items);
      final grand = GstCalculator.grandTotal(items);

      expect(_isRoundedTo2Decimals(cgst), isTrue, reason: 'CGST $cgst');
      expect(_isRoundedTo2Decimals(sgst), isTrue, reason: 'SGST $sgst');
      expect(_isRoundedTo2Decimals(igst), isTrue, reason: 'IGST $igst');
      expect(_isRoundedTo2Decimals(grand), isTrue, reason: 'Grand $grand');
    });
  });

  // ── Issue #13 — Return qty validation ────────────────────────────────────

  group('Issue #13 — Return qty validation', () {
    late BillProvider billProvider;
    late ProductProvider productProvider;
    late CustomerProvider customerProvider;
    late ReturnProvider returnProvider;

    setUp(() {
      billProvider = BillProvider();
      productProvider = ProductProvider();
      customerProvider = CustomerProvider();
      returnProvider = ReturnProvider();
    });

    test('return qty > original bill qty throws StateError', () {
      final product = generalProduct(stockQuantity: 50, gstRate: 0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      billProvider.updateQuantity(0, 5);
      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      final salesReturn = SalesReturn(
        originalBillId: bill.id,
        returnNumber: 'RET-001',
        items: [
          ReturnLineItem(
            productId: product.id!,
            productName: product.name,
            quantityReturned: 10, // More than the 5 sold
            pricePerUnit: product.sellingPrice,
          ),
        ],
      );

      expect(
        () => returnProvider.addReturn(salesReturn, originalBill: bill),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('exceeds returnable quantity'),
        )),
      );
    });

    test('cumulative returns exceed original throws StateError', () {
      final product = generalProduct(stockQuantity: 50, gstRate: 0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      billProvider.updateQuantity(0, 5);
      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // First return of 3 — should succeed
      final return1 = SalesReturn(
        originalBillId: bill.id,
        returnNumber: 'RET-001',
        items: [
          ReturnLineItem(
            productId: product.id!,
            productName: product.name,
            quantityReturned: 3,
            pricePerUnit: product.sellingPrice,
          ),
        ],
      );
      returnProvider.addReturn(return1, originalBill: bill);
      expect(returnProvider.returns.length, equals(1));

      // Second return of 3 — total would be 6, exceeding original qty of 5
      final return2 = SalesReturn(
        originalBillId: bill.id,
        returnNumber: 'RET-002',
        items: [
          ReturnLineItem(
            productId: product.id!,
            productName: product.name,
            quantityReturned: 3,
            pricePerUnit: product.sellingPrice,
          ),
        ],
      );
      expect(
        () => returnProvider.addReturn(return2, originalBill: bill),
        throwsA(isA<StateError>()),
      );
    });

    test('return qty = remaining returnable qty succeeds', () {
      final product = generalProduct(stockQuantity: 50, gstRate: 0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      billProvider.updateQuantity(0, 5);
      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Return 3 first
      final return1 = SalesReturn(
        originalBillId: bill.id,
        returnNumber: 'RET-001',
        items: [
          ReturnLineItem(
            productId: product.id!,
            productName: product.name,
            quantityReturned: 3,
            pricePerUnit: product.sellingPrice,
          ),
        ],
      );
      returnProvider.addReturn(return1, originalBill: bill);

      // Return remaining 2 — should succeed
      final return2 = SalesReturn(
        originalBillId: bill.id,
        returnNumber: 'RET-002',
        items: [
          ReturnLineItem(
            productId: product.id!,
            productName: product.name,
            quantityReturned: 2,
            pricePerUnit: product.sellingPrice,
          ),
        ],
      );
      returnProvider.addReturn(return2, originalBill: bill);
      expect(returnProvider.returns.length, equals(2));
    });
  });

  // ── Issue #18 — _resetActiveState ────────────────────────────────────────

  group('Issue #18 — _resetActiveState', () {
    late BillProvider billProvider;
    late ProductProvider productProvider;
    late CustomerProvider customerProvider;

    setUp(() {
      billProvider = BillProvider();
      productProvider = ProductProvider();
      customerProvider = CustomerProvider();
    });

    test('completeBill clears all active state', () {
      final product = generalProduct(stockQuantity: 50, gstRate: 0);
      final customer = testCustomer();
      productProvider.addProduct(product);

      // Set up rich active state
      billProvider.addItemToBill(product);
      billProvider.setActiveCustomer(customer);
      billProvider.setVisitNotes(diagnosis: 'Test diagnosis', visitNotes: 'Notes');
      billProvider.setVehicleInfo(
        vehicleReg: 'KA-01-1234',
        vehicleMake: 'Honda',
        vehicleModel: 'City',
        kmReading: '50000',
      );
      billProvider.setDiscount(isPercent: false, value: 10);

      // Verify active state is populated
      expect(billProvider.hasActiveItems, isTrue);
      expect(billProvider.activeCustomer, isNotNull);
      expect(billProvider.activeDiagnosis, isNotNull);
      expect(billProvider.activeVehicleReg, isNotNull);

      // Complete the bill
      billProvider.completeBill(
        paymentInfo: cashPayment(amountReceived: 240),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // All active state should be cleared
      expect(billProvider.hasActiveItems, isFalse);
      expect(billProvider.activeCustomer, isNull);
      expect(billProvider.activeDiagnosis, isNull);
      expect(billProvider.activeVisitNotes, isNull);
      expect(billProvider.activeVehicleReg, isNull);
      expect(billProvider.activeVehicleMake, isNull);
      expect(billProvider.activeVehicleModel, isNull);
      expect(billProvider.activeKmReading, isNull);
      expect(billProvider.discountAmount, equals(0));
      expect(billProvider.isEditMode, isFalse);
    });

    test('clearActiveBill clears all active state', () {
      final product = generalProduct(stockQuantity: 50, gstRate: 0);
      productProvider.addProduct(product);

      // Set up active state
      billProvider.addItemToBill(product);
      billProvider.setActiveCustomer(testCustomer());
      billProvider.setVisitNotes(diagnosis: 'Diagnosis', visitNotes: 'Notes');
      billProvider.setVehicleInfo(vehicleReg: 'TN-01-5678');

      expect(billProvider.hasActiveItems, isTrue);

      // Clear without completing
      billProvider.clearActiveBill();

      // All active state should be cleared
      expect(billProvider.hasActiveItems, isFalse);
      expect(billProvider.activeCustomer, isNull);
      expect(billProvider.activeDiagnosis, isNull);
      expect(billProvider.activeVisitNotes, isNull);
      expect(billProvider.activeVehicleReg, isNull);
      expect(billProvider.activeVehicleMake, isNull);
      expect(billProvider.activeVehicleModel, isNull);
      expect(billProvider.activeKmReading, isNull);
    });
  });
}

/// Helper: checks that a double is rounded to at most 2 decimal places.
bool _isRoundedTo2Decimals(double value) {
  return (value * 100).roundToDouble() / 100 == value;
}
