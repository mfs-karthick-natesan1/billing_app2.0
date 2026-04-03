import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/models/expense.dart';
import 'package:billing_app/models/expense_category.dart';
import 'package:billing_app/providers/expense_provider.dart';
import 'package:billing_app/screens/expense_list_screen.dart';
import 'package:billing_app/widgets/add_expense_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _buildTestApp(ExpenseProvider provider) {
  return ChangeNotifierProvider<ExpenseProvider>.value(
    value: provider,
    child: const MaterialApp(home: ExpenseListScreen()),
  );
}

void main() {
  group('ExpenseListScreen', () {
    testWidgets('shows empty state when no expenses are present', (
      tester,
    ) async {
      final provider = ExpenseProvider();
      await tester.pumpWidget(_buildTestApp(provider));

      expect(find.text(AppStrings.expensesTitle), findsOneWidget);
      expect(find.text(AppStrings.noExpensesYet), findsOneWidget);
      expect(find.text(AppStrings.noExpensesDesc), findsOneWidget);
    });

    testWidgets('shows expense card and supports search filtering', (
      tester,
    ) async {
      final provider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'exp-1',
            amount: 540,
            category: ExpenseCategory.electricity,
            description: 'EB office bill',
            vendorName: 'EB Office',
            paymentMode: ExpensePaymentMode.cash,
            date: DateTime.now(),
          ),
        ],
      );

      await tester.pumpWidget(_buildTestApp(provider));

      expect(find.text(AppStrings.noExpensesYet), findsNothing);
      expect(find.textContaining('Electricity'), findsAtLeastNWidgets(1));

      await tester.enterText(find.byType(TextField).first, 'xyz');
      await tester.pump();
      expect(find.text(AppStrings.noExpensesFound), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'office');
      await tester.pump();
      expect(find.text(AppStrings.noExpensesFound), findsNothing);
    });

    testWidgets('fab opens add expense sheet', (tester) async {
      final provider = ExpenseProvider();
      await tester.pumpWidget(_buildTestApp(provider));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AddExpenseSheet), findsOneWidget);
      expect(find.text(AppStrings.addExpense), findsAtLeastNWidgets(1));
    });
  });
}
