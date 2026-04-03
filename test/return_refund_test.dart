import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/return_line_item.dart';
import 'package:billing_app/models/sales_return.dart';
import 'package:billing_app/providers/return_provider.dart';

void main() {
  group('ReturnLineItem', () {
    test('computes refundAmount from qty * price', () {
      final item = ReturnLineItem(
        productId: 'p1',
        productName: 'Widget',
        quantityReturned: 3,
        pricePerUnit: 100,
      );
      expect(item.refundAmount, 300);
    });

    test('accepts explicit refundAmount', () {
      final item = ReturnLineItem(
        productId: 'p1',
        productName: 'Widget',
        quantityReturned: 3,
        pricePerUnit: 100,
        refundAmount: 250,
      );
      expect(item.refundAmount, 250);
    });

    test('toJson and fromJson round-trip', () {
      final item = ReturnLineItem(
        productId: 'p1',
        productName: 'Widget',
        quantityReturned: 2.5,
        pricePerUnit: 40,
        batchId: 'b1',
        batchNumber: 'BATCH-01',
      );
      final json = item.toJson();
      final restored = ReturnLineItem.fromJson(json);
      expect(restored.productId, 'p1');
      expect(restored.productName, 'Widget');
      expect(restored.quantityReturned, 2.5);
      expect(restored.pricePerUnit, 40);
      expect(restored.refundAmount, 100);
      expect(restored.batchId, 'b1');
      expect(restored.batchNumber, 'BATCH-01');
    });

    test('fromJson handles missing fields gracefully', () {
      final item = ReturnLineItem.fromJson(const {});
      expect(item.productId, '');
      expect(item.productName, '');
      expect(item.quantityReturned, 0);
      expect(item.pricePerUnit, 0);
      expect(item.refundAmount, 0);
    });
  });

  group('SalesReturn', () {
    ReturnLineItem makeItem({double qty = 1, double price = 100}) {
      return ReturnLineItem(
        productId: 'p1',
        productName: 'Widget',
        quantityReturned: qty,
        pricePerUnit: price,
      );
    }

    test('auto-generates id and date', () {
      final sr = SalesReturn(
        originalBillId: 'bill-1',
        returnNumber: '2025-26/RET-001',
        items: [makeItem()],
        refundMode: RefundMode.cash,
      );
      expect(sr.id, isNotEmpty);
      expect(sr.date, isA<DateTime>());
    });

    test('computes totalRefundAmount from items', () {
      final sr = SalesReturn(
        originalBillId: 'bill-1',
        returnNumber: 'RET-001',
        items: [makeItem(qty: 2, price: 50), makeItem(qty: 3, price: 30)],
        refundMode: RefundMode.cash,
      );
      expect(sr.totalRefundAmount, 190); // 100 + 90
    });

    test('accepts explicit totalRefundAmount', () {
      final sr = SalesReturn(
        originalBillId: 'bill-1',
        returnNumber: 'RET-001',
        items: [makeItem(qty: 2, price: 50)],
        totalRefundAmount: 80,
        refundMode: RefundMode.cash,
      );
      expect(sr.totalRefundAmount, 80);
    });

    test('toJson and fromJson round-trip', () {
      final sr = SalesReturn(
        id: 'ret-id-1',
        originalBillId: 'bill-1',
        returnNumber: '2025-26/RET-001',
        items: [makeItem(qty: 2, price: 150)],
        refundMode: RefundMode.creditToAccount,
        customerId: 'c1',
        customerName: 'John',
        notes: 'Defective',
        createdBy: 'admin',
      );
      final json = sr.toJson();
      final restored = SalesReturn.fromJson(json);
      expect(restored.id, 'ret-id-1');
      expect(restored.originalBillId, 'bill-1');
      expect(restored.returnNumber, '2025-26/RET-001');
      expect(restored.items.length, 1);
      expect(restored.items.first.quantityReturned, 2);
      expect(restored.totalRefundAmount, 300);
      expect(restored.refundMode, RefundMode.creditToAccount);
      expect(restored.customerId, 'c1');
      expect(restored.customerName, 'John');
      expect(restored.notes, 'Defective');
      expect(restored.createdBy, 'admin');
    });

    test('fromJson handles unknown refundMode gracefully', () {
      final sr = SalesReturn.fromJson({
        'originalBillId': 'b1',
        'returnNumber': 'RET-001',
        'items': [],
        'refundMode': 'unknownMode',
      });
      expect(sr.refundMode, RefundMode.cash); // default fallback
    });

    test('RefundMode enum values', () {
      expect(RefundMode.values.length, 3);
      expect(RefundMode.cash.name, 'cash');
      expect(RefundMode.creditToAccount.name, 'creditToAccount');
      expect(RefundMode.exchange.name, 'exchange');
    });
  });

  group('ReturnProvider', () {
    late ReturnProvider provider;
    int changeCount = 0;

    ReturnLineItem makeReturnItem({
      String productId = 'p1',
      double qty = 1,
      double price = 100,
    }) {
      return ReturnLineItem(
        productId: productId,
        productName: 'Widget',
        quantityReturned: qty,
        pricePerUnit: price,
      );
    }

    SalesReturn makeReturn({
      String billId = 'bill-1',
      String? returnNumber,
      List<ReturnLineItem>? items,
      RefundMode refundMode = RefundMode.cash,
      DateTime? date,
    }) {
      return SalesReturn(
        originalBillId: billId,
        returnNumber: returnNumber ?? provider.generateReturnNumber(),
        items: items ?? [makeReturnItem()],
        refundMode: refundMode,
        date: date,
      );
    }

    setUp(() {
      changeCount = 0;
      provider = ReturnProvider(onChanged: () => changeCount++);
    });

    test('starts empty', () {
      expect(provider.returns, isEmpty);
    });

    test('addReturn adds and notifies', () {
      provider.addReturn(makeReturn());
      expect(provider.returns.length, 1);
      expect(changeCount, 1);
    });

    test('getReturnsByBill filters correctly', () {
      provider.addReturn(makeReturn(billId: 'bill-1'));
      provider.addReturn(makeReturn(billId: 'bill-2'));
      provider.addReturn(makeReturn(billId: 'bill-1'));
      expect(provider.getReturnsByBill('bill-1').length, 2);
      expect(provider.getReturnsByBill('bill-2').length, 1);
      expect(provider.getReturnsByBill('bill-3'), isEmpty);
    });

    test('hasReturnForBill returns correct boolean', () {
      provider.addReturn(makeReturn(billId: 'bill-1'));
      expect(provider.hasReturnForBill('bill-1'), true);
      expect(provider.hasReturnForBill('bill-2'), false);
    });

    test('getReturnedQuantity accumulates across returns', () {
      provider.addReturn(makeReturn(
        billId: 'bill-1',
        items: [makeReturnItem(productId: 'p1', qty: 3)],
      ));
      provider.addReturn(makeReturn(
        billId: 'bill-1',
        items: [makeReturnItem(productId: 'p1', qty: 2)],
      ));
      provider.addReturn(makeReturn(
        billId: 'bill-2',
        items: [makeReturnItem(productId: 'p1', qty: 5)],
      ));
      expect(provider.getReturnedQuantity('bill-1', 'p1'), 5);
      expect(provider.getReturnedQuantity('bill-2', 'p1'), 5);
      expect(provider.getReturnedQuantity('bill-1', 'p2'), 0);
    });

    test('generateReturnNumber increments', () {
      final n1 = provider.generateReturnNumber();
      final n2 = provider.generateReturnNumber();
      expect(n1, contains('RET-001'));
      expect(n2, contains('RET-002'));
    });

    test('generateReturnNumber uses financial year prefix', () {
      final n = provider.generateReturnNumber();
      final now = DateTime.now();
      final startYear = now.month >= 4 ? now.year : now.year - 1;
      final endYear = (startYear + 1) % 100;
      final fy = '$startYear-${endYear.toString().padLeft(2, '0')}';
      expect(n, startsWith('$fy/'));
    });

    test('getReturnsByDateRange filters by date', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final twoDaysAgo = today.subtract(const Duration(days: 2));

      provider.addReturn(makeReturn(date: today));
      provider.addReturn(makeReturn(date: yesterday));
      provider.addReturn(makeReturn(date: twoDaysAgo));

      final result = provider.getReturnsByDateRange(yesterday, today);
      expect(result.length, 2);
    });

    test('getTodayReturns returns only today', () {
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      provider.addReturn(makeReturn(date: today));
      provider.addReturn(makeReturn(date: yesterday));

      expect(provider.getTodayReturns().length, 1);
    });

    test('todayRefundTotal sums today refunds', () {
      final today = DateTime.now();
      provider.addReturn(makeReturn(
        date: today,
        items: [makeReturnItem(qty: 2, price: 100)],
      ));
      provider.addReturn(makeReturn(
        date: today,
        items: [makeReturnItem(qty: 1, price: 50)],
      ));
      expect(provider.todayRefundTotal, 250);
    });

    test('clearAllData resets everything', () {
      provider.addReturn(makeReturn());
      provider.addReturn(makeReturn());
      provider.clearAllData();
      expect(provider.returns, isEmpty);
    });

    test('replaceAllData replaces and hydrates counter', () {
      final now = DateTime.now();
      final fy = now.month >= 4 ? now.year : now.year - 1;
      final endYear = (fy + 1) % 100;
      final fyStr = '$fy-${endYear.toString().padLeft(2, '0')}';

      final existingReturns = [
        SalesReturn(
          originalBillId: 'b1',
          returnNumber: '$fyStr/RET-005',
          items: [makeReturnItem()],
          refundMode: RefundMode.cash,
        ),
        SalesReturn(
          originalBillId: 'b2',
          returnNumber: '$fyStr/RET-003',
          items: [makeReturnItem()],
          refundMode: RefundMode.cash,
        ),
      ];

      provider.replaceAllData(existingReturns);
      expect(provider.returns.length, 2);

      // Next generated number should be RET-006
      final next = provider.generateReturnNumber();
      expect(next, '$fyStr/RET-006');
    });

    test('initialReturns hydrates counter correctly', () {
      final now = DateTime.now();
      final fy = now.month >= 4 ? now.year : now.year - 1;
      final endYear = (fy + 1) % 100;
      final fyStr = '$fy-${endYear.toString().padLeft(2, '0')}';

      final p = ReturnProvider(
        initialReturns: [
          SalesReturn(
            originalBillId: 'b1',
            returnNumber: '$fyStr/RET-010',
            items: [makeReturnItem()],
            refundMode: RefundMode.cash,
          ),
        ],
      );
      final next = p.generateReturnNumber();
      expect(next, '$fyStr/RET-011');
    });
  });
}
