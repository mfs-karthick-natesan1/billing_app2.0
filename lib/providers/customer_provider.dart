import 'package:flutter/foundation.dart';
import '../domain/repositories/customer_repository.dart';
import '../models/customer.dart';
import '../models/customer_payment_entry.dart';
import '../services/db_service.dart';

class CustomerProvider extends ChangeNotifier {
  final List<Customer> _customers = [];
  final List<CustomerPaymentEntry> _paymentEntries = [];
  final VoidCallback? _onChanged;

  DbService? dbService;
  // Sprint 3 #24 slice 2: prefer this repository when wired.
  CustomerRepository? customerRepository;

  Future<void> _persistCustomers(List<Customer> customers) {
    final repo = customerRepository;
    if (repo != null) return repo.saveAll(customers);
    return dbService?.saveCustomers(customers) ?? Future<void>.value();
  }

  Future<void> _persistPaymentEntries(List<CustomerPaymentEntry> entries) {
    final repo = customerRepository;
    if (repo != null) return repo.savePaymentEntries(entries);
    return dbService?.saveCustomerPaymentEntries(entries) ??
        Future<void>.value();
  }

  Future<void> _deleteCustomerRemote(String id) {
    final repo = customerRepository;
    if (repo != null) return repo.delete(id);
    return dbService?.deleteRecord('customers', id) ?? Future<void>.value();
  }

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
    _persistCustomers([customer]);
    _onChanged?.call();
    notifyListeners();
    return customer;
  }

  /// Adds credit (outstanding balance) to a customer.
  ///
  /// When [persist] is false, only the in-memory state is updated and
  /// the DB is not written. Use this after a server-side RPC has
  /// already applied the same mutation atomically — avoids a
  /// redundant (and race-prone) client write that could overwrite
  /// concurrent updates from other devices.
  void addCredit(String customerId, double amount, {bool persist = true}) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      _customers[index] = _customers[index].copyWith(
        outstandingBalance: _customers[index].outstandingBalance + amount,
        lastCreditDate: DateTime.now(),
      );
      if (persist) {
        _persistCustomers([_customers[index]]);
      }
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
      _persistCustomers([_customers[index]]);
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
      _persistCustomers([_customers[index]]);
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
      _persistPaymentEntries([entry]);
      _persistCustomers([_customers[index]]);
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

  // ── Invoice-level payment linkage (#43) ──────────────────────────────────

  /// All payments linked to a specific bill/invoice.
  List<CustomerPaymentEntry> getPaymentsForBill(String billId) {
    return _paymentEntries
        .where((e) => e.billReference == billId)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
  }

  /// Total amount paid against a specific bill.
  double getPaidAmountForBill(String billId) {
    return _paymentEntries
        .where((e) => e.billReference == billId && !e.isBouncedCheque)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Outstanding balance remaining on a specific bill.
  double getOutstandingForBill(String billId, double billCreditAmount) {
    final paid = getPaidAmountForBill(billId);
    return (billCreditAmount - paid).clamp(0.0, double.infinity);
  }

  // ── Cheque clearing workflow (#50) ──────────────────────────────────────

  /// Records a cheque payment with pending status.
  void recordChequePayment(
    String customerId,
    double amount, {
    required String chequeNumber,
    String? chequeBank,
    DateTime? chequeDate,
    String? recordedBy,
    String? notes,
    String? billReference,
  }) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index == -1) return;

    // Reduce outstanding immediately (optimistic — reversed if bounced)
    final newBalance =
        (_customers[index].outstandingBalance - amount).clamp(0.0, double.infinity);
    _customers[index] = _customers[index].copyWith(
      outstandingBalance: newBalance,
    );

    final entry = CustomerPaymentEntry(
      customerId: customerId,
      amount: amount,
      paymentMode: SettlementPaymentMode.cheque,
      recordedBy: recordedBy,
      notes: notes,
      billReference: billReference,
      chequeNumber: chequeNumber,
      chequeBank: chequeBank,
      chequeDate: chequeDate,
      chequeStatus: ChequeStatus.pending,
    );
    _paymentEntries.add(entry);
    _persistPaymentEntries([entry]);
    _persistCustomers([_customers[index]]);
    _onChanged?.call();
    notifyListeners();
  }

  /// Marks a pending cheque as cleared.
  bool clearCheque(String entryId) {
    final index = _paymentEntries.indexWhere((e) => e.id == entryId);
    if (index == -1) return false;
    final entry = _paymentEntries[index];
    if (entry.chequeStatus != ChequeStatus.pending) return false;

    _paymentEntries[index] = entry.copyWith(chequeStatus: ChequeStatus.cleared);
    _persistPaymentEntries([_paymentEntries[index]]);
    _onChanged?.call();
    notifyListeners();
    return true;
  }

  /// Marks a pending cheque as bounced and reverses the customer balance deduction.
  bool bounceCheque(String entryId) {
    final index = _paymentEntries.indexWhere((e) => e.id == entryId);
    if (index == -1) return false;
    final entry = _paymentEntries[index];
    if (entry.chequeStatus != ChequeStatus.pending) return false;

    _paymentEntries[index] = entry.copyWith(chequeStatus: ChequeStatus.bounced);

    // Reverse the balance deduction
    final custIndex = _customers.indexWhere((c) => c.id == entry.customerId);
    if (custIndex != -1) {
      _customers[custIndex] = _customers[custIndex].copyWith(
        outstandingBalance: _customers[custIndex].outstandingBalance + entry.amount,
      );
      _persistCustomers([_customers[custIndex]]);
    }

    _persistPaymentEntries([_paymentEntries[index]]);
    _onChanged?.call();
    notifyListeners();
    return true;
  }

  /// All cheque payments with pending status.
  List<CustomerPaymentEntry> get pendingCheques {
    return _paymentEntries.where((e) => e.isPendingCheque).toList()
      ..sort((a, b) => (a.chequeDate ?? a.recordedAt)
          .compareTo(b.chequeDate ?? b.recordedAt));
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
    _persistCustomers([_customers[index]]);
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
    _persistCustomers([_customers[index]]);
    _onChanged?.call();
    notifyListeners();
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    _deleteCustomerRemote(id);
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
    if (customerRepository == null && dbService == null) return null;
    try {
      final customers = await (customerRepository != null
          ? customerRepository!.loadAll()
          : dbService!.loadCustomers());
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
