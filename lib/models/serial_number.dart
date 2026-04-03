import 'package:uuid/uuid.dart';

enum SerialNumberStatus { inStock, sold, returned }

class SerialNumber {
  final String id;
  final String productId;
  final String productName;
  final String number;
  SerialNumberStatus status;
  final String? purchaseEntryId;
  String? billId;
  final DateTime createdAt;

  SerialNumber({
    String? id,
    required this.productId,
    required this.productName,
    required this.number,
    this.status = SerialNumberStatus.inStock,
    this.purchaseEntryId,
    this.billId,
    DateTime? createdAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': productId,
    'productName': productName,
    'number': number,
    'status': status.name,
    'purchaseEntryId': purchaseEntryId,
    'billId': billId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SerialNumber.fromJson(Map<String, dynamic> json) => SerialNumber(
    id: json['id'] as String?,
    productId: json['productId'] as String? ?? '',
    productName: json['productName'] as String? ?? '',
    number: json['number'] as String? ?? '',
    status: SerialNumberStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => SerialNumberStatus.inStock,
    ),
    purchaseEntryId: json['purchaseEntryId'] as String?,
    billId: json['billId'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
  );
}
