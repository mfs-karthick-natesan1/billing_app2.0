import 'package:flutter/foundation.dart';

import '../models/cash_book_entry.dart';
import '../models/customer_payment_entry.dart';
import '../models/expense.dart';
import '../models/payment_info.dart';
import '../models/sales_return.dart';
import '../services/db_service.dart';
import 'bill_provider.dart';
import 'customer_provider.dart';
import 'expense_provider.dart';
import 'return_provider.dart';

class CashBookProvider extends ChangeNotifier {
  final BillProvider _billProvider;
  final ExpenseProvider _expenseProvider;
  final CustomerProvider _customerProvider;
  final ReturnProvider? _returnProvider;
  final VoidCallback? _onChanged;

  DbService? dbService;

  final Map<String, CashBookDay> _dayLedgers = {};

  int _billSignature = 0;
  int _expenseSignature = 0;
  int _paymentSignature = 0;
  int _returnSignature = 0;

  CashBookProvider({
    required BillProvider billProvider,
    required ExpenseProvider expenseProvider,
    required CustomerProvider customerProvider,
    ReturnProvider? returnProvider,
    List<CashBookDay>? initialDays,
    VoidCallback? onChanged,
  }) : _billProvider = billProvider,
       _expenseProvider = expenseProvider,
       _customerProvider = customerProvider,
       _returnProvider = returnProvider,
       _onChanged = onChanged {
    if (initialDays != null) {
      for (final day in initialDays) {
        _dayLedgers[_dateKey(day.date)] = day;
      }
    }

    _updateDependencySignatures();
    _billProvider.addListener(_onDependenciesChanged);
    _expenseProvider.addListener(_onDependenciesChanged);
    _customerProvider.addListener(_onDependenciesChanged);
    _returnProvider?.addListener(_onDependenciesChanged);
    recalculateFromDate(_earliestRelevantDate(), persist: false);
  }

