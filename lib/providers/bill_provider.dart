import 'package:flutter/foundation.dart';
import '../models/bill.dart';
import '../models/business_config.dart';
import '../models/line_item.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/payment_info.dart';
import '../services/bill_number_service.dart';
import '../services/db_service.dart';
import '../services/gst_calculator.dart';
import '../services/supabase_service.dart';
import '../providers/product_provider.dart';
import '../providers/customer_provider.dart';

enum BillFilter { all, today, thisWeek, thisMonth, cash, credit }

class BillProvider extends ChangeNotifier {
  final BillNumberService _billNumberService;
  final List<Bill> _bills = [];
  final VoidCallback? _onChanged;
  DbService? dbService;
  Future<void>? pendingSave;
  String? businessId;

  // Edit mode
  Bill? _editingBill;

  // Active bill state
  List<LineItem> _activeLineItems = [];
  double _discountAmount = 0;
  bool _discountIsPercent = true;
  double _discountValue = 0;
  Customer? _activeCustomer;
  String? _activeDiagnosis;
  String? _activeVisitNotes;
  String? _activeVehicleReg;
  String? _activeVehicleMake;
  String? _activeVehicleModel;
  String? _activeKmReading;

  BillProvider({
    BillNumberService? billNumberService,
    List<Bill>? initialBills,
    VoidCallback? onChanged,
  }) : _billNumberService = billNumberService ?? BillNumberService(),
       _onChanged = onChanged {
    if (initialBills != null) {
      // Sort newest-first so dedup keeps the most recent bill for each number
      final sorted = List<Bill>.from(initialBills)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final seen = <String>{};
      for (final bill in sorted) {
        if (seen.add(bill.billNumber)) {
          _bills.add(bill);
        }
      }
      _billNumberService.hydrateFromExistingBills(
        _bills.map((bill) => bill.billNumber).toList(),
      );
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Bill> get bills => List.unmodifiable(_bills);
  List<LineItem> get activeLineItems => List.unmodifiable(_activeLineItems);
  Customer? get activeCustomer => _activeCustomer;
  double get discountAmount => _discountAmount;
  bool get discountIsPercent => _discountIsPercent;
  double get discountValue => _discountValue;
  String? get activeDiagnosis => _activeDiagnosis;
  String? get activeVisitNotes => _activeVisitNotes;
  String? get activeVehicleReg => _activeVehicleReg;
  String? get activeVehicleMake => _activeVehicleMake;
  String? get activeVehicleModel => _activeVehicleModel;
  String? get activeKmReading => _activeKmReading;

  void _resetActiveState() {
    _editingBill = null;
    _activeLineItems = [];
    _discountAmount = 0;
    _discountIsPercent = true;
    _discountValue = 0;
    _activeCustomer = null;
    _activeDiagnosis = null;
    _activeVisitNotes = null;
    _activeVehicleReg = null;
    _activeVehicleMake = null;
    _activeVehicleModel = null;
    _activeKmReading = null;
  }

  bool get isEditMode => _editingBill != null;
  String? get editingBillNumber => _editingBill?.billNumber;

  String getNextBillNumber({String prefix = 'INV'}) =>
      _billNumberService.generateBillNumber(prefix: prefix);

  String get nextBillNumber => _billNumberService.generateBillNumber();

  // Active bill calculations
  double get activeSubtotal => GstCalculator.subtotal(_activeLineItems);

  double get activeTotalLineDiscount =>
      _activeLineItems.fold(0.0, (sum, item) => sum + item.lineDiscountAmount);

  double get activeDiscount => _discountAmount;

  double activeCgst({bool isInterState = false}) {
    if (isInterState) return 0;
    final sub = GstCalculator.discountedSubtotal(_activeLineItems);
    if (sub <= 0) return 0;
    final afterBillDiscount = sub - _discountAmount;
    if (afterBillDiscount <= 0) return 0;
    final discountRatio = afterBillDiscount / sub;
    return GstCalculator.totalCgst(_activeLineItems) * discountRatio;
  }

  double activeSgst({bool isInterState = false}) {
    if (isInterState) return 0;
    final sub = GstCalculator.discountedSubtotal(_activeLineItems);
    if (sub <= 0) return 0;
    final afterBillDiscount = sub - _discountAmount;
    if (afterBillDiscount <= 0) return 0;
    final discountRatio = afterBillDiscount / sub;
    return GstCalculator.totalSgst(_activeLineItems) * discountRatio;
  }

  double activeIgst({bool isInterState = false}) {
    if (!isInterState) return 0;
    final sub = GstCalculator.discountedSubtotal(_activeLineItems);
    if (sub <= 0) return 0;
    final afterBillDiscount = sub - _discountAmount;
    if (afterBillDiscount <= 0) return 0;
    final discountRatio = afterBillDiscount / sub;
    return GstCalculator.totalIgst(_activeLineItems) * discountRatio;
  }

  double activeGrandTotal({bool isInterState = false}) {
    return GstCalculator.grandTotal(
      _activeLineItems,
      discount: _discountAmount,
      isInterState: isInterState,
    );
  }

  bool get hasActiveItems => _activeLineItems.isNotEmpty;

  // Today's stats
  List<Bill> get todaysBills {
    final now = DateTime.now();
    return _bills
        .where(
          (b) =>
              b.timestamp.year == now.year &&
              b.timestamp.month == now.month &&
              b.timestamp.day == now.day,
        )
        .toList();
  }

  double get todaysSales =>
      todaysBills.fold(0.0, (sum, b) => sum + b.grandTotal);
  int get todaysBillCount => todaysBills.length;
  double get todaysTotalDiscount =>
      todaysBills.fold(0.0, (sum, b) => sum + b.totalDiscount);
  double get totalOutstandingCredit =>
      _bills.fold(0.0, (sum, b) => sum + b.creditAmount);

  List<Bill> get recentBills {
    final sorted = List<Bill>.from(_bills)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sorted.take(5).toList();
  }

  // Bill history filtering
  List<Bill> _billsInDateRange(DateTime start, DateTime end) {
    return _bills
        .where((b) => !b.timestamp.isBefore(start) && b.timestamp.isBefore(end))
        .toList();
  }

  List<Bill> get _thisWeekBills {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(start.year, start.month, start.day);
    return _billsInDateRange(weekStart, now.add(const Duration(days: 1)));
  }

  List<Bill> get _thisMonthBills {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    return _billsInDateRange(monthStart, now.add(const Duration(days: 1)));
  }

  List<Bill> get _cashBills =>
      _bills.where((b) => b.paymentMode == PaymentMode.cash).toList();

  List<Bill> get _creditBills =>
      _bills.where((b) => b.paymentMode == PaymentMode.credit).toList();

  int get allBillCount => _bills.length;
  int get todayBillCount => todaysBills.length;
  int get thisWeekBillCount => _thisWeekBills.length;
  int get thisMonthBillCount => _thisMonthBills.length;
  int get cashBillCount => _cashBills.length;
  int get creditBillCount => _creditBills.length;

  List<Bill> getFilteredBills(String query, BillFilter filter) {
    List<Bill> result;
    switch (filter) {
      case BillFilter.all:
        result = List<Bill>.from(_bills);
      case BillFilter.today:
        result = todaysBills;
      case BillFilter.thisWeek:
        result = _thisWeekBills;
      case BillFilter.thisMonth:
        result = _thisMonthBills;
      case BillFilter.cash:
        result = _cashBills;
      case BillFilter.credit:
        result = _creditBills;
    }

    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      result = result
          .where(
            (b) =>
                b.billNumber.toLowerCase().contains(lowerQuery) ||
                (b.customer?.name.toLowerCase().contains(lowerQuery) ?? false),
          )
          .toList();
    }

    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  // Active bill mutations
  void addItemToBill(
    Product product, {
    BusinessType businessType = BusinessType.general,
  }) {
    final existing = _activeLineItems.indexWhere(
      (i) => i.product.id == product.id,
    );
    if (existing != -1) {
      _activeLineItems[existing] = _activeLineItems[existing].copyWith(
        quantity: _activeLineItems[existing].quantity + product.quantityStep,
      );
    } else {
      // Determine discount: customer default takes priority over product default
      final discount = (_activeCustomer?.defaultDiscountPercent ?? 0) > 0
          ? _activeCustomer!.defaultDiscountPercent
          : product.defaultDiscountPercent;
      if (businessType == BusinessType.pharmacy) {
        final batch = product.nearestExpiryBatch;
        _activeLineItems.add(LineItem(
          product: product,
          quantity: product.minQuantity,
          batch: batch,
          discountPercent: discount,
        ));
      } else {
        _activeLineItems.add(LineItem(
          product: product,
          quantity: product.minQuantity,
          discountPercent: discount,
        ));
      }
    }
    _recalculateDiscount();
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _activeLineItems.length) {
      _activeLineItems.removeAt(index);
      _recalculateDiscount();
      notifyListeners();
    }
  }

  LineItem? removeItemForUndo(int index) {
    if (index >= 0 && index < _activeLineItems.length) {
      final item = _activeLineItems.removeAt(index);
      _recalculateDiscount();
      notifyListeners();
      return item;
    }
    return null;
  }

  void restoreItem(int index, LineItem item) {
    if (index <= _activeLineItems.length) {
      _activeLineItems.insert(index, item);
      _recalculateDiscount();
      notifyListeners();
    }
  }

  void updateLineDiscount(int index, double discountPercent) {
    if (index >= 0 && index < _activeLineItems.length) {
      _activeLineItems[index] = _activeLineItems[index].copyWith(
        discountPercent: discountPercent.clamp(0, 100),
      );
      notifyListeners();
    }
  }

  void updateQuantity(int index, double newQuantity) {
    if (index >= 0 && index < _activeLineItems.length && newQuantity > 0) {
      _activeLineItems[index] = _activeLineItems[index].copyWith(
        quantity: newQuantity,
      );
      _recalculateDiscount();
      notifyListeners();
    }
  }

  void updateSerialIds(int index, List<String> ids) {
    if (index >= 0 && index < _activeLineItems.length) {
      _activeLineItems[index] = _activeLineItems[index].copyWith(
        serialNumberIds: List.from(ids),
      );
      notifyListeners();
    }
  }

  void setDiscount({required bool isPercent, required double value}) {
    _discountIsPercent = isPercent;
    _discountValue = value;
    _recalculateDiscount();
    notifyListeners();
  }

  void clearDiscount() {
    _discountIsPercent = true;
    _discountValue = 0;
    _discountAmount = 0;
    notifyListeners();
  }

  void _recalculateDiscount() {
    final sub = GstCalculator.discountedSubtotal(_activeLineItems);
    if (_discountIsPercent) {
      _discountAmount = sub * (_discountValue / 100);
    } else {
      _discountAmount = _discountValue.clamp(0, sub);
    }
  }

  void setActiveCustomer(Customer? customer) {
    _activeCustomer = customer;
    // Apply customer discount to all existing line items
    if (customer != null && customer.defaultDiscountPercent > 0) {
      _activeLineItems = _activeLineItems
          .map((item) =>
              item.copyWith(discountPercent: customer.defaultDiscountPercent))
          .toList();
    } else if (customer == null) {
      // Revert to product defaults when customer is cleared
      _activeLineItems = _activeLineItems
          .map((item) =>
              item.copyWith(discountPercent: item.product.defaultDiscountPercent))
          .toList();
    }
    _recalculateDiscount();
    notifyListeners();
  }

  void setVisitNotes({String? diagnosis, String? visitNotes}) {
    _activeDiagnosis = diagnosis;
    _activeVisitNotes = visitNotes;
    notifyListeners();
  }

  void setVehicleInfo({
    String? vehicleReg,
    String? vehicleMake,
    String? vehicleModel,
    String? kmReading,
  }) {
    _activeVehicleReg = vehicleReg;
    _activeVehicleMake = vehicleMake;
    _activeVehicleModel = vehicleModel;
    _activeKmReading = kmReading;
    notifyListeners();
  }

  void loadBillForEdit(Bill bill) {
    _editingBill = bill;
    _activeLineItems = List<LineItem>.from(bill.lineItems);
    _discountAmount = bill.discount;
    _discountIsPercent = bill.billDiscountPercent > 0;
    _discountValue = bill.billDiscountPercent > 0 ? bill.billDiscountPercent : bill.discount;
    _activeCustomer = bill.customer;
    _activeDiagnosis = bill.diagnosis;
    _activeVisitNotes = bill.visitNotes;
    _activeVehicleReg = bill.vehicleReg;
    _activeVehicleMake = bill.vehicleMake;
    _activeVehicleModel = bill.vehicleModel;
    _activeKmReading = bill.kmReading;
    notifyListeners();
  }

  Bill completeBill({
    required PaymentInfo paymentInfo,
    required bool gstEnabled,
    required ProductProvider productProvider,
    required CustomerProvider customerProvider,
    String billPrefix = 'INV',
    bool isInterState = false,
    double advanceUsed = 0,
  }) {
    // Handle edit mode: replace existing bill in-place
    if (_editingBill != null) {
      final updatedBill = Bill(
        id: _editingBill!.id,
        billNumber: _editingBill!.billNumber,
        lineItems: List.from(_activeLineItems),
        subtotal: activeSubtotal,
        discount: _discountAmount,
        billDiscountPercent: _discountIsPercent ? _discountValue : 0,
        totalLineDiscount: activeTotalLineDiscount,
        cgst: gstEnabled ? activeCgst(isInterState: isInterState) : 0,
        sgst: gstEnabled ? activeSgst(isInterState: isInterState) : 0,
        igst: gstEnabled ? activeIgst(isInterState: isInterState) : 0,
        grandTotal: activeGrandTotal(isInterState: isInterState),
        isInterState: isInterState,
        paymentMode: paymentInfo.mode,
        amountReceived: paymentInfo.amountReceived,
        creditAmount: paymentInfo.creditAmount,
        customer: paymentInfo.customer,
        splitCashAmount: paymentInfo.splitCashAmount,
        splitUpiAmount: paymentInfo.splitUpiAmount,
        diagnosis: _activeDiagnosis,
        visitNotes: _activeVisitNotes,
        vehicleReg: _activeVehicleReg,
        vehicleMake: _activeVehicleMake,
        vehicleModel: _activeVehicleModel,
        kmReading: _activeKmReading,
        advanceUsed: advanceUsed,
        timestamp: _editingBill!.timestamp,
      );
      final idx = _bills.indexWhere((b) => b.id == _editingBill!.id);
      if (idx != -1) _bills[idx] = updatedBill;
      pendingSave = dbService?.saveBills([updatedBill]);
      _resetActiveState();
      _onChanged?.call();
      notifyListeners();
      return updatedBill;
    }

    final billNumber = _billNumberService.generateBillNumber(
      prefix: billPrefix,
    );

    final bill = Bill(
      billNumber: billNumber,
      lineItems: List.from(_activeLineItems),
      subtotal: activeSubtotal,
      discount: _discountAmount,
      billDiscountPercent: _discountIsPercent ? _discountValue : 0,
      totalLineDiscount: activeTotalLineDiscount,
      cgst: gstEnabled ? activeCgst(isInterState: isInterState) : 0,
      sgst: gstEnabled ? activeSgst(isInterState: isInterState) : 0,
      igst: gstEnabled ? activeIgst(isInterState: isInterState) : 0,
      grandTotal: activeGrandTotal(isInterState: isInterState),
      isInterState: isInterState,
      paymentMode: paymentInfo.mode,
      amountReceived: paymentInfo.amountReceived,
      creditAmount: paymentInfo.creditAmount,
      customer: paymentInfo.customer,
      splitCashAmount: paymentInfo.splitCashAmount,
      splitUpiAmount: paymentInfo.splitUpiAmount,
      diagnosis: _activeDiagnosis,
      visitNotes: _activeVisitNotes,
      vehicleReg: _activeVehicleReg,
      vehicleMake: _activeVehicleMake,
      vehicleModel: _activeVehicleModel,
      kmReading: _activeKmReading,
      advanceUsed: advanceUsed,
    );

    _bills.add(bill);

    // Immediately persist new bill to Supabase — track future so refresh can await it
    pendingSave = dbService?.saveBills([bill]);

    // Decrement stock (skip services)
    for (final item in _activeLineItems) {
      if (!item.product.isService) {
        productProvider.decrementStock(
          item.product.id,
          item.quantity,
          batchId: item.batch?.id,
        );
      }
    }

    // Update customer credit
    if (paymentInfo.mode == PaymentMode.credit &&
        paymentInfo.customer != null) {
      customerProvider.addCredit(
        paymentInfo.customer!.id,
        paymentInfo.creditAmount,
      );
    }

    // Update customer vehicle record (workshop)
    if (_activeVehicleReg != null &&
        _activeVehicleReg!.isNotEmpty &&
        paymentInfo.customer != null) {
      customerProvider.upsertVehicle(
        paymentInfo.customer!.id,
        CustomerVehicle(
          reg: _activeVehicleReg!,
          make: _activeVehicleMake,
          model: _activeVehicleModel,
          lastKmReading: _activeKmReading,
        ),
      );
    }

    // Reset active bill
    _resetActiveState();
    _onChanged?.call();
    notifyListeners();

    return bill;
  }

  /// Async version of [completeBill] that uses the `complete_bill` Supabase RPC
  /// for atomic server-side execution (bill save + stock + credit + bill count).
  /// Falls back to the synchronous local path when offline or RPC is unavailable.
  Future<Bill> completeBillAsync({
    required PaymentInfo paymentInfo,
    required bool gstEnabled,
    required ProductProvider productProvider,
    required CustomerProvider customerProvider,
    String billPrefix = 'INV',
    bool isInterState = false,
    double advanceUsed = 0,
  }) async {
    // Edit mode: use synchronous path (no server number generation needed)
    if (_editingBill != null) {
      return completeBill(
        paymentInfo: paymentInfo,
        gstEnabled: gstEnabled,
        productProvider: productProvider,
        customerProvider: customerProvider,
        billPrefix: billPrefix,
        isInterState: isInterState,
        advanceUsed: advanceUsed,
      );
    }

    // Try to get a server-side bill number first
    final billNumber = await _billNumberService.generateBillNumberAsync(
      businessId: businessId,
      prefix: billPrefix,
    );

    final bill = Bill(
      billNumber: billNumber,
      lineItems: List.from(_activeLineItems),
      subtotal: activeSubtotal,
      discount: _discountAmount,
      billDiscountPercent: _discountIsPercent ? _discountValue : 0,
      totalLineDiscount: activeTotalLineDiscount,
      cgst: gstEnabled ? activeCgst(isInterState: isInterState) : 0,
      sgst: gstEnabled ? activeSgst(isInterState: isInterState) : 0,
      igst: gstEnabled ? activeIgst(isInterState: isInterState) : 0,
      grandTotal: activeGrandTotal(isInterState: isInterState),
      isInterState: isInterState,
      paymentMode: paymentInfo.mode,
      amountReceived: paymentInfo.amountReceived,
      creditAmount: paymentInfo.creditAmount,
      customer: paymentInfo.customer,
      splitCashAmount: paymentInfo.splitCashAmount,
      splitUpiAmount: paymentInfo.splitUpiAmount,
      diagnosis: _activeDiagnosis,
      visitNotes: _activeVisitNotes,
      vehicleReg: _activeVehicleReg,
      vehicleMake: _activeVehicleMake,
      vehicleModel: _activeVehicleModel,
      kmReading: _activeKmReading,
      advanceUsed: advanceUsed,
    );

    _bills.add(bill);

    // Build stock changes payload for RPC
    final stockChanges = _activeLineItems
        .where((item) => !item.product.isService)
        .map((item) => {
              'productId': item.product.id,
              if (item.batch != null) 'batchId': item.batch!.id,
              'qty': item.quantity.toInt(),
            })
        .toList();

    // Credit payload
    final creditPayload = paymentInfo.mode == PaymentMode.credit &&
            paymentInfo.customer != null
        ? {'customerId': paymentInfo.customer!.id, 'amount': paymentInfo.creditAmount}
        : null;

    // Try atomic server RPC; fall back to individual saves on failure
    bool rpcSucceeded = false;
    if (businessId != null) {
      try {
        await SupabaseService.client.rpc(
          'complete_bill',
          params: {
            'p_business_id': businessId,
            'p_bill': bill.toJson(),
            'p_stock_changes': stockChanges,
            if (creditPayload != null) 'p_credit': creditPayload,
            'p_prefix': billPrefix,
            'p_use_server_bill_number': false, // already got number above
          },
        );
        rpcSucceeded = true;
      } catch (_) {
        // Offline or RPC error — fall through to individual saves
      }
    }

    if (!rpcSucceeded) {
      pendingSave = dbService?.saveBills([bill]);
    }

    // Update local state regardless (for instant UI)
    for (final item in _activeLineItems) {
      if (!item.product.isService) {
        productProvider.decrementStock(
          item.product.id,
          item.quantity,
          batchId: item.batch?.id,
        );
      }
    }
    if (paymentInfo.mode == PaymentMode.credit && paymentInfo.customer != null) {
      customerProvider.addCredit(
        paymentInfo.customer!.id,
        paymentInfo.creditAmount,
      );
    }
    if (_activeVehicleReg != null &&
        _activeVehicleReg!.isNotEmpty &&
        paymentInfo.customer != null) {
      customerProvider.upsertVehicle(
        paymentInfo.customer!.id,
        CustomerVehicle(
          reg: _activeVehicleReg!,
          make: _activeVehicleMake,
          model: _activeVehicleModel,
          lastKmReading: _activeKmReading,
        ),
      );
    }

    _resetActiveState();
    _onChanged?.call();
    notifyListeners();
    return bill;
  }

  void clearActiveBill() {
    _resetActiveState();
    notifyListeners();
  }

  void clearAllBills() {
    _bills.clear();
    _resetActiveState();
    _billNumberService.hydrateFromExistingBills(const []);
    _onChanged?.call();
    notifyListeners();
  }

  void replaceAllData(List<Bill> bills) {
    _bills
      ..clear()
      ..addAll(bills);
    _resetActiveState();
    _billNumberService.hydrateFromExistingBills(
      bills.map((bill) => bill.billNumber).toList(),
    );
    _onChanged?.call();
    notifyListeners();
  }

  /// Reloads bills from Supabase in-place without a full app restart.
  ///
  /// Returns `null` on success, or an error message string on failure so
  /// callers can display feedback to the user.
  Future<String?> syncFromDb() async {
    if (dbService == null) return null;
    _isLoading = true;
    notifyListeners();
    try {
      final bills = await dbService!.loadBills();
      // Sort newest-first so dedup always keeps the most recent bill per number
      bills.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _bills.clear();
      final seen = <String>{};
      for (final bill in bills) {
        if (seen.add(bill.billNumber)) {
          _bills.add(bill);
        }
      }
      _billNumberService.hydrateFromExistingBills(
        _bills.map((b) => b.billNumber).toList(),
      );
      _isLoading = false;
      notifyListeners();
      return null;
    } on FormatException catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('syncFromDb: data parse error — $e');
      return 'Sync failed: could not parse bill data.';
    } on Exception catch (e) {
      _isLoading = false;
      notifyListeners();
      final msg = e.toString();
      if (msg.contains('AuthException') || msg.contains('JWT')) {
        debugPrint('syncFromDb: auth error — $e');
        return 'Sync failed: session expired. Please log in again.';
      }
      debugPrint('syncFromDb: network/unknown error — $e');
      return 'Sync failed: please check your internet connection.';
    }
  }

  void deleteBill(String billNumber) {
    final index = _bills.indexWhere((b) => b.billNumber == billNumber);
    if (index == -1) return;
    final bill = _bills.removeAt(index);
    dbService?.deleteRecord('bills', bill.id);
    _onChanged?.call();
    notifyListeners();
  }
}
