import 'package:uuid/uuid.dart';
import 'payment_info.dart';
import 'purchase_line_item.dart';
import '../core/utils/json_helpers.dart';

class PurchaseEntry {
  final String id;
  final String? supplierId;
  final String? supplierName;
  final DateTime date;
  final List<PurchaseLineItem> items;
  final double totalAmount;
  final PaymentMode paymentMode;
  final String? invoiceNumber;
  final String? notes;
  final String? createdBy;

  PurchaseEntry({
    String? id,
    this.supplierId,
    this.supplierName,
    DateTime? date,
    required this.items,
    double? totalAmount,
    this.paymentMode = PaymentMode.cash,
    this.invoiceNumber,
    this.notes,
    this.createdBy,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        totalAmount =
            totalAmount ?? items.fold(0.0, (sum, i) => sum + i.totalCost);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'paymentMode': paymentMode.name,
      'invoiceNumber': invoiceNumber,
      'notes': notes,
      'createdBy': createdBy,
    };
  }

  factory PurchaseEntry.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PurchaseEntry(
      id: json['id'] as String?,
      supplierId: json['supplierId'] as String?,
      supplierName: json['supplierName'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(PurchaseLineItem.fromJson)
          .toList(),
      totalAmount: JsonHelpers.asDouble(json['totalAmount']),
      paymentMode: PaymentMethodX.fromString(json['paymentMode'] as String?),
      invoiceNumber: json['invoiceNumber'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
    );
  }

}
