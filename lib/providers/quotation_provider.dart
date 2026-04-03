import 'package:flutter/foundation.dart';

import '../models/bill.dart';
import '../models/payment_info.dart';
import '../models/quotation.dart';
import '../services/bill_number_service.dart';
import '../services/db_service.dart';

class QuotationProvider extends ChangeNotifier {
  final List<Quotation> _quotations = [];
  final VoidCallback? _onChanged;
  final BillNumberService _numberService = BillNumberService();

  DbService? dbService;

  QuotationProvider({
    List<Quotation>? initialQuotations,
    VoidCallback? onChanged,
  }) : _onChanged = onChanged {
    if (initialQuotations != null) {
      _quotations.addAll(initialQuotations);
    }
    _numberService.hydrateFromExistingBills(
      _quotations.map((q) => q.quotationNumber).toList(),
    );
  }

  List<Quotation> get quotations => List.unmodifiable(_quotations);

  String generateQuotationNumber() {
    return _numberService.generateBillNumber(prefix: 'QUO');
  }

  void addQuotation(Quotation quotation) {
    _quotations.add(quotation);
    dbService?.saveQuotations([quotation]);
    _persistAndNotify();
  }

  void updateQuotation(Quotation updated) {
    final index = _quotations.indexWhere((q) => q.id == updated.id);
    if (index == -1) return;
    _quotations[index] = updated;
    dbService?.saveQuotations([updated]);
    _persistAndNotify();
  }

  void deleteQuotation(String id) {
    _quotations.removeWhere((q) => q.id == id);
    dbService?.deleteRecord('quotations', id);
    _persistAndNotify();
  }

  void updateStatus(String id, QuotationStatus status) {
    final index = _quotations.indexWhere((q) => q.id == id);
    if (index == -1) return;
    _quotations[index] = _quotations[index].copyWith(status: status);
    dbService?.saveQuotations([_quotations[index]]);
    _persistAndNotify();
  }

  /// Converts an approved quotation into a Bill.
  /// Returns the created Bill, or null if quotation is not found / not approved.
  Bill? convertToBill(String quotationId) {
    final index = _quotations.indexWhere((q) => q.id == quotationId);
    if (index == -1) return null;
    final quotation = _quotations[index];
    if (!quotation.canConvert) return null;

    final bill = Bill(
      billNumber: '', // Caller should set the real bill number
      lineItems: quotation.items,
      subtotal: quotation.subtotal,
      discount: quotation.discount,
      cgst: quotation.cgst,
      sgst: quotation.sgst,
      igst: quotation.igst,
      grandTotal: quotation.grandTotal,
      isInterState: quotation.isInterState,
      paymentMode: PaymentMode.cash,
      customer: quotation.customer,
    );

    _quotations[index] = quotation.copyWith(
      status: QuotationStatus.converted,
      convertedToBillId: bill.id,
    );
    dbService?.saveQuotations([_quotations[index]]);
    _persistAndNotify();
    return bill;
  }

  List<Quotation> getActiveQuotations() {
    return _sortedByDate(
      _quotations.where(
        (q) =>
            q.status == QuotationStatus.draft ||
            q.status == QuotationStatus.sent ||
            q.status == QuotationStatus.approved,
      ),
    );
  }

  List<Quotation> getExpiredQuotations() {
    return _sortedByDate(
      _quotations.where((q) => q.status == QuotationStatus.expired),
    );
  }

  List<Quotation> getByStatus(QuotationStatus status) {
    return _sortedByDate(
      _quotations.where((q) => q.status == status),
    );
  }

  /// Auto-expire quotations that have passed their validUntil date.
  /// Called on app open.
  int expireOverdueQuotations() {
    final now = DateTime.now();
    var count = 0;
    for (var i = 0; i < _quotations.length; i++) {
      final q = _quotations[i];
      if (q.status == QuotationStatus.draft ||
          q.status == QuotationStatus.sent) {
        if (now.isAfter(q.validUntil)) {
          _quotations[i] = q.copyWith(status: QuotationStatus.expired);
          count++;
        }
      }
    }
    if (count > 0) _persistAndNotify();
    return count;
  }

  void clearAllData() {
    _quotations.clear();
    _persistAndNotify();
  }

  List<Quotation> _sortedByDate(Iterable<Quotation> source) {
    final result = source.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  void _persistAndNotify() {
    _onChanged?.call();
    notifyListeners();
  }
}
