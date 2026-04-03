import 'package:billing_app/constants/app_strings.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/cash_book_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/expense_provider.dart';
import 'package:billing_app/screens/cash_book_screen.dart';
import 'package:billing_app/widgets/cash_book_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _buildScreen(CashBookProvider provider) {
  return ChangeNotifierProvider<CashBookProvider>.value(
    value: provider,
    child: const MaterialApp(home: CashBookScreen()),
  );
}

void main() {
  group('CashBookScreen', () {
    testWidgets('renders core sections', (tester) async {
      final cashBookProvider = CashBookProvider(
        billProvider: BillProvider(),
        expenseProvider: ExpenseProvider(),
        customerProvider: CustomerProvider(),
      );

      await tester.pumpWidget(_buildScreen(cashBookProvider));

      expect(find.text(AppStrings.cashBookTitle), findsOneWidget);
      expect(find.text(AppStrings.openingBalance), findsOneWidget);
      expect(find.text(AppStrings.closingBalance), findsOneWidget);
      expect(find.text(AppStrings.closeDay), findsOneWidget);
    });

    testWidgets('opens cash entry sheet when tapping add cash in', (
      tester,
    ) async {
      final cashBookProvider = CashBookProvider(
        billProvider: BillProvider(),
        expenseProvider: ExpenseProvider(),
        customerProvider: CustomerProvider(),
      );

      await tester.pumpWidget(_buildScreen(cashBookProvider));

      await tester.tap(find.text(AppStrings.addCashIn));
      await tester.pumpAndSettle();

      expect(find.byType(CashBookEntrySheet), findsOneWidget);
      expect(find.text(AppStrings.addCashEntry), findsOneWidget);
    });
  });
}
