import '../models/line_item.dart';

class GstCalculator {
  GstCalculator._();

  /// Taxable amount for a single item (reverse-calculates if GST-inclusive).
  static double taxableAmount(
    double price,
    double qty, {
    required bool inclusive,
    required double gstRate,
  }) {
    final lineTotal = price * qty;
    if (gstRate == 0) return lineTotal;
    if (inclusive) return lineTotal / (1 + gstRate / 100);
    return lineTotal;
  }

  /// CGST for a given taxable amount (half the GST rate).
  static double cgst(double taxableAmt, double gstRate) =>
      taxableAmt * (gstRate / 2) / 100;

  /// SGST for a given taxable amount (half the GST rate).
  static double sgst(double taxableAmt, double gstRate) =>
      taxableAmt * (gstRate / 2) / 100;

  /// IGST for a given taxable amount (full GST rate, inter-state).
  static double igst(double taxableAmt, double gstRate) =>
      taxableAmt * gstRate / 100;

  // ── Aggregate helpers (operate on line items) ──

  static double totalCgst(List<LineItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.cgstAmount);
  }

  static double totalSgst(List<LineItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.sgstAmount);
  }

  static double totalIgst(List<LineItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.igstAmount);
  }

  static double totalGst(List<LineItem> items, {bool isInterState = false}) {
    if (isInterState) return totalIgst(items);
    return totalCgst(items) + totalSgst(items);
  }

  static double totalTaxableAmount(List<LineItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.taxableAmount);
  }

  static double subtotal(List<LineItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Subtotal after all line-level discounts.
  static double discountedSubtotal(List<LineItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.discountedSubtotal);
  }

  static double grandTotal(
    List<LineItem> items, {
    double discount = 0,
    bool isInterState = false,
  }) {
    final sub = discountedSubtotal(items);
    final afterBillDiscount = sub - discount;
    if (afterBillDiscount <= 0) return 0;
    // GST is calculated on the discounted subtotal proportionally
    final gst = totalGst(items, isInterState: isInterState);
    final discountRatio = sub > 0 ? afterBillDiscount / sub : 0.0;
    return afterBillDiscount + gst * discountRatio;
  }
}
