class ReturnLineItem {
  final String productId;
  final String productName;
  final double quantityReturned;
  final double pricePerUnit;
  final double refundAmount;
  final String? batchId;
  final String? batchNumber;

  ReturnLineItem({
    required this.productId,
    required this.productName,
    required this.quantityReturned,
    required this.pricePerUnit,
    double? refundAmount,
    this.batchId,
    this.batchNumber,
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
    };
  }

  factory ReturnLineItem.fromJson(Map<String, dynamic> json) {
    return ReturnLineItem(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      quantityReturned: _asDouble(json['quantityReturned']),
      pricePerUnit: _asDouble(json['pricePerUnit']),
      refundAmount: _asDouble(json['refundAmount']),
      batchId: json['batchId'] as String?,
      batchNumber: json['batchNumber'] as String?,
    );
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
