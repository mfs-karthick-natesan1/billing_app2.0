import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/services/gst_calculator.dart';
import 'helpers/test_fixtures.dart';

void main() {
  late ProductProvider productProvider;
  late BillProvider billProvider;
  late CustomerProvider customerProvider;

  setUp(() {
    productProvider = ProductProvider();
    billProvider = BillProvider();
    customerProvider = CustomerProvider();
  });

  group('Jewellery — High-Value GST', () {
    test('3% GST → CGST 1.5% + SGST 1.5%', () {
      final product = jewelleryProduct(
        name: 'Gold Ring 22KT',
        sellingPrice: 29500,
        gstRate: 3.0,
      );
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);
      expect(billProvider.activeLineItems.length, 1);
      expect(billProvider.activeLineItems.first.quantity, 1);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(amountReceived: 30385),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // taxable = 29500, CGST = 29500 * 1.5% = 442.50, SGST = 442.50
      expect(bill.cgst, 442.50);
      expect(bill.sgst, 442.50);
      expect(bill.grandTotal, 30385.00); // 29500 + 442.50 + 442.50
      expect(bill.igst, 0);
    });

    test('high-value bill GST rounding to 2 decimals', () {
      final product = jewelleryProduct(
        name: 'Gold Chain 22KT',
        sellingPrice: 59000,
        gstRate: 3.0,
      );
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(amountReceived: 60770),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Verify all amounts have at most 2 decimal places
      bool hasTwoDecimals(double amount) =>
          (amount * 100).round() / 100 == amount;

      expect(hasTwoDecimals(bill.cgst), isTrue,
          reason: 'CGST ${bill.cgst} should have at most 2 decimal places');
      expect(hasTwoDecimals(bill.sgst), isTrue,
          reason: 'SGST ${bill.sgst} should have at most 2 decimal places');
      expect(hasTwoDecimals(bill.grandTotal), isTrue,
          reason:
              'Grand total ${bill.grandTotal} should have at most 2 decimal places');
      expect(hasTwoDecimals(bill.subtotal), isTrue,
          reason:
              'Subtotal ${bill.subtotal} should have at most 2 decimal places');
    });

    test('inter-state → IGST 3% instead of CGST+SGST', () {
      final product = jewelleryProduct(
        name: 'Gold Necklace',
        sellingPrice: 29500,
        gstRate: 3.0,
      );
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(amountReceived: 30385),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
        isInterState: true,
      );

      // Inter-state: IGST = 29500 * 3% = 885.00
      expect(bill.igst, 885.00);
      expect(bill.cgst, 0);
      expect(bill.sgst, 0);
      expect(bill.grandTotal, 30385.00); // 29500 + 885
    });

    test('bill discount on jewellery → GST proportional reduction', () {
      final product = jewelleryProduct(
        name: 'Gold Bangle',
        sellingPrice: 29500,
        gstRate: 3.0,
      );
      productProvider.addProduct(product);

      billProvider.addItemToBill(product);

      // Apply a flat Rs 500 bill-level discount
      billProvider.setDiscount(isPercent: false, value: 500);
      expect(billProvider.discountAmount, 500);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(amountReceived: 30000),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Subtotal = 29500, after bill discount = 29000
      // Discount ratio = 29000 / 29500
      // Original CGST = 442.50, proportional CGST = 442.50 * (29000/29500)
      // Grand total = 29000 + proportional CGST + proportional SGST
      expect(bill.discount, 500);
      expect(bill.grandTotal, lessThan(30385.00));

      // Verify GST was proportionally reduced
      final fullCgst = 442.50;
      expect(bill.cgst, lessThan(fullCgst));
      expect(bill.sgst, lessThan(fullCgst));

      // Grand total should equal: discountedSubtotal + proportional GST
      final discountRatio = (29500 - 500) / 29500;
      final expectedCgst =
          GstCalculator.cgst(29500, 3.0) * discountRatio;
      final expectedSgst =
          GstCalculator.sgst(29500, 3.0) * discountRatio;
      final expectedTotal =
          (29500 - 500) + expectedCgst + expectedSgst;
      // Allow for rounding to 2 decimal places
      expect(bill.grandTotal, closeTo(expectedTotal, 0.01));
    });
  });
}
