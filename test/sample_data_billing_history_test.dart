import 'package:billing_app/constants/sample_data.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sample billing history includes 50 customers and 100 invoices', () {
    final seed = SampleData.generateBillingHistory(
      products: SampleData.products,
      businessType: BusinessType.general,
      customerCount: 50,
      invoiceCount: 100,
    );

    expect(seed.customers.length, 50);
    expect(seed.bills.length, 100);
    expect(seed.bills.every((bill) => bill.customer != null), isTrue);
  });

  test('sample invoices are generated within last three months', () {
    final seed = SampleData.generateBillingHistory(
      products: SampleData.products,
      businessType: BusinessType.general,
    );
    final now = DateTime.now();
    final threeMonthsStart = DateTime(now.year, now.month - 2, 1);

    final oldest = seed.bills
        .map((bill) => bill.timestamp)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final newest = seed.bills
        .map((bill) => bill.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    expect(oldest.isBefore(threeMonthsStart), isFalse);
    expect(newest.isAfter(now), isFalse);
  });

  test('credit outstanding totals align with generated customer balances', () {
    final seed = SampleData.generateBillingHistory(
      products: SampleData.products,
      businessType: BusinessType.general,
    );

    final billOutstanding = seed.bills.fold<double>(
      0,
      (sum, bill) => sum + bill.creditAmount,
    );
    final customerOutstanding = seed.customers.fold<double>(
      0,
      (sum, customer) => sum + customer.outstandingBalance,
    );

    expect((billOutstanding - customerOutstanding).abs() < 0.01, isTrue);
  });

  test('sample products include barcodes for scan-to-add flow', () {
    final products = SampleData.products;
    expect(products, isNotEmpty);
    expect(
      products.every((product) => (product.barcode ?? '').isNotEmpty),
      isTrue,
    );
  });
}
