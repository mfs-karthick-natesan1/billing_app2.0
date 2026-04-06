import 'package:flutter/foundation.dart';
import '../models/bill.dart';
import '../models/return_line_item.dart';
import '../models/sales_return.dart';
import '../services/db_service.dart';

class ReturnProvider extends ChangeNotifier {
  final List<SalesReturn> _returns = [];
  final VoidCallback? _onChanged;
  int _counter = 0;
  String? _currentFy;

  DbService? dbService;

  ReturnProvider({
    List<SalesReturn>? initialReturns,
    VoidCallback? onChanged,
  }) : _onChanged = onChanged {
    if (initialReturns != null) {
      _returns.addAll(initialReturns);
      _hydrateCounter();
    }
  }

  List<SalesReturn> get returns => List.unmodifiable(_returns);

  String get _financialYear {
    final now = DateTime.now();
    final startYear = now.month >= 4 ? now.year : now.year - 1;
    final endYear = (startYear + 1) % 100;
    return '$startYear-${endYear.toString().padLeft(2, '0')}';
  }

  String generateReturnNumber() {
    final fy = _financialYear;
    if (_currentFy != fy) {
      _currentFy = fy;
      _counter = 0;
    }
    _counter++;
    final number = _counter.toString().padLeft(3, '0');
    return '$fy/RET-$number';
  }

  /// Adds a return after validating that returned quantities don't exceed the
  /// original bill quantities (accounting for previous returns).
  ///
  /// Pass [originalBill] so the provider can cross-check line-item quantities.
  /// Throws [StateError] if any item exceeds the returnable quantity.
  void addReturn(SalesReturn salesReturn, {Bill? originalBill}) {
    if (originalBill != null) {
      final enrichedItems = <ReturnLineItem>[];
      for (final item in salesReturn.items) {
        // Find matching line item in original bill
        final billItem = originalBill.lineItems.firstWhere(
          (li) => li.product.id == item.productId,
          orElse: () => throw StateError(
            'Product "${item.productName}" not found in original bill '
            '${originalBill.billNumber}.',
          ),
        );
        final alreadyReturned = getReturnedQuantity(
          originalBill.id,
          item.productId,
        );
        final maxReturnable = billItem.quantity - alreadyReturned;
        if (item.quantityReturned > maxReturnable) {
          throw StateError(
            'Return quantity (${item.quantityReturned}) for '
            '"${item.productName}" exceeds returnable quantity '
            '($maxReturnable).',
          );
        }

        // Per CGST Act §34, credit notes must reverse the EXACT tax from
        // the original invoice. Pro-rate tax and refund by returned qty so
        // discount + GST applied at sale time are mirrored on the refund.
        final qtyRatio = billItem.quantity == 0
            ? 0.0
            : item.quantityReturned / billItem.quantity;
        final hasTax = item.cgstAmount != 0 ||
            item.sgstAmount != 0 ||
            item.igstAmount != 0;
        enrichedItems.add(ReturnLineItem(
          productId: item.productId,
          productName: item.productName,
          quantityReturned: item.quantityReturned,
          pricePerUnit: item.pricePerUnit,
          refundAmount: billItem.totalWithGst * qtyRatio,
          batchId: item.batchId,
          batchNumber: item.batchNumber,
          cgstAmount: hasTax ? item.cgstAmount : billItem.cgstAmount * qtyRatio,
          sgstAmount: hasTax ? item.sgstAmount : billItem.sgstAmount * qtyRatio,
          igstAmount: hasTax ? item.igstAmount : billItem.igstAmount * qtyRatio,
        ));
      }
      salesReturn = SalesReturn(
        id: salesReturn.id,
        originalBillId: salesReturn.originalBillId,
        returnNumber: salesReturn.returnNumber,
        date: salesReturn.date,
        customerId: salesReturn.customerId,
        customerName: salesReturn.customerName,
        items: enrichedItems,
        refundMode: salesReturn.refundMode,
        notes: salesReturn.notes,
        createdBy: salesReturn.createdBy,
      );
    }

    _returns.add(salesReturn);
    dbService?.saveSalesReturns([salesReturn]);
    _onChanged?.call();
    notifyListeners();
  }

  List<SalesReturn> getReturnsByBill(String billId) {
    return _returns.where((r) => r.originalBillId == billId).toList();
  }

  bool hasReturnForBill(String billId) {
    return _returns.any((r) => r.originalBillId == billId);
  }

  List<SalesReturn> getReturnsByDateRange(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return _returns
        .where((r) => !r.date.isBefore(start) && !r.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<SalesReturn> getTodayReturns() {
    final now = DateTime.now();
    return getReturnsByDateRange(now, now);
  }

  double get todayRefundTotal =>
      getTodayReturns().fold(0.0, (sum, r) => sum + r.totalRefundAmount);

  /// Total quantity already returned for a specific product in a specific bill.
  double getReturnedQuantity(String billId, String productId) {
    return _returns
        .where((r) => r.originalBillId == billId)
        .expand((r) => r.items)
        .where((item) => item.productId == productId)
        .fold(0.0, (sum, item) => sum + item.quantityReturned);
  }

  void clearAllData() {
    _returns.clear();
    _counter = 0;
    _currentFy = null;
    _onChanged?.call();
    notifyListeners();
  }

  void replaceAllData(List<SalesReturn> returns) {
    _returns
      ..clear()
      ..addAll(returns);
    _hydrateCounter();
    _onChanged?.call();
    notifyListeners();
  }

  void _hydrateCounter() {
    final fy = _financialYear;
    _currentFy = fy;
    var maxCounter = 0;
    for (final r in _returns) {
      if (!r.returnNumber.startsWith('$fy/')) continue;
      final parts = r.returnNumber.split('-');
      if (parts.isEmpty) continue;
      final number = int.tryParse(parts.last) ?? 0;
      if (number > maxCounter) maxCounter = number;
    }
    _counter = maxCounter;
  }
}
