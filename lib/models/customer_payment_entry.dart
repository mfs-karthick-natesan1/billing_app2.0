import 'package:uuid/uuid.dart';

import '../core/utils/json_helpers.dart';
import 'payment_method.dart';

export 'payment_method.dart';

// Backward-compatible alias so existing code using SettlementPaymentMode continues to work.
typedef SettlementPaymentMode = PaymentMethod;

/// Cheque clearing status for cheque payments.
enum ChequeStatus { pending, cleared, bounced }

class CustomerPaymentEntry {
  final String id;
  final String customerId;
  final double amount;
  final SettlementPaymentMode paymentMode;
  final DateTime recordedAt;
  final String? recordedBy;
  final String? notes;
  final String? billReference;

  // Cheque-specific fields
  final String? chequeNumber;
  final String? chequeBank;
  final DateTime? chequeDate;
  final ChequeStatus? chequeStatus;

  CustomerPaymentEntry({
    String? id,
    required this.customerId,
    required this.amount,
    this.paymentMode = SettlementPaymentMode.cash,
    DateTime? recordedAt,
    this.recordedBy,
    this.notes,
    this.billReference,
    this.chequeNumber,
    this.chequeBank,
    this.chequeDate,
    this.chequeStatus,
  }) : id = id ?? const Uuid().v4(),
       recordedAt = recordedAt ?? DateTime.now();

  /// Whether this is a cheque payment still awaiting clearance.
  bool get isPendingCheque =>
      paymentMode == PaymentMethod.cheque &&
      chequeStatus == ChequeStatus.pending;

  /// Whether this cheque has bounced.
  bool get isBouncedCheque =>
      paymentMode == PaymentMethod.cheque &&
      chequeStatus == ChequeStatus.bounced;

  CustomerPaymentEntry copyWith({
    double? amount,
    SettlementPaymentMode? paymentMode,
    DateTime? recordedAt,
    String? recordedBy,
    String? notes,
    String? billReference,
    String? chequeNumber,
    String? chequeBank,
    DateTime? chequeDate,
    ChequeStatus? chequeStatus,
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
      chequeNumber: chequeNumber ?? this.chequeNumber,
      chequeBank: chequeBank ?? this.chequeBank,
      chequeDate: chequeDate ?? this.chequeDate,
      chequeStatus: chequeStatus ?? this.chequeStatus,
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
      'chequeNumber': chequeNumber,
      'chequeBank': chequeBank,
      'chequeDate': chequeDate?.toIso8601String(),
      'chequeStatus': chequeStatus?.name,
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
      chequeNumber: json['chequeNumber'] as String?,
      chequeBank: json['chequeBank'] as String?,
      chequeDate: json['chequeDate'] != null
          ? DateTime.tryParse(json['chequeDate'] as String)
          : null,
      chequeStatus: _chequeStatusFromString(json['chequeStatus'] as String?),
    );
  }

  static ChequeStatus? _chequeStatusFromString(String? value) {
    if (value == null) return null;
    for (final status in ChequeStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }
}
