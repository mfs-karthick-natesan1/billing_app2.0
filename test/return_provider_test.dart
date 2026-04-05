import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/sales_return.dart';
import 'package:billing_app/models/return_line_item.dart';
import 'package:billing_app/providers/return_provider.dart';

SalesReturn _makeReturn({
  String? billId,
  String returnNumber = 'RET-001',
  DateTime? date,
  double qty = 1,
  double price = 100,
  RefundMode mode = RefundMode.cash,
}) {
  return SalesReturn(
    originalBillId: billId ?? 'bill-1',
    returnNumber: returnNumber,
    date: date ?? DateTime.now(),
    items: [
      ReturnLineItem(
        productId: 'prod-1',
        productName: 'Rice 5kg',
        quantityReturned: qty,
        pricePerUnit: price,
      ),
    ],
    refundMode: mode,
  );
}

void main() {
  group('ReturnProvider', () {
    late ReturnProvider provider;

    setUp(() {
      provider = ReturnProvider();
    });

    test('starts empty', () {
      expect(provider.returns, isEmpty);
      expect(provider.todayRefundTotal, 0.0);
    });

    test('addReturn adds a return', () {
      provider.addReturn(_makeReturn());
      expect(provider.returns.length, 1);
    });

    test('getReturnsByBill returns only matching returns', () {
      provider.addReturn(_makeReturn(billId: 'bill-1'));
      provider.addReturn(_makeReturn(billId: 'bill-2', returnNumber: 'RET-002'));
      expect(provider.getReturnsByBill('bill-1').length, 1);
      expect(provider.getReturnsByBill('bill-99'), isEmpty);
    });

    test('hasReturnForBill returns correct boolean', () {
      provider.addReturn(_makeReturn(billId: 'bill-1'));
      expect(provider.hasReturnForBill('bill-1'), isTrue);
      expect(provider.hasReturnForBill('bill-99'), isFalse);
    });

    test('todayRefundTotal sums todays returns', () {
      provider.addReturn(_makeReturn(qty: 2, price: 150));
      expect(provider.todayRefundTotal, 300.0);
    });

    test('todayRefundTotal excludes past returns', () {
      provider.addReturn(
        _makeReturn(date: DateTime(2020, 1, 1), qty: 1, price: 500),
      );
      expect(provider.todayRefundTotal, 0.0);
    });

    test('getReturnedQuantity sums previously returned qty per product', () {
      provider.addReturn(_makeReturn(billId: 'bill-1', qty: 2));
      expect(provider.getReturnedQuantity('bill-1', 'prod-1'), 2.0);
    });

    test('generateReturnNumber is sequential', () {
      final n1 = provider.generateReturnNumber();
      final n2 = provider.generateReturnNumber();
      expect(n1.endsWith('001'), isTrue);
      expect(n2.endsWith('002'), isTrue);
    });

    test('clearAllData empties returns and resets counter', () {
      provider.addReturn(_makeReturn());
      provider.clearAllData();
      expect(provider.returns, isEmpty);
      // Counter reset: next number starts at 001 again
      expect(provider.generateReturnNumber().endsWith('001'), isTrue);
    });

    test('getReturnsByDateRange filters correctly', () {
      final d1 = DateTime(2025, 3, 1);
      final d2 = DateTime(2025, 4, 1);
      provider.addReturn(_makeReturn(date: d1, returnNumber: 'RET-A'));
      provider.addReturn(_makeReturn(date: d2, returnNumber: 'RET-B'));

      final march = provider.getReturnsByDateRange(
        DateTime(2025, 3, 1),
        DateTime(2025, 3, 31),
      );
      expect(march.length, 1);
      expect(march.first.returnNumber, 'RET-A');
    });

    test('initialReturns are loaded in constructor', () {
      final r = _makeReturn(returnNumber: 'PRELOADED');
      final p = ReturnProvider(initialReturns: [r]);
      expect(p.returns.length, 1);
      expect(p.returns.first.returnNumber, 'PRELOADED');
    });
  });
}