  List<CashBookDay> get dayLedgers {
    final list = _dayLedgers.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  CashBookDay getCashBookDay(DateTime date) {
    final normalized = _startOfDay(date);
    _ensureDayExists(normalized);
    recalculateFromDate(normalized, persist: false);
    return _dayLedgers[_dateKey(normalized)]!;
  }

  CashBookDay getTodayCashBook() {
    return getCashBookDay(DateTime.now());
  }

  void setOpeningBalance(DateTime date, double amount) {
    final normalized = _startOfDay(date);
    _ensureDayExists(normalized);
    final key = _dateKey(normalized);
    final current = _dayLedgers[key]!;
    _dayLedgers[key] = current.copyWith(
      openingBalance: amount,
      openingBalanceOverridden: true,
    );
    recalculateFromDate(normalized);
  }

  void updateSupplierPayments(DateTime date, double amount) {
    final normalized = _startOfDay(date);
    _ensureDayExists(normalized);
    final key = _dateKey(normalized);
    final current = _dayLedgers[key]!;
    _dayLedgers[key] = current.copyWith(
      cashPaidToSuppliers: amount.clamp(0, double.infinity),
    );
    recalculateFromDate(normalized);
  }

  void setDayNotes(DateTime date, String? notes) {
    final normalized = _startOfDay(date);
    _ensureDayExists(normalized);
    final key = _dateKey(normalized);
    final current = _dayLedgers[key]!;
    _dayLedgers[key] = current.copyWith(
      notes: notes?.trim().isEmpty ?? true ? null : notes?.trim(),
    );
    dbService?.saveCashBook([_dayLedgers[key]!]);
    _persistAndNotify();
  }

  void closeDay(DateTime date, {String? closedBy}) {
    final normalized = _startOfDay(date);
    _ensureDayExists(normalized);
    recalculateFromDate(normalized);
    final key = _dateKey(normalized);
    final current = _dayLedgers[key]!;
    _dayLedgers[key] = current.copyWith(
      isClosed: true,
      closedAt: DateTime.now(),
      closedBy: closedBy,
    );
    recalculateFromDate(normalized);
  }

  bool reopenDay(DateTime date) {
    final normalized = _startOfDay(date);
    _ensureDayExists(normalized);
    final next = normalized.add(const Duration(days: 1));
    final nextDay = _dayLedgers[_dateKey(next)];
    if (nextDay != null && nextDay.isClosed) {
      return false;
    }
    final key = _dateKey(normalized);
    final current = _dayLedgers[key]!;
    _dayLedgers[key] = current.copyWith(
      isClosed: false,
      clearClosedAt: true,
      clearClosedBy: true,
    );
    recalculateFromDate(normalized);
    return true;
  }

  void addManualEntry(DateTime date, CashBookManualEntry entry) {
    final normalized = _startOfDay(date);
    _ensureDayExists(normalized);
    final key = _dateKey(normalized);
    final current = _dayLedgers[key]!;
    final incoming = List<CashBookManualEntry>.from(current.otherCashIn);
    final outgoing = List<CashBookManualEntry>.from(current.otherCashOut);

    if (entry.type == CashEntryType.cashIn) {
      incoming.add(entry);
    } else {
      outgoing.add(entry);
    }

    _dayLedgers[key] = current.copyWith(
      otherCashIn: incoming,
      otherCashOut: outgoing,
    );
    recalculateFromDate(normalized);
  }

  void updateManualEntry(DateTime date, CashBookManualEntry updatedEntry) {
    final normalized = _startOfDay(date);
    _ensureDayExists(normalized);
    final key = _dateKey(normalized);
    final current = _dayLedgers[key]!;

    var incoming = List<CashBookManualEntry>.from(current.otherCashIn)
      ..removeWhere((entry) => entry.id == updatedEntry.id);
    var outgoing = List<CashBookManualEntry>.from(current.otherCashOut)
      ..removeWhere((entry) => entry.id == updatedEntry.id);

    if (updatedEntry.type == CashEntryType.cashIn) {
      incoming.add(updatedEntry);
    } else {
      outgoing.add(updatedEntry);
    }

    _dayLedgers[key] = current.copyWith(
      otherCashIn: incoming,
      otherCashOut: outgoing,
    );
    recalculateFromDate(normalized);
  }

  void deleteManualEntry(DateTime date, String entryId) {
    final normalized = _startOfDay(date);
    _ensureDayExists(normalized);
    final key = _dateKey(normalized);
    final current = _dayLedgers[key]!;

    final incoming = List<CashBookManualEntry>.from(current.otherCashIn)
      ..removeWhere((entry) => entry.id == entryId);
    final outgoing = List<CashBookManualEntry>.from(current.otherCashOut)
      ..removeWhere((entry) => entry.id == entryId);

    _dayLedgers[key] = current.copyWith(
      otherCashIn: incoming,
      otherCashOut: outgoing,
    );
    recalculateFromDate(normalized);
  }

  void recalculateDay(DateTime date) {
    recalculateFromDate(_startOfDay(date), persist: true);
  }

  void recalculateFromDate(DateTime startDate, {bool persist = true}) {
    final normalizedStart = _startOfDay(startDate);
    final end = _maxRelevantDate();

    var cursor = normalizedStart;
    while (!cursor.isAfter(end)) {
      _ensureDayExists(cursor);
      final key = _dateKey(cursor);
      final current = _dayLedgers[key]!;

      final prevDate = cursor.subtract(const Duration(days: 1));
      final prev = _dayLedgers[_dateKey(prevDate)];

      final opening = current.openingBalanceOverridden
          ? current.openingBalance
          : prev?.closingBalance ?? current.openingBalance;

      final cashSales = _billProvider.bills
          .where((bill) => bill.paymentMode == PaymentMode.cash)
          .where((bill) => _isSameDay(bill.timestamp, cursor))
          .fold<double>(0, (sum, bill) => sum + bill.grandTotal);

      final cashReceived = _customerProvider
          .getPaymentEntriesByDateRange(
            cursor,
            cursor,
            paymentMode: SettlementPaymentMode.cash,
          )
          .fold<double>(0, (sum, entry) => sum + entry.amount);

      final cashExpenses = _expenseProvider.expenses
          .where((expense) => expense.paymentMode == ExpensePaymentMode.cash)
          .where((expense) => _isSameDay(expense.date, cursor))
          .fold<double>(0, (sum, expense) => sum + expense.amount);

      final cashRefunds = _returnProvider?.returns
              .where((r) => r.refundMode == RefundMode.cash)
              .where((r) => _isSameDay(r.date, cursor))
              .fold<double>(0, (sum, r) => sum + r.totalRefundAmount) ??
          0;

      final totalOtherIn = current.otherCashIn.fold<double>(
        0,
        (sum, entry) => sum + entry.amount,
      );
      final totalOtherOut = current.otherCashOut.fold<double>(
        0,
        (sum, entry) => sum + entry.amount,
      );
      final closing =
          opening +
          cashSales +
          cashReceived +
          totalOtherIn -
          cashExpenses -
          cashRefunds -
          current.cashPaidToSuppliers -
          totalOtherOut;

      _dayLedgers[key] = current.copyWith(
        openingBalance: opening,
        cashSales: cashSales,
        cashReceived: cashReceived,
        cashExpenses: cashExpenses,
        closingBalance: closing,
      );

      cursor = cursor.add(const Duration(days: 1));
    }

    if (persist) {
      dbService?.saveCashBook(_dayLedgers.values.toList());
      _persistAndNotify();
    }
  }

  double getClosingBalance(DateTime date) {
    return getCashBookDay(date).closingBalance;
  }

  double getOpeningBalance(DateTime date) {
    return getCashBookDay(date).openingBalance;
  }

  CashBookDayBreakdown getDayBreakdown(DateTime date) {
    return CashBookDayBreakdown(getCashBookDay(date));
  }

  List<CashBookDay> getCashBookRange(DateTime from, DateTime to) {
    final start = _startOfDay(from);
    final end = _startOfDay(to);
    final result = <CashBookDay>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      result.add(getCashBookDay(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  CashBookMonthSummary getMonthSummary(int month, int year) {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0);
    final days = getCashBookRange(from, to);
    if (days.isEmpty) return const CashBookMonthSummary();

    final inflows = days.fold<double>(0, (sum, day) => sum + day.totalInflows);
    final outflows = days.fold<double>(
      0,
      (sum, day) => sum + day.totalOutflows,
    );
    final opening = days.first.openingBalance;
    final closing = days.last.closingBalance;

    return CashBookMonthSummary(
      totalInflows: inflows,
      totalOutflows: outflows,
      net: inflows - outflows,
      openingBalance: opening,
      closingBalance: closing,
    );
  }

  bool hasPendingDays() {
    final earliest = _earliestRelevantDate();
    final today = _startOfDay(DateTime.now());
    if (!earliest.isBefore(today)) return false;

    var cursor = earliest;
    while (cursor.isBefore(today)) {
      _ensureDayExists(cursor);
      final day = _dayLedgers[_dateKey(cursor)]!;
      if (!day.isClosed) return true;
      cursor = cursor.add(const Duration(days: 1));
    }
    return false;
  }

  int pendingDaysCount() {
    final earliest = _earliestRelevantDate();
    final today = _startOfDay(DateTime.now());
    if (!earliest.isBefore(today)) return 0;

    var count = 0;
    var cursor = earliest;
    while (cursor.isBefore(today)) {
      _ensureDayExists(cursor);
      final day = _dayLedgers[_dateKey(cursor)]!;
      if (!day.isClosed) count++;
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  double? getCashDiscrepancy(DateTime date) {
    return null;
  }

  void clearAllData() {
    _dayLedgers.clear();
    _updateDependencySignatures();
    recalculateFromDate(_startOfDay(DateTime.now()), persist: false);
    _persistAndNotify();
  }

  DateTime _earliestRelevantDate() {
    final candidates = <DateTime>[];

    if (_billProvider.bills.isNotEmpty) {
      final sorted = _billProvider.bills.map((b) => b.timestamp).toList()
        ..sort((a, b) => a.compareTo(b));
      candidates.add(sorted.first);
    }
    if (_expenseProvider.expenses.isNotEmpty) {
      final sorted = _expenseProvider.expenses.map((e) => e.date).toList()
        ..sort((a, b) => a.compareTo(b));
      candidates.add(sorted.first);
    }
    if (_customerProvider.paymentEntries.isNotEmpty) {
      final sorted =
          _customerProvider.paymentEntries.map((e) => e.recordedAt).toList()
            ..sort((a, b) => a.compareTo(b));
      candidates.add(sorted.first);
    }
    if (_dayLedgers.isNotEmpty) {
      final sorted = _dayLedgers.values.map((d) => d.date).toList()
        ..sort((a, b) => a.compareTo(b));
      candidates.add(sorted.first);
    }

    if (candidates.isEmpty) return _startOfDay(DateTime.now());
    candidates.sort((a, b) => a.compareTo(b));
    return _startOfDay(candidates.first);
  }

  DateTime _maxRelevantDate() {
    final candidates = <DateTime>[DateTime.now()];

    if (_billProvider.bills.isNotEmpty) {
      final sorted = _billProvider.bills.map((b) => b.timestamp).toList()
        ..sort((a, b) => b.compareTo(a));
      candidates.add(sorted.first);
    }
    if (_expenseProvider.expenses.isNotEmpty) {
      final sorted = _expenseProvider.expenses.map((e) => e.date).toList()
        ..sort((a, b) => b.compareTo(a));
      candidates.add(sorted.first);
    }
    if (_customerProvider.paymentEntries.isNotEmpty) {
      final sorted =
          _customerProvider.paymentEntries.map((e) => e.recordedAt).toList()
            ..sort((a, b) => b.compareTo(a));
      candidates.add(sorted.first);
    }
    if (_dayLedgers.isNotEmpty) {
      final sorted = _dayLedgers.values.map((d) => d.date).toList()
        ..sort((a, b) => b.compareTo(a));
      candidates.add(sorted.first);
    }

    candidates.sort((a, b) => b.compareTo(a));
    return _startOfDay(candidates.first);
  }

  void _onDependenciesChanged() {
    final newBillSignature = _computeBillSignature();
    final newExpenseSignature = _computeExpenseSignature();
    final newPaymentSignature = _computePaymentSignature();
    final newReturnSignature = _computeReturnSignature();

    final changed =
        newBillSignature != _billSignature ||
        newExpenseSignature != _expenseSignature ||
        newPaymentSignature != _paymentSignature ||
        newReturnSignature != _returnSignature;

    if (!changed) return;

    _billSignature = newBillSignature;
    _expenseSignature = newExpenseSignature;
    _paymentSignature = newPaymentSignature;
    _returnSignature = newReturnSignature;

    recalculateFromDate(_earliestRelevantDate());
  }

  void _updateDependencySignatures() {
    _billSignature = _computeBillSignature();
    _expenseSignature = _computeExpenseSignature();
    _paymentSignature = _computePaymentSignature();
    _returnSignature = _computeReturnSignature();
  }

  int _computeBillSignature() {
    final bills = _billProvider.bills;
    if (bills.isEmpty) return 0;
    final latest = bills.reduce(
      (a, b) => a.timestamp.isAfter(b.timestamp) ? a : b,
    );
    return Object.hash(
      bills.length,
      latest.id,
      latest.timestamp.millisecondsSinceEpoch,
      latest.grandTotal,
    );
  }

  int _computeExpenseSignature() {
    final expenses = _expenseProvider.expenses;
    if (expenses.isEmpty) return 0;
    final latest = expenses.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    return Object.hash(
      expenses.length,
      latest.id,
      latest.date.millisecondsSinceEpoch,
      latest.amount,
    );
  }

  int _computePaymentSignature() {
    final payments = _customerProvider.paymentEntries;
    if (payments.isEmpty) return 0;
    final latest = payments.reduce(
      (a, b) => a.recordedAt.isAfter(b.recordedAt) ? a : b,
    );
    return Object.hash(
      payments.length,
      latest.id,
      latest.recordedAt.millisecondsSinceEpoch,
      latest.amount,
    );
  }

  int _computeReturnSignature() {
    final returns = _returnProvider?.returns ?? [];
    if (returns.isEmpty) return 0;
    final latest = returns.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    return Object.hash(
      returns.length,
      latest.id,
      latest.date.millisecondsSinceEpoch,
      latest.totalRefundAmount,
    );
  }

  void _ensureDayExists(DateTime date) {
    final normalized = _startOfDay(date);
    final key = _dateKey(normalized);
    _dayLedgers.putIfAbsent(key, () => CashBookDay(date: normalized));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  void _persistAndNotify() {
    _onChanged?.call();
    notifyListeners();
  }

  @override
  void dispose() {
    _billProvider.removeListener(_onDependenciesChanged);
    _expenseProvider.removeListener(_onDependenciesChanged);
    _customerProvider.removeListener(_onDependenciesChanged);
    _returnProvider?.removeListener(_onDependenciesChanged);
    super.dispose();
  }
}
