import 'product.dart';
import 'product_batch.dart';
import '../core/utils/json_helpers.dart';

class LineItem {
  final Product product;
  final double quantity;
  final ProductBatch? batch;
  final double gstRate;
  final bool gstInclusivePrice;
  final double discountPercent;
  // IDs of SerialNumber records being sold on this line (only for tracked products)
  final List<String> serialNumberIds;

  LineItem({
    required this.product,
    this.quantity = 1,
    this.batch,
    double? gstRate,
    bool? gstInclusivePrice,
    this.discountPercent = 0,
    List<String>? serialNumberIds,
  }) : gstRate = gstRate ?? product.gstRate,
       gstInclusivePrice = gstInclusivePrice ?? product.gstInclusivePrice,
       serialNumberIds = serialNumberIds ?? [];

  LineItem copyWith({
    Product? product,
    double? quantity,
    ProductBatch? batch,
    double? gstRate,
    bool? gstInclusivePrice,
    double? discountPercent,
    List<String>? serialNumberIds,
  }) {
    return LineItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      batch: batch ?? this.batch,
      gstRate: gstRate ?? this.gstRate,
      gstInclusivePrice: gstInclusivePrice ?? this.gstInclusivePrice,
      discountPercent: discountPercent ?? this.discountPercent,
      serialNumberIds: serialNumberIds ?? List.from(this.serialNumberIds),
    );
  }

  /// Line discount amount (flat Rs).
  double get lineDiscountAmount => subtotal * discountPercent / 100;

  /// Subtotal after line discount.
  double get discountedSubtotal => subtotal - lineDiscountAmount;

  /// The taxable value (pre-tax base) for this line item.
  double get taxableAmount {
    final lineTotal = discountedSubtotal;
    if (gstRate == 0) return lineTotal;
    if (gstInclusivePrice) {
      // Reverse-calculate: price includes GST
      return lineTotal / (1 + gstRate / 100);
    }
    return lineTotal;
  }

  /// Total line value before any tax or discount (price × qty).
  double get subtotal => product.sellingPrice * quantity;

  /// Total tax for this line item.
  double get taxAmount {
    if (gstRate == 0) return 0;
    return taxableAmount * gstRate / 100;
  }

  /// CGST portion (half of GST rate, intra-state).
  double get cgstAmount {
    if (gstRate == 0) return 0;
    return taxableAmount * (gstRate / 2) / 100;
  }

  /// SGST portion (same as CGST, intra-state).
  double get sgstAmount => cgstAmount;

  /// IGST portion (full GST rate, inter-state).
  double get igstAmount {
    if (gstRate == 0) return 0;
    return taxableAmount * gstRate / 100;
  }

  double get totalWithGst => taxableAmount + taxAmount;

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'batch': batch?.toJson(),
      'gstRate': gstRate,
      'gstInclusivePrice': gstInclusivePrice,
      'discountPercent': discountPercent,
      'serialNumberIds': serialNumberIds,
    };
  }

  factory LineItem.fromJson(Map<String, dynamic> json) {
    final product = _productFromJson(json['product']);
    return LineItem(
      product: product,
      quantity: JsonHelpers.asDouble(json['quantity'], fallback: 1),
      batch: _batchFromJson(json['batch']),
      gstRate: json.containsKey('gstRate')
          ? JsonHelpers.asDouble(json['gstRate'])
          : product.gstRate,
      gstInclusivePrice: json['gstInclusivePrice'] as bool? ??
          product.gstInclusivePrice,
      discountPercent: JsonHelpers.asDouble(json['discountPercent']),
      serialNumberIds: (json['serialNumberIds'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }

  static Product _productFromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Product.fromJson(value);
    }
    if (value is Map) {
      return Product.fromJson(value.cast<String, dynamic>());
    }
    return Product(name: '', sellingPrice: 0);
  }

  static ProductBatch? _batchFromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return ProductBatch.fromJson(value);
    }
    if (value is Map) {
      return ProductBatch.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }
}
