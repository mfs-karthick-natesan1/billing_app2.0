import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/quotation.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/quotation_provider.dart';
import 'package:billing_app/services/gst_calculator.dart';
import 'helpers/test_fixtures.dart';

void main() {
  group('Payment Modes', () {
    late BillProvider billProvider;
    late ProductProvider productProvider;
    late CustomerProvider customerProvider;

    setUp(() {
      billProvider = BillProvider();
      productProvider = ProductProvider();
      customerProvider = CustomerProvider();
    });

    test('cash payment — bill created, no credit', () {
      final product = generalProduct(sellingPrice: 500, stockQuantity: 20, gstRate: 0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(amountReceived: 500),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(bill.paymentMode, equals(PaymentMode.cash));
      expect(bill.creditAmount, equals(0));
      expect(bill.grandTotal, equals(500));
    });

    test('credit payment → customer outstandingBalance updated', () {
      final product = generalProduct(sellingPrice: 1000, stockQuantity: 10, gstRate: 0);
      final customer = testCustomer();
      productProvider.addProduct(product);
      final customerProvider = CustomerProvider(initialCustomers: [customer]);

      billProvider.addItemToBill(product);
      final bill = billProvider.completeBill(
        paymentInfo: creditPayment(customer: customer, creditAmount: 1000),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(bill.paymentMode, equals(PaymentMode.credit));
      expect(bill.creditAmount, equals(1000));
      expect(customerProvider.customers.first.outstandingBalance, equals(1000));
    });

    test('UPI payment — bill created, no credit', () {
      final product = generalProduct(sellingPrice: 300, stockQuantity: 10, gstRate: 0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      final bill = billProvider.completeBill(
        paymentInfo: upiPayment(amountReceived: 300),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(bill.paymentMode, equals(PaymentMode.upi));
      expect(bill.creditAmount, equals(0));
      expect(bill.grandTotal, equals(300));
    });

    test('split payment — splitCash + splitUpi amounts preserved', () {
      final product = generalProduct(sellingPrice: 1000, stockQuantity: 10, gstRate: 0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      final bill = billProvider.completeBill(
        paymentInfo: splitPayment(cashAmount: 600, upiAmount: 400, amountReceived: 1000),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(bill.paymentMode, equals(PaymentMode.split));
      expect(bill.splitCashAmount, equals(600));
      expect(bill.splitUpiAmount, equals(400));
      expect(bill.grandTotal, equals(1000));
    });
  });

  group('GST Rounding — Issue #11', () {
    late BillProvider billProvider;
    late ProductProvider productProvider;
    late CustomerProvider customerProvider;

    setUp(() {
      billProvider = BillProvider();
      productProvider = ProductProvider();
      customerProvider = CustomerProvider();
    });

    test('all amounts rounded to 2 decimal places', () {
      // Rs 99.99 * 7 = 699.93, GST 18%
      final product = generalProduct(sellingPrice: 99.99, stockQuantity: 50, gstRate: 18.0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      billProvider.updateQuantity(0, 7);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Verify no floating point drift: rounding to 2 decimals should be idempotent
      expect((bill.cgst * 100).round() / 100, equals(bill.cgst));
      expect((bill.sgst * 100).round() / 100, equals(bill.sgst));
      expect((bill.grandTotal * 100).round() / 100, equals(bill.grandTotal));
    });

    test('GST-inclusive pricing reverse calculation', () {
      // Selling price = 118 (inclusive of 18% GST), so taxable = 100
      final product = generalProduct(
        sellingPrice: 118,
        stockQuantity: 10,
        gstRate: 18.0,
      );
      // Create a product with gstInclusivePrice=true
      final inclusiveProduct = Product(
        name: 'Inclusive Item',
        sellingPrice: 118,
        stockQuantity: 10,
        gstRate: 18.0,
        gstInclusivePrice: true,
      );

      final item = LineItem(product: inclusiveProduct);
      // taxableAmount should reverse-calculate: 118 / 1.18 = 100
      expect(item.taxableAmount, closeTo(100.0, 0.02));
    });

    test('inter-state IGST replaces CGST+SGST', () {
      final product = generalProduct(sellingPrice: 1000, stockQuantity: 10, gstRate: 18.0);
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        isInterState: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Inter-state: CGST and SGST should be 0, IGST = 18% of 1000 = 180
      expect(bill.cgst, equals(0));
      expect(bill.sgst, equals(0));
      expect(bill.igst, closeTo(180.0, 0.02));
      expect(bill.grandTotal, closeTo(1180.0, 0.02));
    });
  });

  group('Bill Number Sequencing', () {
    test('sequential bill numbers with prefix', () {
      final productProvider = ProductProvider();
      final customerProvider = CustomerProvider();
      final bp = BillProvider();

      final product = generalProduct(stockQuantity: 100, gstRate: 0);
      productProvider.addProduct(product);

      // Create 3 bills
      for (var i = 0; i < 3; i++) {
        bp.addItemToBill(product);
        bp.completeBill(
          paymentInfo: cashPayment(),
          gstEnabled: false,
          productProvider: productProvider,
          customerProvider: customerProvider,
        );
      }

      expect(bp.bills.length, equals(3));
      // Bill numbers now include financial year prefix: FY/INV-NNN
      expect(bp.bills[0].billNumber, matches(RegExp(r'^\d{4}-\d{2}/INV-001$')));
      expect(bp.bills[1].billNumber, matches(RegExp(r'^\d{4}-\d{2}/INV-002$')));
      expect(bp.bills[2].billNumber, matches(RegExp(r'^\d{4}-\d{2}/INV-003$')));
    });

    test('hydrate from existing bills preserves sequence', () {
      final product = generalProduct(stockQuantity: 100, gstRate: 0);

      // Determine current FY to use in existing bill number
      final now = DateTime.now();
      final fyStart = now.month >= 4 ? now.year : now.year - 1;
      final fyLabel = '$fyStart-${(fyStart + 1).toString().substring(2)}';

      // Create a Bill with FY-prefixed billNumber as initialBills
      final existingBill = Bill(
        billNumber: '$fyLabel/INV-005',
        lineItems: [LineItem(product: product)],
        subtotal: 250,
        grandTotal: 250,
        paymentMode: PaymentMode.cash,
      );

      final productProvider = ProductProvider(initialProducts: [product]);
      final customerProvider = CustomerProvider();
      final bp = BillProvider(initialBills: [existingBill]);

      expect(bp.bills.length, equals(1));

      // Create a new bill — should be INV-006 within the same FY
      bp.addItemToBill(product);
      final newBill = bp.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: false,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(newBill.billNumber, equals('$fyLabel/INV-006'));
    });
  });

  group('Quotation → Bill Conversion', () {
    late QuotationProvider quotationProvider;

    setUp(() {
      quotationProvider = QuotationProvider();
    });

    test('approved quotation converts to bill with correct amounts', () {
      final product = generalProduct(sellingPrice: 500, stockQuantity: 20, gstRate: 18.0);
      final items = [LineItem(product: product, quantity: 2)];

      final quotation = testQuotation(
        quotationNumber: 'QUO-001',
        items: items,
        status: QuotationStatus.draft,
      );

      quotationProvider.addQuotation(quotation);

      // Approve the quotation
      quotationProvider.updateStatus(quotation.id, QuotationStatus.approved);
      expect(quotationProvider.quotations.first.status, equals(QuotationStatus.approved));

      // Convert to bill
      final bill = quotationProvider.convertToBill(quotation.id);
      expect(bill, isNotNull);
      expect(bill!.subtotal, equals(quotation.subtotal));
      expect(bill.grandTotal, equals(quotation.grandTotal));
      expect(bill.cgst, equals(quotation.cgst));
      expect(bill.sgst, equals(quotation.sgst));
    });

    test('non-approved quotation cannot convert (returns null)', () {
      final product = generalProduct(sellingPrice: 500, stockQuantity: 20, gstRate: 18.0);
      final items = [LineItem(product: product)];

      final quotation = testQuotation(
        quotationNumber: 'QUO-001',
        items: items,
        status: QuotationStatus.draft,
      );

      quotationProvider.addQuotation(quotation);

      // Try to convert draft quotation — should return null
      final bill = quotationProvider.convertToBill(quotation.id);
      expect(bill, isNull);
    });

    test('converted quotation status updated to converted', () {
      final product = generalProduct(sellingPrice: 500, stockQuantity: 20, gstRate: 18.0);
      final items = [LineItem(product: product)];

      final quotation = testQuotation(
        quotationNumber: 'QUO-001',
        items: items,
        status: QuotationStatus.draft,
      );

      quotationProvider.addQuotation(quotation);
      quotationProvider.updateStatus(quotation.id, QuotationStatus.approved);

      final bill = quotationProvider.convertToBill(quotation.id);
      expect(bill, isNotNull);

      // Quotation status should now be converted
      expect(
        quotationProvider.quotations.first.status,
        equals(QuotationStatus.converted),
      );
    });
  });
}
