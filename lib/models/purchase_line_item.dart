import '../core/utils/json_helpers.dart';

class PurchaseLineItem {
  final String productId;
  final String productName;
  final double quantity;
  final String? unitOfMeasure;
  final double purchasePricePerUnit;
  final String? batchNumber;
  final DateTime? expiryDate;
  final double gstRate;
  final bool isTaxInclusive;

  PurchaseLineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    this.unitOfMeasure,
    required this.purchasePricePerUnit,
    this.batchNumber,
    this.expiryDate,
    this.gstRate = 0,
    this.isTaxInclusive = false,
  });

  /// Total amount paid (inclusive of tax if isTaxInclusive, or exclusive).
  double get totalCost => quantity * purchasePricePerUnit;

  /// Tax amount embedded in totalCost (when isTaxInclusive) or added on top.
  double get taxAmount {
    if (gstRate <= 0) return 0;
    if (isTaxInclusive) {
      // Reverse-calculate: tax = total * rate / (100 + rate)
      return totalCost * gstRate / (100 + gstRate);
    } else {
      return totalCost * gstRate / 100;
    }
  }

  /// Base amount before tax.
  double get baseAmount => isTaxInclusive ? totalCost - taxAmount : totalCost;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitOfMeasure': unitOfMeasure,
      'purchasePricePerUnit': purchasePricePerUnit,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'gstRate': gstRate,
      'isTaxInclusive': isTaxInclusive,
    };
  }

  factory PurchaseLineItem.fromJson(Map<String, dynamic> json) {
    return PurchaseLineItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantity: JsonHelpers.asDouble(json['quantity']),
      unitOfMeasure: json['unitOfMeasure'] as String?,
      purchasePricePerUnit: JsonHelpers.asDouble(json['purchasePricePerUnit']),
      batchNumber: json['batchNumber'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'] as String)
          : null,
      gstRate: JsonHelpers.asDouble(json['gstRate']),
      isTaxInclusive: json['isTaxInclusive'] as bool? ?? false,
    );
  }

}
