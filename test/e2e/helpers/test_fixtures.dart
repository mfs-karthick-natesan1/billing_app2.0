import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/product_batch.dart';
import 'package:billing_app/models/purchase_entry.dart';
import 'package:billing_app/models/purchase_line_item.dart';
import 'package:billing_app/models/quotation.dart';
import 'package:billing_app/models/return_line_item.dart';
import 'package:billing_app/models/sales_return.dart';
import 'package:billing_app/services/gst_calculator.dart';

// ── Product Fixtures ────────────────────────────────────────────────────────

Product generalProduct({
  String? id,
  String name = 'Rice 5kg',
  double sellingPrice = 250,
  int stockQuantity = 50,
  double gstRate = 5.0,
  double costPrice = 200,
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    gstRate: gstRate,
    costPrice: costPrice,
  );
}

Product pharmacyProduct({
  String? id,
  String name = 'Paracetamol 500mg',
  double sellingPrice = 30,
  int stockQuantity = 0,
  double gstRate = 12.0,
  List<ProductBatch>? batches,
}) {
  final pid = id ?? 'pharma-${DateTime.now().microsecondsSinceEpoch}';
  final defaultBatches = batches ??
      [
        ProductBatch(
          productId: pid,
          batchNumber: 'BN-001',
          expiryDate: DateTime.now().add(const Duration(days: 30)),
          stockQuantity: 20,
        ),
        ProductBatch(
          productId: pid,
          batchNumber: 'BN-002',
          expiryDate: DateTime.now().add(const Duration(days: 180)),
          stockQuantity: 30,
        ),
      ];
  return Product(
    id: pid,
    name: name,
    sellingPrice: sellingPrice,
    stockQuantity: defaultBatches.fold(0, (s, b) => s + b.stockQuantity),
    gstRate: gstRate,
    batches: defaultBatches,
  );
}

Product clinicService({
  String? id,
  String name = 'General Consultation',
  double sellingPrice = 500,
  double gstRate = 18.0,
  int durationMinutes = 15,
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    gstRate: gstRate,
    isService: true,
    durationMinutes: durationMinutes,
  );
}

Product clinicSupply({
  String? id,
  String name = 'Bandage Roll',
  double sellingPrice = 50,
  int stockQuantity = 100,
  double gstRate = 12.0,
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    gstRate: gstRate,
  );
}

Product salonService({
  String? id,
  String name = 'Haircut',
  double sellingPrice = 200,
  double gstRate = 18.0,
  int durationMinutes = 30,
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    gstRate: gstRate,
    isService: true,
    durationMinutes: durationMinutes,
  );
}

Product salonRetailProduct({
  String? id,
  String name = 'Shampoo',
  double sellingPrice = 350,
  int stockQuantity = 25,
  double gstRate = 18.0,
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    gstRate: gstRate,
  );
}

Product jewelleryProduct({
  String? id,
  String name = 'Gold Ring 22KT',
  double sellingPrice = 29500,
  int stockQuantity = 10,
  double gstRate = 3.0,
  String unit = 'g',
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    gstRate: gstRate,
    unit: unit,
    hsnCode: '7113',
  );
}

Product restaurantProduct({
  String? id,
  String name = 'Paneer Tikka',
  double sellingPrice = 220,
  int stockQuantity = 999,
  double gstRate = 5.0,
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    gstRate: gstRate,
  );
}

Product workshopPart({
  String? id,
  String name = 'Engine Oil 1L',
  double sellingPrice = 420,
  int stockQuantity = 40,
  double gstRate = 18.0,
  double costPrice = 320,
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    gstRate: gstRate,
    costPrice: costPrice,
  );
}

Product workshopLabor({
  String? id,
  String name = 'Full Service',
  double sellingPrice = 800,
  double gstRate = 18.0,
  int durationMinutes = 120,
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    gstRate: gstRate,
    isService: true,
    durationMinutes: durationMinutes,
  );
}

Product mobileShopPhone({
  String? id,
  String name = 'Samsung Galaxy M34',
  double sellingPrice = 15999,
  int stockQuantity = 5,
  double gstRate = 18.0,
  bool trackSerialNumbers = true,
}) {
  return Product(
    id: id,
    name: name,
    sellingPrice: sellingPrice,
    stockQuantity: stockQuantity,
    gstRate: gstRate,
    trackSerialNumbers: trackSerialNumbers,
  );
}

