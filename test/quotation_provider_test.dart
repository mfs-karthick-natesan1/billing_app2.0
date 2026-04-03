import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/quotation.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/providers/quotation_provider.dart';

Quotation _makeQuotation({
  String? quotationNumber,
  QuotationStatus status = QuotationStatus.draft,
  DateTime? validUntil,
  String? customerName,
  double grandTotal = 100,
}) {
  return Quotation(
    quotationNumber: quotationNumber ?? 'QUO-001',
    status: status,
    validUntil: validUntil,
    customerName: customerName,
    grandTotal: grandTotal,
    subtotal: grandTotal,
    items: [
      LineItem(
        product: Product(name: 'Test Item', sellingPrice: grandTotal),
      ),
    ],
  );
}

void main() {
  group('QuotationProvider', () {
    late QuotationProvider provider;

    setUp(() {
      provider = QuotationProvider();
    });

    test('starts with empty quotation list', () {
      expect(provider.quotations, isEmpty);
      expect(provider.getActiveQuotations(), isEmpty);
      expect(provider.getExpiredQuotations(), isEmpty);
    });

    test('addQuotation adds a quotation', () {
      final quotation = _makeQuotation();
      provider.addQuotation(quotation);

      expect(provider.quotations.length, 1);
      expect(provider.quotations.first.quotationNumber, 'QUO-001');
    });

    test('updateQuotation modifies quotation', () {
      final quotation = _makeQuotation(customerName: 'Old Name');
      provider.addQuotation(quotation);

      final updated = quotation.copyWith(customerName: 'New Name');
      provider.updateQuotation(updated);

      expect(provider.quotations.first.customerName, 'New Name');
    });

    test('deleteQuotation removes quotation', () {
      final quotation = _makeQuotation();
      provider.addQuotation(quotation);
      expect(provider.quotations.length, 1);

      provider.deleteQuotation(quotation.id);
      expect(provider.quotations, isEmpty);
    });

    test('updateStatus changes quotation status', () {
      final quotation = _makeQuotation();
      provider.addQuotation(quotation);

      provider.updateStatus(quotation.id, QuotationStatus.sent);
      expect(provider.quotations.first.status, QuotationStatus.sent);

      provider.updateStatus(quotation.id, QuotationStatus.approved);
      expect(provider.quotations.first.status, QuotationStatus.approved);
    });

    test('getActiveQuotations returns draft, sent, approved', () {
      provider.addQuotation(
        _makeQuotation(quotationNumber: 'Q1', status: QuotationStatus.draft),
      );
      provider.addQuotation(
        _makeQuotation(quotationNumber: 'Q2', status: QuotationStatus.sent),
      );
      provider.addQuotation(
        _makeQuotation(
          quotationNumber: 'Q3',
          status: QuotationStatus.approved,
        ),
      );
      provider.addQuotation(
        _makeQuotation(
          quotationNumber: 'Q4',
          status: QuotationStatus.rejected,
        ),
      );
      provider.addQuotation(
        _makeQuotation(
          quotationNumber: 'Q5',
          status: QuotationStatus.expired,
        ),
      );

      final active = provider.getActiveQuotations();
      expect(active.length, 3);
    });

    test('getExpiredQuotations returns only expired', () {
      provider.addQuotation(
        _makeQuotation(quotationNumber: 'Q1', status: QuotationStatus.draft),
      );
      provider.addQuotation(
        _makeQuotation(
          quotationNumber: 'Q2',
          status: QuotationStatus.expired,
        ),
      );

      final expired = provider.getExpiredQuotations();
      expect(expired.length, 1);
      expect(expired.first.quotationNumber, 'Q2');
    });

    test('getByStatus filters correctly', () {
      provider.addQuotation(
        _makeQuotation(quotationNumber: 'Q1', status: QuotationStatus.sent),
      );
      provider.addQuotation(
        _makeQuotation(quotationNumber: 'Q2', status: QuotationStatus.sent),
      );
      provider.addQuotation(
        _makeQuotation(quotationNumber: 'Q3', status: QuotationStatus.draft),
      );

      expect(provider.getByStatus(QuotationStatus.sent).length, 2);
      expect(provider.getByStatus(QuotationStatus.draft).length, 1);
    });

    test('convertToBill returns null if not approved', () {
      final quotation = _makeQuotation(status: QuotationStatus.draft);
      provider.addQuotation(quotation);

      final bill = provider.convertToBill(quotation.id);
      expect(bill, isNull);
    });

    test('convertToBill works for approved quotation', () {
      final quotation = _makeQuotation(
        status: QuotationStatus.approved,
        grandTotal: 500,
      );
      provider.addQuotation(quotation);

      final bill = provider.convertToBill(quotation.id);
      expect(bill, isNotNull);
      expect(bill!.grandTotal, 500);

      // Quotation should be marked as converted
      expect(
        provider.quotations.first.status,
        QuotationStatus.converted,
      );
      expect(
        provider.quotations.first.convertedToBillId,
        bill.id,
      );
    });

    test('expireOverdueQuotations marks overdue as expired', () {
      // Add a quotation that expired yesterday
      final expiredQuotation = _makeQuotation(
        quotationNumber: 'Q-EXPIRED',
        status: QuotationStatus.draft,
        validUntil: DateTime.now().subtract(const Duration(days: 1)),
      );
      provider.addQuotation(expiredQuotation);

      // Add a quotation valid for 7 days
      final validQuotation = _makeQuotation(
        quotationNumber: 'Q-VALID',
        status: QuotationStatus.sent,
        validUntil: DateTime.now().add(const Duration(days: 7)),
      );
      provider.addQuotation(validQuotation);

      final count = provider.expireOverdueQuotations();
      expect(count, 1);

      final expired = provider.quotations
          .firstWhere((q) => q.quotationNumber == 'Q-EXPIRED');
      expect(expired.status, QuotationStatus.expired);

      final valid = provider.quotations
          .firstWhere((q) => q.quotationNumber == 'Q-VALID');
      expect(valid.status, QuotationStatus.sent);
    });

    test('expireOverdueQuotations skips approved and rejected', () {
      provider.addQuotation(_makeQuotation(
        quotationNumber: 'Q-APPROVED',
        status: QuotationStatus.approved,
        validUntil: DateTime.now().subtract(const Duration(days: 1)),
      ));
      provider.addQuotation(_makeQuotation(
        quotationNumber: 'Q-REJECTED',
        status: QuotationStatus.rejected,
        validUntil: DateTime.now().subtract(const Duration(days: 1)),
      ));

      final count = provider.expireOverdueQuotations();
      expect(count, 0);
    });

    test('generateQuotationNumber returns unique numbers', () {
      final n1 = provider.generateQuotationNumber();
      expect(n1, contains('QUO'));

      // Add a quotation so the next number is different
      provider.addQuotation(_makeQuotation(quotationNumber: n1));
      final n2 = provider.generateQuotationNumber();
      expect(n2, isNot(equals(n1)));
    });

    test('onChanged callback fires on mutations', () {
      var callCount = 0;
      provider = QuotationProvider(onChanged: () => callCount++);

      provider.addQuotation(_makeQuotation());
      expect(callCount, 1);

      provider.updateStatus(
        provider.quotations.first.id,
        QuotationStatus.sent,
      );
      expect(callCount, 2);

      provider.deleteQuotation(provider.quotations.first.id);
      expect(callCount, 3);
    });

    test('initialQuotations hydrates provider', () {
      final q = _makeQuotation(quotationNumber: 'INIT-001');
      provider = QuotationProvider(initialQuotations: [q]);

      expect(provider.quotations.length, 1);
      expect(provider.quotations.first.quotationNumber, 'INIT-001');
    });

    test('clearAllData empties the list', () {
      provider.addQuotation(_makeQuotation());
      provider.addQuotation(_makeQuotation(quotationNumber: 'Q2'));
      expect(provider.quotations.length, 2);

      provider.clearAllData();
      expect(provider.quotations, isEmpty);
    });
  });
}
