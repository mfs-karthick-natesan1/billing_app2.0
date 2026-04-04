import 'package:uuid/uuid.dart';

import '../core/utils/json_helpers.dart';
import 'payment_method.dart';

export 'payment_method.dart';

// Backward-compatible alias so existing code using SettlementPaymentMode continues to work.
typedef SettlementPaymentMode = PaymentMethod;

class CustomerPaymentEntry {
  final String id;
  final String customerId;
  final double amount;
  final SettlementPaymentMode paymentMode;
  final DateTime recordedAt;
  final String? recordedBy;
  final String? notes;
  final String? billReference;

  CustomerPaymentEntry({
    String? id,
    required this.customerId,
    required this.amount,
    this.paymentMode = SettlementPaymentMode.cash,
    DateTime? recordedAt,
    this.recordedBy,
    this.notes,
    this.billReference,
  }) : id = id ?? const Uuid().v4(),
       recordedAt = recordedAt ?? DateTime.now();

  CustomerPaymentEntry copyWith({
    double? amount,
    SettlementPaymentMode? paymentMode,
    DateTime? recordedAt,
    String? recordedBy,
    String? notes,
    String? billReference,
  }) {
    return CustomerPaymentEntry(
      id: id,
      customerId: customerId,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedBy: recordedBy ?? this.recordedBy,
      notes: notes ?? this.notes,
      billReference: billReference ?? this.billReference,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'amount': amount,
      'paymentMode': paymentMode.name,
      'recordedAt': recordedAt.toIso8601String(),
      'recordedBy': recordedBy,
      'notes': notes,
      'billReference': billReference,
    };
  }

  factory CustomerPaymentEntry.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentEntry(
      id: json['id'] as String?,
      customerId: json['customerId'] as String? ?? '',
      amount: JsonHelpers.asDouble(json['amount']),
      paymentMode: PaymentMethodX.fromString(json['paymentMode'] as String?),
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? ''),
      recordedBy: json['recordedBy'] as String?,
      notes: json['notes'] as String?,
      billReference: json['billReference'] as String?,
    );
  }
}
