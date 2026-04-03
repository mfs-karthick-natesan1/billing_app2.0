import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/cash_book_entry.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/customer_payment_entry.dart';
import 'package:billing_app/models/expense.dart';
import 'package:billing_app/models/expense_category.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/cash_book_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/expense_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CashBookProvider', () {
    test(
      'computes day totals from bills, settlements, expenses and manual entries',
      () {
        final targetDate = DateTime(2026, 2, 1, 10);
        final billProvider = BillProvider(
          initialBills: [
            Bill(
              id: 'b-cash',
              billNumber: '2025-26/INV-001',
              lineItems: [
                LineItem(product: Product(name: 'Rice', sellingPrice: 500)),
              ],
              subtotal: 500,
              grandTotal: 500,
              paymentMode: PaymentMode.cash,
              timestamp: targetDate,
            ),
            Bill(
              id: 'b-credit',
              billNumber: '2025-26/INV-002',
              lineItems: [
                LineItem(product: Product(name: 'Soap', sellingPrice: 100)),
              ],
              subtotal: 100,
              grandTotal: 100,
              paymentMode: PaymentMode.credit,
              timestamp: targetDate,
            ),
          ],
        );

        final customerProvider = CustomerProvider(
          initialCustomers: [Customer(id: 'c1', name: 'Arun')],
          initialPaymentEntries: [
            CustomerPaymentEntry(
              id: 'p1',
              customerId: 'c1',
              amount: 200,
              paymentMode: SettlementPaymentMode.cash,
              recordedAt: targetDate,
            ),
          ],
        );

        final expenseProvider = ExpenseProvider(
          initialExpenses: [
            Expense(
              id: 'e1',
              amount: 150,
              category: ExpenseCategory.transport,
              paymentMode: ExpensePaymentMode.cash,
              date: targetDate,
            ),
            Expense(
              id: 'e2',
              amount: 90,
              category: ExpenseCategory.transport,
              paymentMode: ExpensePaymentMode.upi,
              date: targetDate,
            ),
          ],
        );

        final cashBook = CashBookProvider(
          billProvider: billProvider,
          expenseProvider: expenseProvider,
          customerProvider: customerProvider,
        );

        cashBook.setOpeningBalance(targetDate, 1000);
        cashBook.addManualEntry(
          targetDate,
          CashBookManualEntry(
            amount: 50,
            description: 'Owner added',
            type: CashEntryType.cashIn,
          ),
        );
        cashBook.addManualEntry(
          targetDate,
          CashBookManualEntry(
            amount: 20,
            description: 'Petty cash',
            type: CashEntryType.cashOut,
          ),
        );

        final day = cashBook.getCashBookDay(targetDate);
        expect(day.openingBalance, 1000);
        expect(day.cashSales, 500);
        expect(day.cashReceived, 200);
        expect(day.cashExpenses, 150);
        expect(day.totalOtherCashIn, 50);
        expect(day.totalOtherCashOut, 20);
        expect(day.closingBalance, 1580);
      },
    );

    test('close day and reopen restrictions are enforced', () {
      final billProvider = BillProvider();
      final customerProvider = CustomerProvider();
      final expenseProvider = ExpenseProvider();
      final cashBook = CashBookProvider(
        billProvider: billProvider,
        expenseProvider: expenseProvider,
        customerProvider: customerProvider,
      );

      final day1 = DateTime(2026, 2, 2);
      final day2 = DateTime(2026, 2, 3);

      cashBook.setOpeningBalance(day1, 1000);
      cashBook.closeDay(day1);
      cashBook.closeDay(day2);

      expect(cashBook.getCashBookDay(day1).isClosed, isTrue);
      expect(cashBook.reopenDay(day1), isFalse);

      expect(cashBook.reopenDay(day2), isTrue);
      expect(cashBook.getCashBookDay(day2).isClosed, isFalse);
    });

    test('cascading recalculation updates subsequent day balances', () {
      final day1 = DateTime(2026, 1, 10);
      final day2 = DateTime(2026, 1, 11);

      final billProvider = BillProvider();
      final customerProvider = CustomerProvider();
      final expenseProvider = ExpenseProvider(
        initialExpenses: [
          Expense(
            id: 'd2-exp',
            amount: 100,
            category: ExpenseCategory.miscellaneous,
            paymentMode: ExpensePaymentMode.cash,
            date: day2,
          ),
        ],
      );

      final cashBook = CashBookProvider(
        billProvider: billProvider,
        expenseProvider: expenseProvider,
        customerProvider: customerProvider,
      );

      cashBook.setOpeningBalance(day1, 1000);
      expect(cashBook.getCashBookDay(day2).closingBalance, 900);

      expenseProvider.addExpense(
        Expense(
          id: 'd1-exp',
          amount: 50,
          category: ExpenseCategory.miscellaneous,
          paymentMode: ExpensePaymentMode.cash,
          date: day1,
        ),
      );

      final day1Book = cashBook.getCashBookDay(day1);
      final day2Book = cashBook.getCashBookDay(day2);
      expect(day1Book.closingBalance, 950);
      expect(day2Book.openingBalance, 950);
      expect(day2Book.closingBalance, 850);
    });
  });
}
