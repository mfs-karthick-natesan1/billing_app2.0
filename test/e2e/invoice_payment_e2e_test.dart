import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/customer_payment_entry.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'helpers/test_fixtures.dart';

void main() {
  // ── #43 — Invoice-level payment linkage ──────────────────────────────────

  group('Invoice-level payment linkage', () {
    late BillProvider billProvider;
    late ProductProvider productProvider;
    late CustomerProvider customerProvider;

    setUp(() {
      billProvider = BillProvider();
      productProvider = ProductProvider();
      customerProvider = CustomerProvider();
    });

    test('recordPayment with billReference links payment to invoice', () {
      final customer = testCustomer();
      customerProvider = CustomerProvider(initialCustomers: [customer]);
      final product = generalProduct(stockQuantity: 50, gstRate: 0);
      productProvider.addProduct(product);

      // Create a credit bill
      billProvider.addItemToBill(product);
      billProvider.updateQuantity(0, 4); // 4 * 250 = 1000
      final bill = billProvider.completeBill(
        paymentInfo: creditPayment(customer: customer, creditAmount: 1000),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Record partial payment linked to this bill
      customerProvider.recordPayment(
        customer.id!,
        400,
        billReference: bill.id,
        notes: 'Partial payment',
      );

      final payments = customerProvider.getPaymentsForBill(bill.id);
      expect(payments.length, equals(1));
      expect(payments.first.amount, equals(400));
      expect(payments.first.billReference, equals(bill.id));
    });

    test('getPaidAmountForBill sums all linked payments', () {
      final customer = testCustomer();
      customerProvider = CustomerProvider(initialCustomers: [customer]);
      final product = generalProduct(stockQuantity: 50, gstRate: 0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      billProvider.updateQuantity(0, 4);
      final bill = billProvider.completeBill(
        paymentInfo: creditPayment(customer: customer, creditAmount: 1000),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Make 3 partial payments
      customerProvider.recordPayment(customer.id!, 300, billReference: bill.id);
      customerProvider.recordPayment(customer.id!, 200, billReference: bill.id);
      customerProvider.recordPayment(customer.id!, 100, billReference: bill.id);

      expect(customerProvider.getPaidAmountForBill(bill.id), equals(600));
    });

    test('getOutstandingForBill returns remaining balance', () {
      final customer = testCustomer();
      customerProvider = CustomerProvider(initialCustomers: [customer]);
      final product = generalProduct(stockQuantity: 50, gstRate: 0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      billProvider.updateQuantity(0, 4);
      final bill = billProvider.completeBill(
        paymentInfo: creditPayment(customer: customer, creditAmount: 1000),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      customerProvider.recordPayment(customer.id!, 600, billReference: bill.id);

      final outstanding = customerProvider.getOutstandingForBill(bill.id, 1000);
      expect(outstanding, equals(400));
    });

    test('full payment brings outstanding to 0', () {
      final customer = testCustomer();
      customerProvider = CustomerProvider(initialCustomers: [customer]);
      final product = generalProduct(stockQuantity: 50, gstRate: 0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      final bill = billProvider.completeBill(
        paymentInfo: creditPayment(customer: customer, creditAmount: 250),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      customerProvider.recordPayment(customer.id!, 250, billReference: bill.id);

      expect(customerProvider.getOutstandingForBill(bill.id, 250), equals(0));
      expect(customerProvider.customers.first.outstandingBalance, equals(0));
    });

    test('payments without billReference not counted for specific bill', () {
      final customer = testCustomer();
      customerProvider = CustomerProvider(initialCustomers: [customer]);

      // Add credit manually
      customerProvider.addCredit(customer.id!, 1000);

      // Record a general payment (no billReference)
      customerProvider.recordPayment(customer.id!, 500);

      // Record a bill-linked payment
      customerProvider.recordPayment(
        customer.id!,
        200,
        billReference: 'bill-123',
      );

      expect(customerProvider.getPaidAmountForBill('bill-123'), equals(200));
      // General payment should not appear in bill-specific query
      expect(customerProvider.getPaymentsForBill('bill-123').length, equals(1));
    });
  });

  // ── #50 — Cheque clearing workflow ───────────────────────────────────────

  group('Cheque clearing workflow', () {
    late CustomerProvider customerProvider;

    setUp(() {
      final customer = testCustomer();
      customerProvider = CustomerProvider(initialCustomers: [customer]);
      // Give customer some credit
      customerProvider.addCredit(customer.id!, 5000);
    });

    String get customerId => customerProvider.customers.first.id!;

    test('recordChequePayment creates entry with pending status', () {
      customerProvider.recordChequePayment(
        customerId,
        2000,
        chequeNumber: 'CHQ-001',
        chequeBank: 'SBI',
        chequeDate: DateTime(2026, 4, 10),
      );

      final entries = customerProvider.getPaymentHistory(customerId);
      expect(entries.length, equals(1));
      expect(entries.first.paymentMode, equals(PaymentMethod.cheque));
      expect(entries.first.chequeNumber, equals('CHQ-001'));
      expect(entries.first.chequeBank, equals('SBI'));
      expect(entries.first.chequeStatus, equals(ChequeStatus.pending));
      expect(entries.first.isPendingCheque, isTrue);

      // Outstanding should be reduced optimistically
      expect(customerProvider.customers.first.outstandingBalance, equals(3000));
    });

    test('clearCheque marks cheque as cleared', () {
      customerProvider.recordChequePayment(
        customerId,
        2000,
        chequeNumber: 'CHQ-001',
      );

      final entryId = customerProvider.paymentEntries.first.id;
      final result = customerProvider.clearCheque(entryId);

      expect(result, isTrue);
      expect(
        customerProvider.paymentEntries.first.chequeStatus,
        equals(ChequeStatus.cleared),
      );
      // Outstanding remains reduced (was already deducted on record)
      expect(customerProvider.customers.first.outstandingBalance, equals(3000));
    });

    test('bounceCheque reverses the balance deduction', () {
      customerProvider.recordChequePayment(
        customerId,
        2000,
        chequeNumber: 'CHQ-001',
      );

      expect(customerProvider.customers.first.outstandingBalance, equals(3000));

      final entryId = customerProvider.paymentEntries.first.id;
      final result = customerProvider.bounceCheque(entryId);

      expect(result, isTrue);
      expect(
        customerProvider.paymentEntries.first.chequeStatus,
        equals(ChequeStatus.bounced),
      );
      // Outstanding should be restored
      expect(customerProvider.customers.first.outstandingBalance, equals(5000));
    });

    test('cannot clear an already bounced cheque', () {
      customerProvider.recordChequePayment(
        customerId,
        2000,
        chequeNumber: 'CHQ-001',
      );

      final entryId = customerProvider.paymentEntries.first.id;
      customerProvider.bounceCheque(entryId);

      // Try to clear a bounced cheque
      expect(customerProvider.clearCheque(entryId), isFalse);
    });

    test('cannot bounce an already cleared cheque', () {
      customerProvider.recordChequePayment(
        customerId,
        2000,
        chequeNumber: 'CHQ-001',
      );

      final entryId = customerProvider.paymentEntries.first.id;
      customerProvider.clearCheque(entryId);

      // Try to bounce a cleared cheque
      expect(customerProvider.bounceCheque(entryId), isFalse);
    });

    test('pendingCheques returns only pending entries', () {
      customerProvider.recordChequePayment(
        customerId,
        1000,
        chequeNumber: 'CHQ-001',
      );
      customerProvider.recordChequePayment(
        customerId,
        500,
        chequeNumber: 'CHQ-002',
      );

      expect(customerProvider.pendingCheques.length, equals(2));

      // Clear one
      final firstId = customerProvider.paymentEntries.first.id;
      customerProvider.clearCheque(firstId);

      expect(customerProvider.pendingCheques.length, equals(1));
      expect(customerProvider.pendingCheques.first.chequeNumber, equals('CHQ-002'));
    });

    test('bounced cheque excluded from getPaidAmountForBill', () {
      customerProvider.recordChequePayment(
        customerId,
        2000,
        chequeNumber: 'CHQ-001',
        billReference: 'bill-abc',
      );

      expect(customerProvider.getPaidAmountForBill('bill-abc'), equals(2000));

      // Bounce the cheque
      final entryId = customerProvider.paymentEntries.first.id;
      customerProvider.bounceCheque(entryId);

      // Bounced cheque should not count as paid
      expect(customerProvider.getPaidAmountForBill('bill-abc'), equals(0));
    });

    test('cheque payment serialization roundtrip', () {
      customerProvider.recordChequePayment(
        customerId,
        1500,
        chequeNumber: 'CHQ-123',
        chequeBank: 'HDFC',
        chequeDate: DateTime(2026, 4, 15),
        notes: 'Q1 payment',
      );

      final entry = customerProvider.paymentEntries.first;
      final json = entry.toJson();
      final restored = CustomerPaymentEntry.fromJson(json);

      expect(restored.chequeNumber, equals('CHQ-123'));
      expect(restored.chequeBank, equals('HDFC'));
      expect(restored.chequeDate, equals(DateTime(2026, 4, 15)));
      expect(restored.chequeStatus, equals(ChequeStatus.pending));
      expect(restored.paymentMode, equals(PaymentMethod.cheque));
      expect(restored.amount, equals(1500));
    });
  });
}
