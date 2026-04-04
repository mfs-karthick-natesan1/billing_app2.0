import 'package:uuid/uuid.dart';
import 'return_line_item.dart';
import '../core/utils/json_helpers.dart';

enum RefundMode { cash, creditToAccount, exchange }

class SalesReturn {
  final String id;
  final String originalBillId;
  final String returnNumber;
  final DateTime date;
  final String? customerId;
  final String? customerName;
  final List<ReturnLineItem> items;
  final double totalRefundAmount;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final RefundMode refundMode;
  final String? notes;
  final String? createdBy;

  SalesReturn({
    String? id,
    required this.originalBillId,
    required this.returnNumber,
    DateTime? date,
    this.customerId,
    this.customerName,
    required this.items,
    double? totalRefundAmount,
    double? totalCgst,
    double? totalSgst,
    double? totalIgst,
    required this.refundMode,
    this.notes,
    this.createdBy,
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now(),
       totalRefundAmount = totalRefundAmount ??
           items.fold(0.0, (sum, item) => sum + item.refundAmount),
       totalCgst = totalCgst ??
           items.fold(0.0, (sum, item) => sum + item.cgstAmount),
       totalSgst = totalSgst ??
           items.fold(0.0, (sum, item) => sum + item.sgstAmount),
       totalIgst = totalIgst ??
           items.fold(0.0, (sum, item) => sum + item.igstAmount);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalBillId': originalBillId,
      'returnNumber': returnNumber,
      'date': date.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'totalRefundAmount': totalRefundAmount,
      'totalCgst': totalCgst,
      'totalSgst': totalSgst,
      'totalIgst': totalIgst,
      'refundMode': refundMode.name,
      'notes': notes,
      'createdBy': createdBy,
    };
  }

  factory SalesReturn.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return SalesReturn(
      id: json['id'] as String?,
      originalBillId: json['originalBillId'] as String? ?? '',
      returnNumber: json['returnNumber'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ReturnLineItem.fromJson)
          .toList(),
      totalRefundAmount: JsonHelpers.asDouble(json['totalRefundAmount']),
      totalCgst: JsonHelpers.asDouble(json['totalCgst']),
      totalSgst: JsonHelpers.asDouble(json['totalSgst']),
      totalIgst: JsonHelpers.asDouble(json['totalIgst']),
      refundMode: _refundModeFromString(json['refundMode'] as String?),
      notes: json['notes'] as String?,
      createdBy: json['createdBy'] as String?,
    );
  }

  static RefundMode _refundModeFromString(String? value) {
    if (value == null) return RefundMode.cash;
    for (final mode in RefundMode.values) {
      if (mode.name == value) return mode;
    }
    return RefundMode.cash;
  }

}
