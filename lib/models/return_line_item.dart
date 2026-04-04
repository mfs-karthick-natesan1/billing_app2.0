import '../core/utils/json_helpers.dart';

class ReturnLineItem {
  final String productId;
  final String productName;
  final double quantityReturned;
  final double pricePerUnit;
  final double refundAmount;
  final String? batchId;
  final String? batchNumber;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;

  ReturnLineItem({
    required this.productId,
    required this.productName,
    required this.quantityReturned,
    required this.pricePerUnit,
    double? refundAmount,
    this.batchId,
    this.batchNumber,
    this.cgstAmount = 0,
    this.sgstAmount = 0,
    this.igstAmount = 0,
  }) : refundAmount = refundAmount ?? (quantityReturned * pricePerUnit);

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantityReturned': quantityReturned,
      'pricePerUnit': pricePerUnit,
      'refundAmount': refundAmount,
      'batchId': batchId,
      'batchNumber': batchNumber,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
    };
  }

  factory ReturnLineItem.fromJson(Map<String, dynamic> json) {
    return ReturnLineItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantityReturned: JsonHelpers.asDouble(json['quantityReturned']),
      pricePerUnit: JsonHelpers.asDouble(json['pricePerUnit']),
      refundAmount: JsonHelpers.asDouble(json['refundAmount']),
      batchId: json['batchId'] as String?,
      batchNumber: json['batchNumber'] as String?,
      cgstAmount: JsonHelpers.asDouble(json['cgstAmount']),
      sgstAmount: JsonHelpers.asDouble(json['sgstAmount']),
      igstAmount: JsonHelpers.asDouble(json['igstAmount']),
    );
  }

}
