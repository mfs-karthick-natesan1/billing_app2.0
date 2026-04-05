import 'package:billing_app/widgets/bill_total_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildFooter({
  double subtotal = 1000,
  double lineDiscount = 0,
  double discount = 0,
  double cgst = 0,
  double sgst = 0,
  double igst = 0,
  double grandTotal = 1000,
  bool gstEnabled = false,
  bool isInterState = false,
  bool hasItems = true,
  bool discountIsPercent = true,
  double discountValue = 0,
  VoidCallback? onProceed,
  void Function({required bool isPercent, required double value})? onDiscountChanged,
  VoidCallback? onClearDiscount,
  String? buttonLabel,
}) {
  return MaterialApp(
    home: Scaffold(
      body: BillTotalFooter(
        subtotal: subtotal,
        lineDiscount: lineDiscount,
        discount: discount,
        cgst: cgst,
        sgst: sgst,
        igst: igst,
        grandTotal: grandTotal,
        gstEnabled: gstEnabled,
        isInterState: isInterState,
        hasItems: hasItems,
        discountIsPercent: discountIsPercent,
        discountValue: discountValue,
        onProceedToPayment: onProceed ?? () {},
        onDiscountChanged:
            onDiscountChanged ?? ({required isPercent, required value}) {},
        onClearDiscount: onClearDiscount ?? () {},
        buttonLabel: buttonLabel,
      ),
    ),
  );
}

void main() {
  group('BillTotalFooter — display', () {
    testWidgets('shows subtotal and grand total', (tester) async {
      await tester.pumpWidget(_buildFooter(subtotal: 500, grandTotal: 500));

      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Grand Total'), findsOneWidget);
      expect(find.textContaining('500'), findsWidgets);
    });

    testWidgets('shows CGST and SGST rows when GST enabled', (tester) async {
      await tester.pumpWidget(
        _buildFooter(
          subtotal: 1000,
          cgst: 90,
          sgst: 90,
          grandTotal: 1180,
          gstEnabled: true,
        ),
      );

      expect(find.text('CGST'), findsOneWidget);
      expect(find.text('SGST'), findsOneWidget);
      expect(find.text('IGST'), findsNothing);
    });

    testWidgets('shows IGST row for inter-state when GST enabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildFooter(
          subtotal: 1000,
          igst: 180,
          grandTotal: 1180,
          gstEnabled: true,
          isInterState: true,
        ),
      );

      expect(find.text('IGST'), findsOneWidget);
      expect(find.text('CGST'), findsNothing);
      expect(find.text('SGST'), findsNothing);
    });

    testWidgets('hides CGST/SGST rows when GST disabled', (tester) async {
      await tester.pumpWidget(
        _buildFooter(
          subtotal: 1000,
          cgst: 90,
          sgst: 90,
          grandTotal: 1000,
          gstEnabled: false,
        ),
      );

      expect(find.text('CGST'), findsNothing);
      expect(find.text('SGST'), findsNothing);
    });

    testWidgets('shows line discount row when lineDiscount > 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildFooter(subtotal: 500, lineDiscount: 50, grandTotal: 450),
      );

      expect(find.text('Line Discounts'), findsOneWidget);
    });

    testWidgets('hides line discount row when lineDiscount == 0', (
      tester,
    ) async {
      await tester.pumpWidget(_buildFooter(subtotal: 500, grandTotal: 500));

      expect(find.text('Line Discounts'), findsNothing);
    });

    testWidgets('custom button label shown', (tester) async {
      await tester.pumpWidget(
        _buildFooter(buttonLabel: 'Save Quotation'),
      );

      expect(find.text('Save Quotation'), findsOneWidget);
      expect(find.text('Proceed to Payment'), findsNothing);
    });

    testWidgets('default button label is Proceed to Payment', (tester) async {
      await tester.pumpWidget(_buildFooter());

      expect(find.text('Proceed to Payment'), findsOneWidget);
    });
  });

  group('BillTotalFooter — proceed button', () {
    testWidgets('button enabled when hasItems=true', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildFooter(hasItems: true, onProceed: () => tapped = true),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byType(ElevatedButton).first);
      expect(tapped, isTrue);
    });

    testWidgets('button disabled when hasItems=false', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _buildFooter(hasItems: false, onProceed: () => tapped = true),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton).first,
      );
      expect(button.onPressed, isNull);
      expect(tapped, isFalse);
    });
  });

  group('BillTotalFooter — discount interaction', () {
    testWidgets('Add Discount button appears when no discount set', (
      tester,
    ) async {
      await tester.pumpWidget(_buildFooter(discount: 0, discountValue: 0));

      expect(find.text('Add Discount'), findsOneWidget);
    });

    testWidgets('tapping Add Discount shows discount input field', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildFooter(discount: 0, discountValue: 0),
      );

      await tester.tap(find.text('Add Discount'));
      await tester.pump();

      // % and Rs. toggle chips appear
      expect(find.text('%'), findsOneWidget);
      expect(find.text('Rs.'), findsOneWidget);
    });

    testWidgets('discount field hidden when discountValue > 0 on init', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildFooter(
          discount: 100,
          discountValue: 100,
          discountIsPercent: false,
          grandTotal: 900,
        ),
      );

      // Add Discount button should NOT show when discount already applied
      expect(find.text('Add Discount'), findsNothing);
      // Discount row shows
      expect(find.text('Discount'), findsOneWidget);
    });

    testWidgets('clearing discount calls onClearDiscount', (tester) async {
      var cleared = false;
      await tester.pumpWidget(
        _buildFooter(
          discount: 0,
          discountValue: 0,
          onClearDiscount: () => cleared = true,
        ),
      );

      // Open discount field first
      await tester.tap(find.text('Add Discount'));
      await tester.pump();

      // Tap the close icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(cleared, isTrue);
    });

    testWidgets('toggling % → Rs. switches discount type', (tester) async {
      bool? lastIsPercent;
      await tester.pumpWidget(
        _buildFooter(
          discount: 0,
          discountValue: 0,
          onDiscountChanged:
              ({required isPercent, required value}) =>
                  lastIsPercent = isPercent,
        ),
      );

      await tester.tap(find.text('Add Discount'));
      await tester.pump();

      // Default is %, tap Rs. toggle
      await tester.tap(find.text('Rs.'));
      await tester.pump();

      expect(lastIsPercent, isFalse);
    });
  });
}
