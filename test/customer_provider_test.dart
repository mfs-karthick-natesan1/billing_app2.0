import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/customer_payment_entry.dart';
import 'package:billing_app/providers/customer_provider.dart';

void main() {
  group('CustomerProvider', () {
    late CustomerProvider provider;

    setUp(() {
      provider = CustomerProvider();
    });

    test('starts with empty customer list', () {
      expect(provider.customers, isEmpty);
      expect(provider.totalOutstanding, 0.0);
    });

    test('addCustomer creates a new customer', () {
      final c = provider.addCustomer(name: 'Ravi Kumar', phone: '9876543210');
      expect(provider.customers.length, 1);
      expect(c.name, 'Ravi Kumar');
      expect(c.phone, '9876543210');
    });

    test('addCustomer with duplicate name returns existing customer', () {
      final first = provider.addCustomer(name: 'Priya');
      final second = provider.addCustomer(name: 'Priya');
      expect(provider.customers.length, 1);
      expect(first.id, second.id);
    });

    test('addCredit increases outstandingBalance', () {
      final c = provider.addCustomer(name: 'Amit');
      provider.addCredit(c.id, 500.0);
      expect(provider.customers.first.outstandingBalance, 500.0);
      expect(provider.totalOutstanding, 500.0);
    });

    test('addCredit sets lastCreditDate', () {
      final c = provider.addCustomer(name: 'Suma');
      expect(c.lastCreditDate, isNull);
      provider.addCredit(c.id, 200.0);
      expect(provider.customers.first.lastCreditDate, isNotNull);
    });

    test('recordPayment reduces outstandingBalance and adds payment entry', () {
      final c = provider.addCustomer(name: 'Raj');
      provider.addCredit(c.id, 1000.0);
      provider.recordPayment(c.id, 400.0);
      expect(provider.customers.first.outstandingBalance, 600.0);
      expect(provider.paymentEntries.length, 1);
      expect(provider.paymentEntries.first.amount, 400.0);
    });

    test('recordPayment clamps balance to 0', () {
      final c = provider.addCustomer(name: 'Leena');
      provider.addCredit(c.id, 100.0);
      provider.recordPayment(c.id, 500.0); // overpayment
      expect(provider.customers.first.outstandingBalance, 0.0);
    });

    test('addAdvance and deductAdvance manage advanceBalance correctly', () {
      final c = provider.addCustomer(name: 'Deepa');
      provider.addAdvance(c.id, 300.0);
      expect(provider.customers.first.advanceBalance, 300.0);
      provider.deductAdvance(c.id, 100.0);
      expect(provider.customers.first.advanceBalance, 200.0);
    });

    test('deductAdvance clamps to 0', () {
      final c = provider.addCustomer(name: 'Kumar');
      provider.addAdvance(c.id, 50.0);
      provider.deductAdvance(c.id, 200.0);
      expect(provider.customers.first.advanceBalance, 0.0);
    });

    test('getPaymentHistory returns entries for specific customer sorted desc', () {
      final c1 = provider.addCustomer(name: 'A');
      final c2 = provider.addCustomer(name: 'B');
      provider.addCredit(c1.id, 500.0);
      provider.addCredit(c2.id, 300.0);
      final d1 = DateTime(2025, 1, 1);
      final d2 = DateTime(2025, 1, 5);
      provider.recordPayment(c1.id, 100.0, recordedAt: d1);
      provider.recordPayment(c1.id, 200.0, recordedAt: d2);
      provider.recordPayment(c2.id, 150.0);

      final history = provider.getPaymentHistory(c1.id);
      expect(history.length, 2);
      expect(history.first.recordedAt, d2); // newest first
      expect(history.last.recordedAt, d1);
    });

    test('getTotalPayments sums all payments for a customer', () {
      final c = provider.addCustomer(name: 'Total');
      provider.addCredit(c.id, 1000.0);
      provider.recordPayment(c.id, 300.0);
      provider.recordPayment(c.id, 200.0);
      expect(provider.getTotalPayments(c.id), 500.0);
    });

    test('totalOutstanding sums across all customers', () {
      final c1 = provider.addCustomer(name: 'X');
      final c2 = provider.addCustomer(name: 'Y');
      provider.addCredit(c1.id, 400.0);
      provider.addCredit(c2.id, 600.0);
      expect(provider.totalOutstanding, 1000.0);
    });

    test('searchCustomers returns matching customers', () {
      provider.addCustomer(name: 'Ravi Kumar');
      provider.addCustomer(name: 'Priya Singh');
      provider.addCustomer(name: 'Ravi Shankar');
      final results = provider.searchCustomers('ravi');
      expect(results.length, 2);
      expect(results.every((c) => c.name.toLowerCase().contains('ravi')), isTrue);
    });

    test('initialCustomers are loaded in constructor', () {
      final c = Customer(name: 'Preloaded', outstandingBalance: 250.0);
      final p = CustomerProvider(initialCustomers: [c]);
      expect(p.customers.length, 1);
      expect(p.customers.first.name, 'Preloaded');
      expect(p.totalOutstanding, 250.0);
    });

    test('getPaymentEntriesByDateRange filters by date range', () {
      final c = provider.addCustomer(name: 'DateRange');
      provider.addCredit(c.id, 1000.0);
      final d1 = DateTime(2025, 3, 1);
      final d2 = DateTime(2025, 3, 15);
      final d3 = DateTime(2025, 4, 1);
      provider.recordPayment(c.id, 100.0, recordedAt: d1);
      provider.recordPayment(c.id, 200.0, recordedAt: d2);
      provider.recordPayment(c.id, 300.0, recordedAt: d3);

      final range = provider.getPaymentEntriesByDateRange(
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 31),
      );
      expect(range.length, 2);
      expect(range.map((e) => e.amount).toSet(), {100.0, 200.0});
    });

    test('getCashReceivedInDateRange filters by cash payment mode', () {
      final c = provider.addCustomer(name: 'PayMode');
      provider.addCredit(c.id, 1000.0);
      final d = DateTime(2025, 3, 10);
      provider.recordPayment(c.id, 200.0,
          paymentMode: SettlementPaymentMode.cash, recordedAt: d);
      provider.recordPayment(c.id, 300.0,
          paymentMode: SettlementPaymentMode.upi, recordedAt: d);

      final cash = provider.getCashReceivedInDateRange(
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 31),
      );
      expect(cash, 200.0);
    });
  });
}
