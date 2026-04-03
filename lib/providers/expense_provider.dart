import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/db_service.dart';

enum ExpenseDateFilter { all, today, thisWeek, thisMonth, customRange }

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  final VoidCallback? _onChanged;

  DbService? dbService;

  ExpenseProvider({List<Expense>? initialExpenses, VoidCallback? onChanged})
    : _onChanged = onChanged {
    if (initialExpenses != null) {
      _expenses.addAll(initialExpenses);
    }
  }

  List<Expense> get expenses => List.unmodifiable(_expenses);

  double get todayTotal =>
      getTodayExpenses().fold(0, (sum, expense) => sum + expense.amount);

  double get thisMonthTotal =>
      getThisMonthExpenses().fold(0, (sum, expense) => sum + expense.amount);

  void addExpense(Expense expense) {
    _expenses.add(expense);
    dbService?.saveExpenses([expense]);
    _persistAndNotify();
  }

  void updateExpense(Expense updated) {
    final index = _expenses.indexWhere((expense) => expense.id == updated.id);
    if (index == -1) return;
    _expenses[index] = updated;
    dbService?.saveExpenses([updated]);
    _persistAndNotify();
  }

  void deleteExpense(String id) {
    _expenses.removeWhere((expense) => expense.id == id);
    dbService?.deleteRecord('expenses', id);
    _persistAndNotify();
  }

  void clearAllData() {
    _expenses.clear();
    _persistAndNotify();
  }

  List<Expense> getExpensesByDateRange(DateTime from, DateTime to) {
    final start = _startOfDay(from);
    final end = _endOfDay(to);
    return _sortedByDateDesc(
      _expenses.where(
        (expense) =>
            !expense.date.isBefore(start) && !expense.date.isAfter(end),
      ),
    );
  }

  List<Expense> getExpensesByCategory(ExpenseCategory category) {
    return _sortedByDateDesc(
      _expenses.where((expense) => expense.category == category),
    );
  }

  List<Expense> getTodayExpenses() {
    final now = DateTime.now();
    return _sortedByDateDesc(
      _expenses.where((expense) => _isSameDay(expense.date, now)),
    );
  }

  List<Expense> getThisMonthExpenses() {
    final now = DateTime.now();
    return _sortedByDateDesc(
      _expenses.where(
        (expense) =>
            expense.date.year == now.year && expense.date.month == now.month,
      ),
    );
  }

  double getTotalByCategory(
    ExpenseCategory category,
    DateTime from,
    DateTime to,
  ) {
    return getExpensesByDateRange(from, to)
        .where((expense) => expense.category == category)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double getDailyTotal(DateTime date) {
    return _expenses
        .where((expense) => _isSameDay(expense.date, date))
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  double getMonthlyTotal(int month, int year) {
    return _expenses
        .where(
          (expense) => expense.date.month == month && expense.date.year == year,
        )
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  Map<ExpenseCategory, double> getCategoryBreakdown(
    DateTime from,
    DateTime to,
  ) {
    final result = <ExpenseCategory, double>{};
    for (final expense in getExpensesByDateRange(from, to)) {
      result.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return result;
  }

  List<Expense> getRecurringExpenses() {
    return _sortedByDateDesc(
      _expenses.where(
        (expense) => expense.isRecurring && expense.recurringFrequency != null,
      ),
    );
  }

  /// Returns recurring expenses due within [days] days from now.
  List<Expense> getUpcomingRecurring(int days) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    return getRecurringExpenses().where((expense) {
      final next = expense.nextDueDate;
      if (next == null) return false;
      return !next.isAfter(cutoff);
    }).toList();
  }

  /// Processes due recurring expenses where autoCreate is true.
  /// Creates new expense entries for each overdue occurrence.
  /// Returns the number of auto-created entries.
  int processDueRecurringExpenses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var createdCount = 0;

    final recurring = getRecurringExpenses()
        .where((e) => e.autoCreate)
        .toList();

    for (final template in recurring) {
      final nextDue = template.nextDueDate;
      if (nextDue == null) continue;

      final dueDay = DateTime(nextDue.year, nextDue.month, nextDue.day);
      if (dueDay.isAfter(today)) continue;

      // Check if we already created for this due date
      if (template.lastCreatedAt != null) {
        final lastDay = DateTime(
          template.lastCreatedAt!.year,
          template.lastCreatedAt!.month,
          template.lastCreatedAt!.day,
        );
        if (!lastDay.isBefore(dueDay)) continue;
      }

      // Create the auto-generated expense entry
      final autoExpense = Expense(
        amount: template.amount,
        category: template.category,
        customCategoryName: template.customCategoryName,
        customCategoryIconKey: template.customCategoryIconKey,
        description: template.description,
        date: nextDue,
        paymentMode: template.paymentMode,
        vendorName: template.vendorName,
        billReference: 'auto:${template.id}',
      );
      _expenses.add(autoExpense);

      // Update template's lastCreatedAt
      final index = _expenses.indexWhere((e) => e.id == template.id);
      if (index != -1) {
        _expenses[index] = template.copyWith(lastCreatedAt: now);
      }
      createdCount++;
    }

    if (createdCount > 0) {
      _persistAndNotify();
    }
    return createdCount;
  }

  List<Expense> searchExpenses(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return _sortedByDateDesc(_expenses);
    return _sortedByDateDesc(
      _expenses.where((expense) {
        final description = expense.description?.toLowerCase() ?? '';
        final vendor = expense.vendorName?.toLowerCase() ?? '';
        final category = expense.categoryLabel.toLowerCase();
        return description.contains(normalized) ||
            vendor.contains(normalized) ||
            category.contains(normalized);
      }),
    );
  }

  List<String> getVendorSuggestions(String query) {
    final normalized = query.trim().toLowerCase();
    final unique = <String>{};
    for (final expense in _expenses) {
      final vendor = expense.vendorName?.trim();
      if (vendor == null || vendor.isEmpty) continue;
      if (normalized.isEmpty || vendor.toLowerCase().contains(normalized)) {
        unique.add(vendor);
      }
    }
    final vendors = unique.toList()..sort();
    return vendors;
  }

  List<Expense> getFilteredExpenses({
    String query = '',
    ExpenseDateFilter dateFilter = ExpenseDateFilter.all,
    ExpenseCategory? category,
    ExpensePaymentMode? paymentMode,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    Iterable<Expense> filtered = _expenses;

    filtered = _applyDateFilter(
      filtered,
      dateFilter: dateFilter,
      customFrom: customFrom,
      customTo: customTo,
    );

    if (category != null) {
      filtered = filtered.where((expense) => expense.category == category);
    }

    if (paymentMode != null) {
      filtered = filtered.where(
        (expense) => expense.paymentMode == paymentMode,
      );
    }

    final normalized = query.trim().toLowerCase();
    if (normalized.isNotEmpty) {
      filtered = filtered.where((expense) {
        final description = expense.description?.toLowerCase() ?? '';
        final vendor = expense.vendorName?.toLowerCase() ?? '';
        final categoryText = expense.categoryLabel.toLowerCase();
        return description.contains(normalized) ||
            vendor.contains(normalized) ||
            categoryText.contains(normalized);
      });
    }

    return _sortedByDateDesc(filtered);
  }

  List<String> get customCategoryNames {
    final unique = <String>{};
    for (final expense in _expenses) {
      if (expense.category != ExpenseCategory.custom) continue;
      final name = expense.customCategoryName?.trim();
      if (name != null && name.isNotEmpty) unique.add(name);
    }
    final names = unique.toList()..sort();
    return names;
  }

  String? getCustomCategoryIcon(String categoryName) {
    for (final expense in _expenses.reversed) {
      if (expense.category != ExpenseCategory.custom) continue;
      if (expense.customCategoryName?.trim() == categoryName.trim()) {
        return expense.customCategoryIconKey;
      }
    }
    return null;
  }

  Iterable<Expense> _applyDateFilter(
    Iterable<Expense> source, {
    required ExpenseDateFilter dateFilter,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final now = DateTime.now();
    switch (dateFilter) {
      case ExpenseDateFilter.all:
        return source;
      case ExpenseDateFilter.today:
        return source.where((expense) => _isSameDay(expense.date, now));
      case ExpenseDateFilter.thisWeek:
        final start = _startOfDay(
          now.subtract(Duration(days: now.weekday - 1)),
        );
        final end = _endOfDay(start.add(const Duration(days: 6)));
        return source.where(
          (expense) =>
              !expense.date.isBefore(start) && !expense.date.isAfter(end),
        );
      case ExpenseDateFilter.thisMonth:
        return source.where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        );
      case ExpenseDateFilter.customRange:
        if (customFrom == null || customTo == null) return source;
        final start = _startOfDay(customFrom);
        final end = _endOfDay(customTo);
        return source.where(
          (expense) =>
              !expense.date.isBefore(start) && !expense.date.isAfter(end),
        );
    }
  }

  List<Expense> _sortedByDateDesc(Iterable<Expense> source) {
    final result = source.toList()..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }

  void _persistAndNotify() {
    _onChanged?.call();
    notifyListeners();
  }
}
