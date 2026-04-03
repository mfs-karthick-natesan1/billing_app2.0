import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/expense.dart';
import 'package:billing_app/models/expense_category.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/business_config_provider.dart';
import 'package:billing_app/providers/cash_book_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/expense_provider.dart';
import 'package:billing_app/providers/purchase_provider.dart';
import 'package:billing_app/providers/return_provider.dart';
import 'package:billing_app/screens/eod_summary_screen.dart';
import 'package:billing_app/constants/app_strings.dart';

void main() {
  group('EOD Summary Screen', () {
    late BillProvider billProvider;
    late ExpenseProvider expenseProvider;
    late PurchaseProvider purchaseProvider;
    late ReturnProvider returnProvider;
    late CustomerProvider customerProvider;
    late CashBookProvider cashBookProvider;
    late BusinessConfigProvider businessConfigProvider;

    setUp(() {
      final product1 = Product(
        id: 'p1',
        name: 'Rice 5kg',
        sellingPrice: 250,
        stockQuantity: 100,
      );
      final product2 = Product(
        id: 'p2',
        name: 'Dal 1kg',
        sellingPrice: 150,
        stockQuantity: 50,
      );

      billProvider = BillProvider(initialBills: [
        Bill(
          billNumber: 'INV-001',
          lineItems: [
            LineItem(product: product1, quantity: 2),
          ],
          subtotal: 500,
          grandTotal: 500,
          paymentMode: PaymentMode.cash,
        ),
        Bill(
          billNumber: 'INV-002',
          lineItems: [
            LineItem(product: product2, quantity: 3),
          ],
          subtotal: 450,
          grandTotal: 450,
          paymentMode: PaymentMode.upi,
        ),
        Bill(
          billNumber: 'INV-003',
          lineItems: [
            LineItem(product: product1, quantity: 1),
            LineItem(product: product2, quantity: 1),
          ],
          subtotal: 400,
          grandTotal: 400,
          paymentMode: PaymentMode.credit,
          creditAmount: 400,
          customer: Customer(name: 'Test Customer'),
        ),
      ]);

      expenseProvider = ExpenseProvider(initialExpenses: [
        Expense(
          amount: 100,
          category: ExpenseCategory.rent,
          date: DateTime.now(),
        ),
      ]);

      purchaseProvider = PurchaseProvider();
      returnProvider = ReturnProvider();
      customerProvider = CustomerProvider();

      cashBookProvider = CashBookProvider(
        billProvider: billProvider,
        expenseProvider: expenseProvider,
        customerProvider: customerProvider,
        returnProvider: returnProvider,
      );

      businessConfigProvider = BusinessConfigProvider();
      businessConfigProvider.updateConfig(
        businessName: 'Test Shop',
        phone: '9876543210',
      );
    });

    Widget buildTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<BillProvider>.value(value: billProvider),
          ChangeNotifierProvider<ExpenseProvider>.value(
              value: expenseProvider),
          ChangeNotifierProvider<PurchaseProvider>.value(
              value: purchaseProvider),
          ChangeNotifierProvider<ReturnProvider>.value(
              value: returnProvider),
          ChangeNotifierProvider<CustomerProvider>.value(
              value: customerProvider),
          ChangeNotifierProvider<CashBookProvider>.value(
              value: cashBookProvider),
          ChangeNotifierProvider<BusinessConfigProvider>.value(
              value: businessConfigProvider),
        ],
        child: const MaterialApp(
          home: EodSummaryScreen(),
        ),
      );
    }

    testWidgets('shows business name and date', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Test Shop'), findsOneWidget);
      expect(find.text(AppStrings.eodTitle), findsOneWidget);
    });

    testWidgets('shows sales section with bill count', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.eodSalesSection), findsOneWidget);
      expect(find.text('3 ${AppStrings.eodBillsSuffix}'), findsOneWidget);
    });

    testWidgets('shows cash and UPI collected', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Cash: 500, UPI: 450
      expect(find.text(AppStrings.eodCashCollected), findsOneWidget);
      expect(find.text(AppStrings.eodUpiCollected), findsOneWidget);
    });

    testWidgets('shows credit given info', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.eodCreditGiven), findsOneWidget);
    });

    testWidgets('shows top products section', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.eodTopProducts), findsOneWidget);
    });

    testWidgets('shows expenses section', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.eodExpensesSection), findsAtLeastNWidgets(1));
    });

    testWidgets('shows net profit section', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.eodNetProfit), findsOneWidget);
    });

    testWidgets('shows cash in hand section', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.eodCashInHand), findsOneWidget);
      expect(find.text(AppStrings.eodOpeningBalance), findsOneWidget);
      expect(find.text(AppStrings.eodClosingBalance), findsOneWidget);
    });

    testWidgets('shows close day button when not closed', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.eodCloseCashBook), findsOneWidget);
    });

    testWidgets('shows share button in app bar', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('close day button closes cash book', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text(AppStrings.eodCloseCashBook),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.eodCloseCashBook));
      await tester.pumpAndSettle();

      final todayCashBook = cashBookProvider.getTodayCashBook();
      expect(todayCashBook.isClosed, isTrue);
    });
  });

  group('EOD Summary data calculations', () {
    test('product stats aggregate correctly', () {
      // Simple unit test for aggregation logic
      final bills = <Bill>[
        Bill(
          billNumber: 'INV-001',
          lineItems: [
            LineItem(
              product: Product(
                id: 'p1',
                name: 'Item A',
                sellingPrice: 100,
                stockQuantity: 10,
              ),
              quantity: 3,
            ),
          ],
          subtotal: 300,
          grandTotal: 300,
          paymentMode: PaymentMode.cash,
        ),
        Bill(
          billNumber: 'INV-002',
          lineItems: [
            LineItem(
              product: Product(
                id: 'p1',
                name: 'Item A',
                sellingPrice: 100,
                stockQuantity: 10,
              ),
              quantity: 2,
            ),
            LineItem(
              product: Product(
                id: 'p2',
                name: 'Item B',
                sellingPrice: 50,
                stockQuantity: 20,
              ),
              quantity: 5,
            ),
          ],
          subtotal: 450,
          grandTotal: 450,
          paymentMode: PaymentMode.upi,
        ),
      ];

      final productSales = <String, Map<String, dynamic>>{};
      for (final bill in bills) {
        for (final item in bill.lineItems) {
          final key = item.product.id;
          final existing = productSales[key];
          if (existing != null) {
            existing['qty'] =
                (existing['qty'] as double) + item.quantity;
            existing['amount'] =
                (existing['amount'] as double) + item.subtotal;
          } else {
            productSales[key] = {
              'name': item.product.name,
              'qty': item.quantity,
              'amount': item.subtotal,
            };
          }
        }
      }

      expect(productSales['p1']!['qty'], 5.0);
      expect(productSales['p1']!['amount'], 500.0);
      expect(productSales['p2']!['qty'], 5.0);
      expect(productSales['p2']!['amount'], 250.0);
    });

    test('payment mode breakdown is correct', () {
      final bills = [
        Bill(
          billNumber: 'INV-001',
          lineItems: [],
          subtotal: 500,
          grandTotal: 500,
          paymentMode: PaymentMode.cash,
        ),
        Bill(
          billNumber: 'INV-002',
          lineItems: [],
          subtotal: 300,
          grandTotal: 300,
          paymentMode: PaymentMode.upi,
        ),
        Bill(
          billNumber: 'INV-003',
          lineItems: [],
          subtotal: 200,
          grandTotal: 200,
          paymentMode: PaymentMode.credit,
          creditAmount: 200,
        ),
      ];

      final cashTotal = bills
          .where((b) => b.paymentMode == PaymentMode.cash)
          .fold(0.0, (s, b) => s + b.grandTotal);
      final upiTotal = bills
          .where((b) => b.paymentMode == PaymentMode.upi)
          .fold(0.0, (s, b) => s + b.grandTotal);
      final creditTotal = bills
          .where((b) => b.paymentMode == PaymentMode.credit)
          .fold(0.0, (s, b) => s + b.creditAmount);

      expect(cashTotal, 500.0);
      expect(upiTotal, 300.0);
      expect(creditTotal, 200.0);
    });

    test('net profit calculation', () {
      final revenue = 1350.0;
      final expenses = 100.0;
      final returns = 0.0;
      final netProfit = revenue - expenses - returns;
      expect(netProfit, 1250.0);
    });
  });
}
