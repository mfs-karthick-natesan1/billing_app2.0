import 'package:uuid/uuid.dart';
import '../core/utils/json_helpers.dart';

class ProductBatch {
  final String id;
  final String productId;
  final String batchNumber;
  final DateTime expiryDate;
  final int stockQuantity;
  final DateTime createdAt;

  ProductBatch({
    String? id,
    required this.productId,
    required this.batchNumber,
    required this.expiryDate,
    this.stockQuantity = 0,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isExpiringSoon =>
      expiryDate.isBefore(DateTime.now().add(const Duration(days: 90))) &&
      !isExpired;

  ProductBatch copyWith({
    String? batchNumber,
    DateTime? expiryDate,
    int? stockQuantity,
  }) {
    return ProductBatch(
      id: id,
      productId: productId,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate.toIso8601String(),
      'stockQuantity': stockQuantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductBatch.fromJson(Map<String, dynamic> json) {
    return ProductBatch(
      id: json['id'] as String?,
      productId: json['productId'] as String? ?? '',
      batchNumber: json['batchNumber'] as String? ?? '',
      expiryDate:
          DateTime.tryParse(json['expiryDate'] as String? ?? '') ??
          DateTime.now(),
      stockQuantity: JsonHelpers.asInt(json['stockQuantity']),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
