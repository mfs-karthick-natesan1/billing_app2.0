import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/expense.dart';
import 'package:billing_app/models/expense_category.dart';
import 'package:billing_app/providers/expense_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── Unit tests for Expense model new fields ──

  group('Expense autoCreate and lastCreatedAt fields', () {
    test('default autoCreate is false', () {
      final expense = Expense(
        amount: 500,
        category: ExpenseCategory.rent,
        paymentMode: ExpensePaymentMode.cash,
      );
      expect(expense.autoCreate, isFalse);
      expect(expense.lastCreatedAt, isNull);
    });

    test('copyWith updates autoCreate and lastCreatedAt', () {
      final expense = Expense(
        amount: 500,
        category: ExpenseCategory.rent,
        paymentMode: ExpensePaymentMode.cash,
      );
      final now = DateTime.now();
      final updated = expense.copyWith(autoCreate: true, lastCreatedAt: now);
      expect(updated.autoCreate, isTrue);
      expect(updated.lastCreatedAt, now);
    });

    test('clearLastCreatedAt resets to null', () {
      final now = DateTime.now();
      final expense = Expense(
        amount: 500,
        category: ExpenseCategory.rent,
        paymentMode: ExpensePaymentMode.cash,
        autoCreate: true,
        lastCreatedAt: now,
      );
      final cleared = expense.copyWith(clearLastCreatedAt: true);
      expect(cleared.lastCreatedAt, isNull);
      expect(cleared.autoCreate, isTrue); // unchanged
    });

    test('toJson includes autoCreate and lastCreatedAt', () {
      final now = DateTime(2026, 2, 20, 10, 30);
      final expense = Expense(
        amount: 100,
        category: ExpenseCategory.rent,
        paymentMode: ExpensePaymentMode.cash,
        autoCreate: true,
        lastCreatedAt: now,
      );
      final json = expense.toJson();
      expect(json['autoCreate'], isTrue);
      expect(json['lastCreatedAt'], now.toIso8601String());
    });

    test('fromJson parses autoCreate and lastCreatedAt', () {
      final json = {
        'amount': 100,
        'category': 'rent',
        'paymentMode': 'cash',
        'autoCreate': true,
        'lastCreatedAt': '2026-02-20T10:30:00.000',
      };
      final expense = Expense.fromJson(json);
      expect(expense.autoCreate, isTrue);
      expect(expense.lastCreatedAt, isNotNull);
      expect(expense.lastCreatedAt!.year, 2026);
    });

    test('fromJson defaults autoCreate to false when missing', () {
      final json = {
        'amount': 100,
        'category': 'rent',
        'paymentMode': 'cash',
      };
      final expense = Expense.fromJson(json);
      expect(expense.autoCreate, isFalse);
      expect(expense.lastCreatedAt, isNull);
    });

    test('toJson -> fromJson round trip', () {
      final now = DateTime(2026, 1, 15, 9, 0);
      final original = Expense(
        amount: 500,
        category: ExpenseCategory.rent,
        paymentMode: ExpensePaymentMode.cash,
        isRecurring: true,
        recurringFrequency: RecurringFrequency.monthly,
        autoCreate: true,
        lastCreatedAt: now,
      );
      final restored = Expense.fromJson(original.toJson());
      expect(restored.autoCreate, original.autoCreate);
      expect(
        restored.lastCreatedAt?.toIso8601String(),
        original.lastCreatedAt?.toIso8601String(),
      );
    });
  });

  // ── Unit tests for nextDueDate ──

  group('Expense nextDueDate', () {
    test('returns null for non-recurring expense', () {
      final expense = Expense(
        amount: 100,
        category: ExpenseCategory.rent,
        paymentMode: ExpensePaymentMode.cash,
      );
      expect(expense.nextDueDate, isNull);
    });

    test('returns today if due date is today', () {
      final today = DateTime.now();
      final expense = Expense(
        amount: 100,
        category: ExpenseCategory.rent,
        paymentMode: ExpensePaymentMode.cash,
        date: DateTime(today.year, today.month, today.day),
        isRecurring: true,
        recurringFrequency: RecurringFrequency.monthly,
      );
      final next = expense.nextDueDate;
      expect(next, isNotNull);
      expect(next!.day, today.day);
    });

    test('computes next monthly occurrence from past date', () {
      // A date well in the past
      final pastDate = DateTime(2025, 1, 15);
      final expense = Expense(
        amount: 100,
        category: ExpenseCategory.rent,
        paymentMode: ExpensePaymentMode.cash,
        date: pastDate,
        isRecurring: true,
        recurringFrequency: RecurringFrequency.monthly,
      );
      final next = expense.nextDueDate;
      expect(next, isNotNull);
      // Should be on the 15th of some future month
      expect(next!.day, 15);
      expect(
        next.isAfter(DateTime.now()) ||
            _isSameDay(next, DateTime.now()),
        isTrue,
      );
    });

    test('computes next weekly occurrence', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      final expense = Expense(
        amount: 50,
        category: ExpenseCategory.transport,
        paymentMode: ExpensePaymentMode.cash,
        date: pastDate,
        isRecurring: true,
        recurringFrequency: RecurringFrequency.weekly,
      );
      final next = expense.nextDueDate;
      expect(next, isNotNull);
      // Should be within 7 days from now
      final diff = next!.difference(DateTime.now()).inDays;
      expect(diff, lessThanOrEqualTo(7));
    });

    test('computes next daily occurrence', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final expense = Expense(
        amount: 25,
        category: ExpenseCategory.foodBeverage,
        paymentMode: ExpensePaymentMode.cash,
        date: yesterday,
        isRecurring: true,
        recurringFrequency: RecurringFrequency.daily,
      );
      final next = expense.nextDueDate;
      expect(next, isNotNull);
    });
  });

  // ── Unit tests for provider methods ──

  group('ExpenseProvider getUpcomingRecurring', () {
    test('returns expenses due within given days', () {
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'r1',
            amount: 500,
            category: ExpenseCategory.rent,
            paymentMode: ExpensePaymentMode.cash,
            date: DateTime.now().subtract(const Duration(days: 28)),
            isRecurring: true,
            recurringFrequency: RecurringFrequency.monthly,
          ),
          Expense(
            id: 'r2',
            amount: 100,
            category: ExpenseCategory.transport,
            paymentMode: ExpensePaymentMode.cash,
            date: DateTime.now().subtract(const Duration(days: 3)),
            isRecurring: true,
            recurringFrequency: RecurringFrequency.weekly,
          ),
          Expense(
            id: 'not-recurring',
            amount: 200,
            category: ExpenseCategory.maintenance,
            paymentMode: ExpensePaymentMode.cash,
          ),
        ],
      );
      final upcoming = provider.getUpcomingRecurring(7);
      // Both recurring expenses should have next due within 7 days
      expect(upcoming.length, 2);
    });

    test('excludes non-recurring expenses', () {
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'one-off',
            amount: 300,
            category: ExpenseCategory.equipment,
            paymentMode: ExpensePaymentMode.cash,
          ),
        ],
      );
      expect(provider.getUpcomingRecurring(30), isEmpty);
    });
  });

  group('ExpenseProvider processDueRecurringExpenses', () {
    test('creates entry for due autoCreate expense', () {
      // Use a date exactly 7 days ago with weekly frequency so nextDueDate is today
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'template-1',
            amount: 500,
            category: ExpenseCategory.rent,
            paymentMode: ExpensePaymentMode.cash,
            date: DateTime.now().subtract(const Duration(days: 7)),
            isRecurring: true,
            recurringFrequency: RecurringFrequency.weekly,
            autoCreate: true,
          ),
        ],
      );

      final created = provider.processDueRecurringExpenses();
      expect(created, 1);
      // Should now have 2 expenses: template + auto-created
      expect(provider.expenses.length, 2);

      // The auto-created expense should reference the template
      final autoExpense = provider.expenses.firstWhere(
        (e) => e.billReference == 'auto:template-1',
      );
      expect(autoExpense.amount, 500);
      expect(autoExpense.category, ExpenseCategory.rent);

      // Template should have lastCreatedAt set
      final template = provider.expenses.firstWhere(
        (e) => e.id == 'template-1',
      );
      expect(template.lastCreatedAt, isNotNull);
    });

    test('does not create for non-autoCreate expenses', () {
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'remind-only',
            amount: 200,
            category: ExpenseCategory.electricity,
            paymentMode: ExpensePaymentMode.cash,
            date: DateTime.now().subtract(const Duration(days: 7)),
            isRecurring: true,
            recurringFrequency: RecurringFrequency.weekly,
            autoCreate: false,
          ),
        ],
      );

      final created = provider.processDueRecurringExpenses();
      expect(created, 0);
      expect(provider.expenses.length, 1);
    });

    test('does not double-create if already processed today', () {
      final now = DateTime.now();
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'template-2',
            amount: 100,
            category: ExpenseCategory.salary,
            paymentMode: ExpensePaymentMode.cash,
            date: DateTime.now().subtract(const Duration(days: 7)),
            isRecurring: true,
            recurringFrequency: RecurringFrequency.weekly,
            autoCreate: true,
            lastCreatedAt: now,
          ),
        ],
      );

      final created = provider.processDueRecurringExpenses();
      expect(created, 0);
      expect(provider.expenses.length, 1);
    });

    test('does not create for future due dates', () {
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'future-template',
            amount: 300,
            category: ExpenseCategory.insurance,
            paymentMode: ExpensePaymentMode.cash,
            date: DateTime.now().add(const Duration(days: 5)),
            isRecurring: true,
            recurringFrequency: RecurringFrequency.monthly,
            autoCreate: true,
          ),
        ],
      );

      final created = provider.processDueRecurringExpenses();
      expect(created, 0);
      expect(provider.expenses.length, 1);
    });

    test('returns 0 when no recurring expenses exist', () {
      final provider = ExpenseProvider();
      final created = provider.processDueRecurringExpenses();
      expect(created, 0);
    });
  });

  // ── String constants ──

  group('Recurring expense strings exist', () {
    test('auto-create strings defined', () {
      expect(AppStrings.autoCreateExpense, isNotEmpty);
      expect(AppStrings.autoCreateDesc, isNotEmpty);
      expect(AppStrings.remindOnly, isNotEmpty);
      expect(AppStrings.nextDueLabel, isNotEmpty);
      expect(AppStrings.recurringDueThisWeek, isNotEmpty);
      expect(AppStrings.autoCreatedExpenses, isNotEmpty);
    });
  });
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
