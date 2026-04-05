import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../services/db_service.dart';

class SupplierProvider extends ChangeNotifier {
  final List<Supplier> _suppliers = [];
  final VoidCallback? _onChanged;

  DbService? dbService;

  SupplierProvider({
    List<Supplier>? initialSuppliers,
    VoidCallback? onChanged,
  }) : _onChanged = onChanged {
    if (initialSuppliers != null) {
      _suppliers.addAll(initialSuppliers);
    }
  }

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);

  List<Supplier> getActiveSuppliers() {
    return _suppliers.where((s) => s.isActive).toList();
  }

  double getTotalPayable() {
    return _suppliers
        .where((s) => s.isActive)
        .fold(0.0, (sum, s) => sum + s.outstandingPayable);
  }

  Supplier? getSupplierById(String id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Supplier addSupplier({
    required String name,
    String? phone,
    String? gstin,
    String? address,
    List<String> productCategories = const [],
    String? notes,
  }) {
    final supplier = Supplier(
      name: name,
      phone: phone,
      gstin: gstin,
      address: address,
      productCategories: productCategories,
      notes: notes,
    );
    _suppliers.add(supplier);
    dbService?.saveSuppliers([supplier]);
    _onChanged?.call();
    notifyListeners();
    return supplier;
  }

  bool updateSupplier(
    String id, {
    String? name,
    String? phone,
    String? gstin,
    String? address,
    List<String>? productCategories,
    String? notes,
  }) {
    final index = _suppliers.indexWhere((s) => s.id == id);
    if (index == -1) return false;

    _suppliers[index] = _suppliers[index].copyWith(
      name: name,
      phone: phone,
      gstin: gstin,
      address: address,
      productCategories: productCategories,
      notes: notes,
    );
    dbService?.saveSuppliers([_suppliers[index]]);
    _onChanged?.call();
    notifyListeners();
    return true;
  }

  void deleteSupplier(String id) {
    final index = _suppliers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _suppliers[index] = _suppliers[index].copyWith(isActive: false);
    dbService?.saveSuppliers([_suppliers[index]]);
    _onChanged?.call();
    notifyListeners();
  }

  void reactivateSupplier(String id) {
    final index = _suppliers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _suppliers[index] = _suppliers[index].copyWith(isActive: true);
    dbService?.saveSuppliers([_suppliers[index]]);
    _onChanged?.call();
    notifyListeners();
  }

  void addPayable(String supplierId, double amount) {
    final index = _suppliers.indexWhere((s) => s.id == supplierId);
    if (index != -1) {
      _suppliers[index] = _suppliers[index].copyWith(
        outstandingPayable: _suppliers[index].outstandingPayable + amount,
      );
      dbService?.saveSuppliers([_suppliers[index]]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  void recordPayment(String supplierId, double amount) {
    final index = _suppliers.indexWhere((s) => s.id == supplierId);
    if (index != -1) {
      final newPayable =
          (_suppliers[index].outstandingPayable - amount).clamp(0.0, double.infinity);
      _suppliers[index] = _suppliers[index].copyWith(
        outstandingPayable: newPayable,
      );
      dbService?.saveSuppliers([_suppliers[index]]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  List<Supplier> searchSuppliers(String query) {
    if (query.length < 2) return getActiveSuppliers();
    final lower = query.toLowerCase();
    return _suppliers
        .where(
          (s) =>
              s.isActive &&
              (s.name.toLowerCase().contains(lower) ||
                  s.productCategories.any(
                    (c) => c.toLowerCase().contains(lower),
                  ) ||
                  (s.phone != null && s.phone!.contains(query))),
        )
        .toList();
  }

  void clearAllData() {
    _suppliers.clear();
    _onChanged?.call();
    notifyListeners();
  }

  void replaceAllData({required List<Supplier> suppliers}) {
    _suppliers
      ..clear()
      ..addAll(suppliers);
    _onChanged?.call();
    notifyListeners();
  }

  Future<String?> syncFromDb() async {
    if (dbService == null) return null;
    try {
      final suppliers = await dbService!.loadSuppliers();
      _suppliers
        ..clear()
        ..addAll(suppliers);
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
