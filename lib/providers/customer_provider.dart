import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/customer_payment_entry.dart';
import '../services/db_service.dart';

class CustomerProvider extends ChangeNotifier {
  final List<Customer> _customers = [];
  final List<CustomerPaymentEntry> _paymentEntries = [];
  final VoidCallback? _onChanged;

  DbService? dbService;

  CustomerProvider({
    List<Customer>? initialCustomers,
    List<CustomerPaymentEntry>? initialPaymentEntries,
    VoidCallback? onChanged,
  }) : _onChanged = onChanged {
    if (initialCustomers != null) {
      _customers.addAll(initialCustomers);
    }
    if (initialPaymentEntries != null) {
      _paymentEntries.addAll(initialPaymentEntries);
    }
  }

  List<Customer> get customers => List.unmodifiable(_customers);
  List<CustomerPaymentEntry> get paymentEntries =>
      List.unmodifiable(_paymentEntries);

  double get totalOutstanding =>
      _customers.fold(0.0, (sum, c) => sum + c.outstandingBalance);

  Customer addCustomer({
    required String name,
    String? phone,
    int? age,
    String? gender,
    String? bloodGroup,
    String? allergies,
    String? medicalNotes,
    double defaultDiscountPercent = 0,
  }) {
    // Check if customer with same name exists
    final existing = _customers.where(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      return existing.first;
    }

    final customer = Customer(
      name: name,
      phone: phone,
      age: age,
      gender: gender,
      bloodGroup: bloodGroup,
      allergies: allergies,
      medicalNotes: medicalNotes,
      defaultDiscountPercent: defaultDiscountPercent,
    );
    _customers.add(customer);
    dbService?.saveCustomers([customer]);
    _onChanged?.call();
    notifyListeners();
    return customer;
  }

  void addCredit(String customerId, double amount) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        outstandingBalance: _customers[index].outstandingBalance + amount,
        lastCreditDate: DateTime.now(),
      );
      dbService?.saveCustomers([_customers[index]]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  void addAdvance(String customerId, double amount) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1 && amount > 0) {
      _customers[index] = _customers[index].copyWith(
        advanceBalance: _customers[index].advanceBalance + amount,
      );
      dbService?.saveCustomers([_customers[index]]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  void deductAdvance(String customerId, double amount) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1 && amount > 0) {
      _customers[index] = _customers[index].copyWith(
        advanceBalance: (_customers[index].advanceBalance - amount)
            .clamp(0, double.infinity),
      );
      dbService?.saveCustomers([_customers[index]]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  void recordPayment(
    String customerId,
    double amount, {
    SettlementPaymentMode paymentMode = SettlementPaymentMode.cash,
    DateTime? recordedAt,
    String? recordedBy,
    String? notes,
    String? billReference,
  }) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      final newBalance =
          (_customers[index].outstandingBalance - amount).clamp(0.0, double.infinity);
      _customers[index] = _customers[index].copyWith(
        outstandingBalance: newBalance,
      );
      final entry = CustomerPaymentEntry(
        customerId: customerId,
        amount: amount,
        paymentMode: paymentMode,
        recordedAt: recordedAt,
        recordedBy: recordedBy,
        notes: notes,
        billReference: billReference,
      );
      _paymentEntries.add(entry);
      dbService?.saveCustomerPaymentEntries([entry]);
      dbService?.saveCustomers([_customers[index]]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  /// Payment history for a customer, sorted by date descending.
  List<CustomerPaymentEntry> getPaymentHistory(String customerId) {
    return _paymentEntries
        .where((e) => e.customerId == customerId)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  /// Total payments made by a customer.
  double getTotalPayments(String customerId) {
    return _paymentEntries
        .where((e) => e.customerId == customerId)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  List<CustomerPaymentEntry> getPaymentEntriesByDateRange(
    DateTime from,
    DateTime to, {
    SettlementPaymentMode? paymentMode,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);

    final filtered = _paymentEntries.where((entry) {
      final inRange =
          !entry.recordedAt.isBefore(start) && !entry.recordedAt.isAfter(end);
      if (!inRange) return false;
      if (paymentMode != null && entry.paymentMode != paymentMode) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    return filtered;
  }

  double getCashReceivedInDateRange(DateTime from, DateTime to) {
    return getPaymentEntriesByDateRange(
      from,
      to,
      paymentMode: SettlementPaymentMode.cash,
    ).fold(0, (sum, entry) => sum + entry.amount);
  }

  List<Customer> searchCustomers(String query) {
    if (query.length < 2) return _customers;
    final lower = query.toLowerCase();
    return _customers
        .where(
          (c) =>
              c.name.toLowerCase().contains(lower) ||
              (c.phone != null && c.phone!.contains(query)),
        )
        .toList();
  }

  bool updateCustomer(
    String id, {
    String? name,
    String? phone,
    String? gstin,
    int? age,
    String? gender,
    String? bloodGroup,
    String? allergies,
    String? medicalNotes,
    double? defaultDiscountPercent,
  }) {
    final index = _customers.indexWhere((c) => c.id == id);
    if (index == -1) return false;

    if (name != null) {
      final duplicate = _customers.any(
        (c) => c.id != id && c.name.toLowerCase() == name.toLowerCase(),
      );
      if (duplicate) return false;
    }

    _customers[index] = _customers[index].copyWith(
      name: name,
      phone: phone,
      gstin: gstin,
      age: age,
      gender: gender,
      bloodGroup: bloodGroup,
      allergies: allergies,
      medicalNotes: medicalNotes,
      defaultDiscountPercent: defaultDiscountPercent,
    );
    dbService?.saveCustomers([_customers[index]]);
    _onChanged?.call();
    notifyListeners();
    return true;
  }

  /// Adds or updates a vehicle on a customer (matched by reg number).
  /// Also updates the customer's name/phone if the vehicle's km changed.
  void upsertVehicle(String customerId, CustomerVehicle vehicle) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;
    final customer = _customers[index];
    final vehicles = List<CustomerVehicle>.from(customer.vehicles);
    final vIndex = vehicles.indexWhere(
      (v) => v.reg.toLowerCase() == vehicle.reg.toLowerCase(),
    );
    if (vIndex == -1) {
      vehicles.add(vehicle);
    } else {
      vehicles[vIndex] = vehicles[vIndex].copyWith(
        make: vehicle.make ?? vehicles[vIndex].make,
        model: vehicle.model ?? vehicles[vIndex].model,
        lastKmReading: vehicle.lastKmReading ?? vehicles[vIndex].lastKmReading,
      );
    }
    _customers[index] = customer.copyWith(vehicles: vehicles);
    dbService?.saveCustomers([_customers[index]]);
    _onChanged?.call();
    notifyListeners();
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    dbService?.deleteRecord('customers', id);
    _onChanged?.call();
    notifyListeners();
  }

  Customer? findById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearAllData() {
    _customers.clear();
    _paymentEntries.clear();
    _onChanged?.call();
    notifyListeners();
  }

  void replaceAllData({
    required List<Customer> customers,
    List<CustomerPaymentEntry> paymentEntries = const [],
  }) {
    _customers
      ..clear()
      ..addAll(customers);
    _paymentEntries
      ..clear()
      ..addAll(paymentEntries);
    _onChanged?.call();
    notifyListeners();
  }

  Future<String?> syncFromDb() async {
    if (dbService == null) return null;
    try {
      final customers = await dbService!.loadCustomers();
      _customers
        ..clear()
        ..addAll(customers);
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
