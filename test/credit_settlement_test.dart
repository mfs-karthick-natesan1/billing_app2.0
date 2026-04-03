import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/customer_payment_entry.dart';
import 'package:billing_app/providers/customer_provider.dart';

void main() {
  group('CustomerPaymentEntry enhancements', () {
    test('notes and billReference fields default to null', () {
      final entry = CustomerPaymentEntry(
        customerId: 'c1',
        amount: 500,
      );
      expect(entry.notes, isNull);
      expect(entry.billReference, isNull);
    });

    test('notes and billReference can be set', () {
      final entry = CustomerPaymentEntry(
        customerId: 'c1',
        amount: 500,
        notes: 'Partial payment',
        billReference: 'INV-001',
      );
      expect(entry.notes, 'Partial payment');
      expect(entry.billReference, 'INV-001');
    });

    test('toJson includes notes and billReference', () {
      final entry = CustomerPaymentEntry(
        customerId: 'c1',
        amount: 300,
        notes: 'Cheque #456',
        billReference: 'INV-002',
      );
      final json = entry.toJson();
      expect(json['notes'], 'Cheque #456');
      expect(json['billReference'], 'INV-002');
    });

    test('fromJson reads notes and billReference', () {
      final entry = CustomerPaymentEntry.fromJson({
        'customerId': 'c1',
        'amount': 200,
        'notes': 'Cash received',
        'billReference': 'INV-003',
      });
      expect(entry.notes, 'Cash received');
      expect(entry.billReference, 'INV-003');
    });

    test('fromJson handles missing notes and billReference', () {
      final entry = CustomerPaymentEntry.fromJson({
        'customerId': 'c1',
        'amount': 200,
      });
      expect(entry.notes, isNull);
      expect(entry.billReference, isNull);
    });

    test('copyWith preserves notes and billReference', () {
      final entry = CustomerPaymentEntry(
        customerId: 'c1',
        amount: 100,
        notes: 'Original',
        billReference: 'INV-001',
      );
      final copied = entry.copyWith(amount: 200);
      expect(copied.amount, 200);
      expect(copied.notes, 'Original');
      expect(copied.billReference, 'INV-001');
    });

    test('copyWith can override notes and billReference', () {
      final entry = CustomerPaymentEntry(
        customerId: 'c1',
        amount: 100,
        notes: 'Original',
        billReference: 'INV-001',
      );
      final copied = entry.copyWith(
        notes: 'Updated',
        billReference: 'INV-002',
      );
      expect(copied.notes, 'Updated');
      expect(copied.billReference, 'INV-002');
    });

    test('toJson/fromJson round-trip preserves all fields', () {
      final original = CustomerPaymentEntry(
        customerId: 'c1',
        amount: 750,
        paymentMode: SettlementPaymentMode.upi,
        notes: 'UPI transfer',
        billReference: 'INV-010',
        recordedBy: 'admin',
      );
      final json = original.toJson();
      final restored = CustomerPaymentEntry.fromJson(json);
      expect(restored.customerId, 'c1');
      expect(restored.amount, 750);
      expect(restored.paymentMode, SettlementPaymentMode.upi);
      expect(restored.notes, 'UPI transfer');
      expect(restored.billReference, 'INV-010');
      expect(restored.recordedBy, 'admin');
    });
  });

  group('CustomerProvider credit settlement', () {
    late CustomerProvider provider;
    late String customerId;
    int changeCount = 0;

    setUp(() {
      changeCount = 0;
      provider = CustomerProvider(onChanged: () => changeCount++);
      final customer = provider.addCustomer(name: 'Test Customer');
      customerId = customer.id;
      provider.addCredit(customerId, 1000);
      changeCount = 0; // reset after setup
    });

    test('recordPayment with notes and billReference', () {
      provider.recordPayment(
        customerId,
        200,
        notes: 'Cash collected',
        billReference: 'INV-001',
      );
      final history = provider.getPaymentHistory(customerId);
      expect(history.length, 1);
      expect(history.first.notes, 'Cash collected');
      expect(history.first.billReference, 'INV-001');
      expect(history.first.amount, 200);
    });

    test('recordPayment reduces outstanding balance', () {
      provider.recordPayment(customerId, 300);
      final customer = provider.findById(customerId);
      expect(customer!.outstandingBalance, 700);
    });

    test('recordPayment clamps balance to zero', () {
      provider.recordPayment(customerId, 1500);
      final customer = provider.findById(customerId);
      expect(customer!.outstandingBalance, 0);
    });

    test('getPaymentHistory returns sorted by date desc', () {
      provider.recordPayment(
        customerId,
        100,
        recordedAt: DateTime(2026, 1, 1),
      );
      provider.recordPayment(
        customerId,
        200,
        recordedAt: DateTime(2026, 1, 15),
      );
      provider.recordPayment(
        customerId,
        300,
        recordedAt: DateTime(2026, 1, 10),
      );
      final history = provider.getPaymentHistory(customerId);
      expect(history.length, 3);
      expect(history[0].amount, 200); // Jan 15 (newest)
      expect(history[1].amount, 300); // Jan 10
      expect(history[2].amount, 100); // Jan 1 (oldest)
    });

    test('getPaymentHistory returns empty for unknown customer', () {
      final history = provider.getPaymentHistory('nonexistent');
      expect(history, isEmpty);
    });

    test('getTotalPayments accumulates correctly', () {
      provider.recordPayment(customerId, 100);
      provider.recordPayment(customerId, 250);
      provider.recordPayment(customerId, 50);
      expect(provider.getTotalPayments(customerId), 400);
    });

    test('getTotalPayments returns 0 for unknown customer', () {
      expect(provider.getTotalPayments('nonexistent'), 0);
    });

    test('recordPayment with different payment modes', () {
      provider.recordPayment(
        customerId,
        100,
        paymentMode: SettlementPaymentMode.cash,
      );
      provider.recordPayment(
        customerId,
        200,
        paymentMode: SettlementPaymentMode.upi,
      );
      provider.recordPayment(
        customerId,
        300,
        paymentMode: SettlementPaymentMode.bankTransfer,
      );
      final history = provider.getPaymentHistory(customerId);
      expect(history.length, 3);
      final modes = history.map((h) => h.paymentMode).toSet();
      expect(modes, containsAll(SettlementPaymentMode.values));
    });

    test('multiple partial settlements reduce balance correctly', () {
      provider.recordPayment(customerId, 200);
      provider.recordPayment(customerId, 300);
      provider.recordPayment(customerId, 150);
      final customer = provider.findById(customerId);
      expect(customer!.outstandingBalance, 350);
      expect(provider.getTotalPayments(customerId), 650);
    });

    test('recordPayment notifies listeners and persists', () {
      provider.recordPayment(customerId, 100);
      expect(changeCount, 1);
    });

    test('clearAllData clears payment entries', () {
      provider.recordPayment(customerId, 100);
      provider.recordPayment(customerId, 200);
      provider.clearAllData();
      expect(provider.paymentEntries, isEmpty);
    });

    test('getPaymentEntriesByDateRange filters correctly', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      provider.recordPayment(customerId, 100, recordedAt: today);
      provider.recordPayment(customerId, 200, recordedAt: yesterday);

      final todayOnly = provider.getPaymentEntriesByDateRange(today, today);
      expect(todayOnly.length, 1);
      expect(todayOnly.first.amount, 100);
    });

    test('getPaymentEntriesByDateRange filters by payment mode', () {
      final today = DateTime.now();
      provider.recordPayment(
        customerId,
        100,
        recordedAt: today,
        paymentMode: SettlementPaymentMode.cash,
      );
      provider.recordPayment(
        customerId,
        200,
        recordedAt: today,
        paymentMode: SettlementPaymentMode.upi,
      );

      final cashOnly = provider.getPaymentEntriesByDateRange(
        today,
        today,
        paymentMode: SettlementPaymentMode.cash,
      );
      expect(cashOnly.length, 1);
      expect(cashOnly.first.amount, 100);
    });
  });
}
