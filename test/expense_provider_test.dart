import 'package:billing_app/models/expense.dart';
import 'package:billing_app/models/expense_category.dart';
import 'package:billing_app/providers/expense_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseProvider', () {
    test('add/update/delete expense', () {
      final provider = ExpenseProvider();
      final expense = Expense(
        id: 'exp-1',
        amount: 1200,
        category: ExpenseCategory.rent,
        description: 'Shop rent',
      );

      provider.addExpense(expense);
      expect(provider.expenses.length, 1);

      provider.updateExpense(
        expense.copyWith(amount: 1500, description: 'Updated rent'),
      );
      expect(provider.expenses.single.amount, 1500);
      expect(provider.expenses.single.description, 'Updated rent');

      provider.deleteExpense('exp-1');
      expect(provider.expenses, isEmpty);
    });

    test('today and this month totals are computed correctly', () {
      final now = DateTime.now();
      final lastMonth = DateTime(
        now.year,
        now.month == 1 ? 12 : now.month - 1,
        10,
      );

      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'exp-today',
            amount: 500,
            category: ExpenseCategory.electricity,
            date: now,
          ),
          Expense(
            id: 'exp-month',
            amount: 300,
            category: ExpenseCategory.transport,
            date: DateTime(now.year, now.month, 1),
          ),
          Expense(
            id: 'exp-old',
            amount: 900,
            category: ExpenseCategory.rent,
            date: lastMonth,
          ),
        ],
      );

      expect(provider.todayTotal, 500);
      expect(provider.thisMonthTotal, 800);
      expect(provider.getTodayExpenses().length, 1);
      expect(provider.getThisMonthExpenses().length, 2);
    });

    test('date range and category breakdown work', () {
      final from = DateTime(2026, 1, 1);
      final to = DateTime(2026, 1, 31);
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'e1',
            amount: 100,
            category: ExpenseCategory.salary,
            date: DateTime(2026, 1, 5),
          ),
          Expense(
            id: 'e2',
            amount: 250,
            category: ExpenseCategory.salary,
            date: DateTime(2026, 1, 6),
          ),
          Expense(
            id: 'e3',
            amount: 180,
            category: ExpenseCategory.transport,
            date: DateTime(2026, 1, 9),
          ),
          Expense(
            id: 'e4',
            amount: 999,
            category: ExpenseCategory.salary,
            date: DateTime(2026, 2, 1),
          ),
        ],
      );

      final rangeExpenses = provider.getExpensesByDateRange(from, to);
      expect(rangeExpenses.length, 3);

      final breakdown = provider.getCategoryBreakdown(from, to);
      expect(breakdown[ExpenseCategory.salary], 350);
      expect(breakdown[ExpenseCategory.transport], 180);
      expect(
        provider.getTotalByCategory(ExpenseCategory.salary, from, to),
        350,
      );
    });

    test('search and combined filters work together', () {
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 's1',
            amount: 120,
            category: ExpenseCategory.packaging,
            description: 'Carry bags',
            vendorName: 'ABC Packaging',
            paymentMode: ExpensePaymentMode.upi,
            date: DateTime.now(),
          ),
          Expense(
            id: 's2',
            amount: 220,
            category: ExpenseCategory.electricity,
            description: 'EB office payment',
            vendorName: 'EB Office',
            paymentMode: ExpensePaymentMode.cash,
            date: DateTime.now(),
          ),
        ],
      );

      expect(provider.searchExpenses('bags').length, 1);
      expect(provider.searchExpenses('office').length, 1);
      expect(provider.getVendorSuggestions('ab'), ['ABC Packaging']);

      final filtered = provider.getFilteredExpenses(
        query: 'payment',
        paymentMode: ExpensePaymentMode.cash,
        dateFilter: ExpenseDateFilter.today,
      );
      expect(filtered.length, 1);
      expect(filtered.single.id, 's2');
    });

    test('custom category names are collected from expenses', () {
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'c1',
            amount: 99,
            category: ExpenseCategory.custom,
            customCategoryName: 'Cleaning',
            customCategoryIconKey: 'cleaning',
          ),
          Expense(
            id: 'c2',
            amount: 120,
            category: ExpenseCategory.custom,
            customCategoryName: 'Cleaning',
            customCategoryIconKey: 'cleaning',
          ),
          Expense(
            id: 'c3',
            amount: 20,
            category: ExpenseCategory.custom,
            customCategoryName: 'Tips',
            customCategoryIconKey: 'payments',
          ),
        ],
      );

      expect(provider.customCategoryNames, ['Cleaning', 'Tips']);
      expect(provider.getCustomCategoryIcon('Tips'), 'payments');
    });
  });
}
