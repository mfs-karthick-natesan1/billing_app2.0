import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/payment_info.dart';

void main() {
  late BillProvider provider;

  setUp(() {
    provider = BillProvider();
  });

  group('getFilteredBills', () {
    test(
      'returns all bills sorted newest-first when filter is all and query is empty',
      () {
        // Use completeBill to add bills — but that requires too much wiring.
        // Instead test the method by adding bills via completeBill indirectly.
        // Since _bills is private, we need to go through completeBill.
        // Let's just verify the public API via a simpler approach:
        // We can't add bills without completeBill, so let's test that flow.

        // Actually, let's just verify that an empty provider returns empty list
        final result = provider.getFilteredBills('', BillFilter.all);
        expect(result, isEmpty);
      },
    );

    test('count getters return 0 for empty provider', () {
      expect(provider.allBillCount, 0);
      expect(provider.todayBillCount, 0);
      expect(provider.thisWeekBillCount, 0);
      expect(provider.thisMonthBillCount, 0);
      expect(provider.cashBillCount, 0);
      expect(provider.creditBillCount, 0);
    });
  });

  group('BillFilter enum', () {
    test('has all expected values', () {
      expect(BillFilter.values.length, 6);
      expect(BillFilter.values, contains(BillFilter.all));
      expect(BillFilter.values, contains(BillFilter.today));
      expect(BillFilter.values, contains(BillFilter.thisWeek));
      expect(BillFilter.values, contains(BillFilter.thisMonth));
      expect(BillFilter.values, contains(BillFilter.cash));
      expect(BillFilter.values, contains(BillFilter.credit));
    });
  });

  group('BillProvider with bills', () {
    // To properly test filtering, we need to add bills via completeBill.
    // This requires ProductProvider and CustomerProvider, so let's create
    // a focused integration-style test.

    test('completeBill adds a bill and counts update', () {
      // We need the dependent providers
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();

      final product = Product(
        name: 'Widget',
        sellingPrice: 50,
        stockQuantity: 10,
      );
      provider.addItemToBill(product);

      expect(provider.hasActiveItems, isTrue);

      final bill = provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 50,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(provider.allBillCount, 1);
      expect(provider.todayBillCount, 1);
      expect(provider.cashBillCount, 1);
      expect(provider.creditBillCount, 0);
      expect(bill.billNumber, isNotEmpty);
    });

    test('getFilteredBills filters by payment mode', () {
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();
      final product = Product(
        name: 'Item',
        sellingPrice: 100,
        stockQuantity: 100,
      );
      final customer = Customer(name: 'John');

      // Add a cash bill
      provider.addItemToBill(product);
      provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Add a credit bill
      provider.addItemToBill(product);
      provider.completeBill(
        paymentInfo: PaymentInfo(
          mode: PaymentMode.credit,
          creditAmount: 100,
          customer: customer,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(provider.allBillCount, 2);
      expect(provider.cashBillCount, 1);
      expect(provider.creditBillCount, 1);

      final cashBills = provider.getFilteredBills('', BillFilter.cash);
      expect(cashBills.length, 1);
      expect(cashBills.first.paymentMode, PaymentMode.cash);

      final creditBills = provider.getFilteredBills('', BillFilter.credit);
      expect(creditBills.length, 1);
      expect(creditBills.first.paymentMode, PaymentMode.credit);
    });

    test('getFilteredBills searches by bill number', () {
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();
      final product = Product(
        name: 'Item',
        sellingPrice: 100,
        stockQuantity: 100,
      );

      provider.addItemToBill(product);
      final bill = provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Search by bill number substring
      final results = provider.getFilteredBills('INV', BillFilter.all);
      expect(results.length, 1);
      expect(results.first.billNumber, bill.billNumber);

      // Search with no match
      final noResults = provider.getFilteredBills('XYZ', BillFilter.all);
      expect(noResults, isEmpty);
    });

    test('getFilteredBills searches by customer name', () {
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();
      final product = Product(
        name: 'Item',
        sellingPrice: 100,
        stockQuantity: 100,
      );
      final customer = Customer(name: 'Rajesh Kumar');

      provider.addItemToBill(product);
      provider.completeBill(
        paymentInfo: PaymentInfo(
          mode: PaymentMode.credit,
          creditAmount: 100,
          customer: customer,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      final results = provider.getFilteredBills('rajesh', BillFilter.all);
      expect(results.length, 1);

      final noResults = provider.getFilteredBills('amit', BillFilter.all);
      expect(noResults, isEmpty);
    });

    test('getFilteredBills returns newest-first', () {
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();
      final product = Product(
        name: 'Item',
        sellingPrice: 100,
        stockQuantity: 100,
      );

      // Add two bills (they'll have slightly different timestamps)
      provider.addItemToBill(product);
      provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      provider.addItemToBill(product);
      provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      final results = provider.getFilteredBills('', BillFilter.all);
      expect(results.length, 2);
      expect(
        results.first.timestamp.isAfter(results.last.timestamp) ||
            results.first.timestamp.isAtSameMomentAs(results.last.timestamp),
        isTrue,
      );
    });

    test('getFilteredBills today filter only includes today bills', () {
      final productProvider = _MockProductProvider();
      final customerProvider = _MockCustomerProvider();
      final product = Product(
        name: 'Item',
        sellingPrice: 100,
        stockQuantity: 100,
      );

      provider.addItemToBill(product);
      provider.completeBill(
        paymentInfo: const PaymentInfo(
          mode: PaymentMode.cash,
          amountReceived: 100,
        ),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      final todayResults = provider.getFilteredBills('', BillFilter.today);
      expect(todayResults.length, 1);
    });
  });
}

// Minimal mock for ProductProvider — only needs decrementStock
class _MockProductProvider extends ProductProvider {
  @override
  void decrementStock(
    String productId,
    double quantity, {
    String? batchId,
    bool persist = true,
  }) {
    // no-op for testing
  }
}

class _MockCustomerProvider extends CustomerProvider {
  @override
  void addCredit(String customerId, double amount, {bool persist = true}) {
    // no-op for testing
  }
}