// ── Customer Fixtures ───────────────────────────────────────────────────────

Customer testCustomer({
  String? id,
  String name = 'Rahul Sharma',
  String? phone,
  double defaultDiscountPercent = 0,
}) {
  return Customer(
    id: id,
    name: name,
    phone: phone ?? '9876543210',
    defaultDiscountPercent: defaultDiscountPercent,
  );
}

// ── LineItem Helpers ────────────────────────────────────────────────────────

LineItem lineItem(
  Product product, {
  double qty = 1,
  ProductBatch? batch,
  double discountPercent = 0,
}) {
  return LineItem(
    product: product,
    quantity: qty,
    batch: batch,
    discountPercent: discountPercent,
  );
}

// ── Payment Helpers ─────────────────────────────────────────────────────────

PaymentInfo cashPayment({double amountReceived = 0}) {
  return PaymentInfo(mode: PaymentMode.cash, amountReceived: amountReceived);
}

PaymentInfo creditPayment({required Customer customer, required double creditAmount}) {
  return PaymentInfo(
    mode: PaymentMode.credit,
    creditAmount: creditAmount,
    customer: customer,
  );
}

PaymentInfo splitPayment({
  required double cashAmount,
  required double upiAmount,
  double amountReceived = 0,
}) {
  return PaymentInfo(
    mode: PaymentMode.split,
    amountReceived: amountReceived,
    splitCashAmount: cashAmount,
    splitUpiAmount: upiAmount,
  );
}

PaymentInfo upiPayment({double amountReceived = 0}) {
  return PaymentInfo(mode: PaymentMode.upi, amountReceived: amountReceived);
}

// ── Purchase Helpers ────────────────────────────────────────────────────────

PurchaseEntry testPurchase({
  required String productId,
  required String productName,
  double qty = 10,
  double pricePerUnit = 100,
  PaymentMode paymentMode = PaymentMode.cash,
  String? supplierId,
  String? supplierName,
}) {
  return PurchaseEntry(
    supplierId: supplierId,
    supplierName: supplierName,
    items: [
      PurchaseLineItem(
        productId: productId,
        productName: productName,
        quantity: qty,
        purchasePricePerUnit: pricePerUnit,
      ),
    ],
    paymentMode: paymentMode,
  );
}

// ── Return Helpers ──────────────────────────────────────────────────────────

SalesReturn testReturn({
  required String billId,
  required String returnNumber,
  required List<ReturnLineItem> items,
  RefundMode refundMode = RefundMode.cash,
}) {
  return SalesReturn(
    originalBillId: billId,
    returnNumber: returnNumber,
    items: items,
    refundMode: refundMode,
  );
}

ReturnLineItem returnItem({
  required String productId,
  String productName = 'Product',
  required double qty,
  required double pricePerUnit,
  double cgstAmount = 0,
  double sgstAmount = 0,
  double igstAmount = 0,
}) {
  return ReturnLineItem(
    productId: productId,
    productName: productName,
    quantityReturned: qty,
    pricePerUnit: pricePerUnit,
    cgstAmount: cgstAmount,
    sgstAmount: sgstAmount,
    igstAmount: igstAmount,
  );
}

// ── Quotation Helpers ───────────────────────────────────────────────────────

Quotation testQuotation({
  required String quotationNumber,
  required List<LineItem> items,
  QuotationStatus status = QuotationStatus.draft,
  double discount = 0,
  bool isInterState = false,
}) {
  final sub = GstCalculator.discountedSubtotal(items);
  return Quotation(
    quotationNumber: quotationNumber,
    items: items,
    status: status,
    subtotal: GstCalculator.subtotal(items),
    discount: discount,
    cgst: isInterState ? 0 : GstCalculator.totalCgst(items),
    sgst: isInterState ? 0 : GstCalculator.totalSgst(items),
    igst: isInterState ? GstCalculator.totalIgst(items) : 0,
    grandTotal: GstCalculator.grandTotal(items, discount: discount, isInterState: isInterState),
    isInterState: isInterState,
    validUntil: DateTime.now().add(const Duration(days: 30)),
  );
}
