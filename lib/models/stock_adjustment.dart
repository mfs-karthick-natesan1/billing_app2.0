import 'package:uuid/uuid.dart';
import '../core/utils/json_helpers.dart';

enum StockAdjustmentReason {
  damage,
  theft,
  expiry,
  countCorrection,
  returnFromCustomer,
  other,
}

extension StockAdjustmentReasonX on StockAdjustmentReason {
  String get label {
    switch (this) {
      case StockAdjustmentReason.damage:
        return 'Damage';
      case StockAdjustmentReason.theft:
        return 'Theft';
      case StockAdjustmentReason.expiry:
        return 'Expiry';
      case StockAdjustmentReason.countCorrection:
        return 'Count Correction';
      case StockAdjustmentReason.returnFromCustomer:
        return 'Customer Return';
      case StockAdjustmentReason.other:
        return 'Other';
    }
  }
}

class StockAdjustment {
  final String id;
  final String productId;
  final String productName;
  final double previousStock;
  final double newStock;
  final double adjustmentQty;
  final StockAdjustmentReason reason;
  final String? notes;
  final DateTime date;
  final String? adjustedBy;

  StockAdjustment({
    String? id,
    required this.productId,
    required this.productName,
    required this.previousStock,
    required this.newStock,
    double? adjustmentQty,
    required this.reason,
    this.notes,
    DateTime? date,
    this.adjustedBy,
  })  : id = id ?? const Uuid().v4(),
        adjustmentQty = adjustmentQty ?? (newStock - previousStock),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'previousStock': previousStock,
      'newStock': newStock,
      'adjustmentQty': adjustmentQty,
      'reason': reason.name,
      'notes': notes,
      'date': date.toIso8601String(),
      'adjustedBy': adjustedBy,
    };
  }

  factory StockAdjustment.fromJson(Map<String, dynamic> json) {
    return StockAdjustment(
      id: json['id'] as String?,
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      previousStock: JsonHelpers.asDouble(json['previousStock']),
      newStock: JsonHelpers.asDouble(json['newStock']),
      adjustmentQty: JsonHelpers.asDouble(json['adjustmentQty']),
      reason: _reasonFromString(json['reason'] as String?),
      notes: json['notes'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      adjustedBy: json['adjustedBy'] as String?,
    );
  }

  static StockAdjustmentReason _reasonFromString(String? value) {
    if (value == null) return StockAdjustmentReason.other;
    for (final r in StockAdjustmentReason.values) {
      if (r.name == value) return r;
    }
    return StockAdjustmentReason.other;
  }

}
