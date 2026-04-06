import 'package:flutter/foundation.dart';
import '../models/payment_info.dart';
import '../models/purchase_entry.dart';
import '../models/purchase_line_item.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../services/db_service.dart';

class PurchaseProvider extends ChangeNotifier {
  final List<PurchaseEntry> _purchases = [];
  final VoidCallback? _onChanged;

  DbService? dbService;

  PurchaseProvider({
    List<PurchaseEntry>? initialPurchases,
    VoidCallback? onChanged,
  }) : _onChanged = onChanged {
    if (initialPurchases != null) {
      _purchases.addAll(initialPurchases);
    }
  }

  List<PurchaseEntry> get purchases => List.unmodifiable(_purchases);

  void addPurchase(
    PurchaseEntry entry, {
    required ProductProvider productProvider,
    SupplierProvider? supplierProvider,
  }) {
    _purchases.add(entry);

    // Increment stock for each item
    for (final item in entry.items) {
      productProvider.incrementStock(item.productId, item.quantity);
    }

    // Credit purchase → increment supplier payable
    if (entry.paymentMode == PaymentMode.credit &&
        entry.supplierId != null &&
        supplierProvider != null) {
      supplierProvider.addPayable(entry.supplierId!, entry.totalAmount);
    }

    _onChanged?.call();
    notifyListeners();
  }

  void deletePurchase(
    String id, {
    required ProductProvider productProvider,
    SupplierProvider? supplierProvider,
  }) {
    final index = _purchases.indexWhere((p) => p.id == id);
    if (index == -1) return;

    final entry = _purchases[index];

    // Reverse stock increments
    for (final item in entry.items) {
      productProvider.decrementStock(item.productId, item.quantity);
    }

    // Reverse supplier payable if credit
    if (entry.paymentMode == PaymentMode.credit &&
        entry.supplierId != null &&
        supplierProvider != null) {
      supplierProvider.recordPayment(entry.supplierId!, entry.totalAmount);
    }

    _purchases.removeAt(index);
    dbService?.deleteRecord('purchases', id);
    _onChanged?.call();
    notifyListeners();
  }

  void updatePurchase(
    String id,
    PurchaseEntry newEntry, {
    required ProductProvider productProvider,
    SupplierProvider? supplierProvider,
  }) {
    deletePurchase(
      id,
      productProvider: productProvider,
      supplierProvider: supplierProvider,
    );
    addPurchase(
      newEntry,
      productProvider: productProvider,
      supplierProvider: supplierProvider,
    );
  }

  List<PurchaseEntry> getPurchasesByDateRange(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    return _purchases
        .where((p) => !p.date.isBefore(start) && !p.date.isAfter(end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<PurchaseEntry> getPurchasesBySupplier(String supplierId) {
    return _purchases
        .where((p) => p.supplierId == supplierId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<PurchaseLineItem> getProductPurchaseHistory(String productId) {
    final items = <_PurchaseLineWithDate>[];
    for (final purchase in _purchases) {
      for (final item in purchase.items) {
        if (item.productId == productId) {
          items.add(_PurchaseLineWithDate(item, purchase.date));
        }
      }
    }
    items.sort((a, b) => b.date.compareTo(a.date));
    return items.map((e) => e.item).toList();
  }

  double getAverageCostPrice(String productId) {
    double totalCost = 0;
    double totalQty = 0;
    for (final purchase in _purchases) {
      for (final item in purchase.items) {
        if (item.productId == productId) {
          totalCost += item.totalCost;
          totalQty += item.quantity;
        }
      }
    }
    if (totalQty == 0) return 0;
    return totalCost / totalQty;
  }

  double? getLastPurchasePrice(String productId) {
    for (final purchase in _purchases.reversed) {
      for (final item in purchase.items) {
        if (item.productId == productId) {
          return item.purchasePricePerUnit;
        }
      }
    }
    return null;
  }

  List<PurchaseEntry> getTodayPurchases() {
    final now = DateTime.now();
    return getPurchasesByDateRange(now, now);
  }

  List<PurchaseEntry> getThisMonthPurchases() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    return getPurchasesByDateRange(start, now);
  }

  double getTotalPurchaseValue(DateTime from, DateTime to) {
    return getPurchasesByDateRange(from, to)
        .fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  double get todayPurchaseTotal {
    return getTodayPurchases().fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  void clearAllData() {
    _purchases.clear();
    _onChanged?.call();
    notifyListeners();
  }

  void replaceAllData({required List<PurchaseEntry> purchases}) {
    _purchases
      ..clear()
      ..addAll(purchases);
    _onChanged?.call();
    notifyListeners();
  }

  Future<String?> syncFromDb() async {
    if (dbService == null) return null;
    try {
      final purchases = await dbService!.loadPurchases();
      _purchases
        ..clear()
        ..addAll(purchases);
      notifyListeners();
      return null;
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('AuthException') || msg.contains('JWT')) {
        return 'Sync failed: session expired. Please log in again.';
      }
      return 'Sync failed: please check your internet connection.';
    }
  }
}

class _PurchaseLineWithDate {
  final PurchaseLineItem item;
  final DateTime date;
  _PurchaseLineWithDate(this.item, this.date);
}
