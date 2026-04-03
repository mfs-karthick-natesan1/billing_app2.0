import 'package:uuid/uuid.dart';

import '../constants/app_strings.dart';

enum SettlementPaymentMode { cash, upi, bankTransfer }

extension SettlementPaymentModeX on SettlementPaymentMode {
  String get label {
    switch (this) {
      case SettlementPaymentMode.cash:
        return AppStrings.cash;
      case SettlementPaymentMode.upi:
        return AppStrings.upi;
      case SettlementPaymentMode.bankTransfer:
        return AppStrings.bankTransfer;
    }
  }
}

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
      amount: _asDouble(json['amount']),
      paymentMode: _paymentModeFromString(json['paymentMode'] as String?),
      recordedAt: DateTime.tryParse(json['recordedAt'] as String? ?? ''),
      recordedBy: json['recordedBy'] as String?,
      notes: json['notes'] as String?,
      billReference: json['billReference'] as String?,
    );
  }

  static SettlementPaymentMode _paymentModeFromString(String? value) {
    if (value == null) return SettlementPaymentMode.cash;
    for (final mode in SettlementPaymentMode.values) {
      if (mode.name == value) return mode;
    }
    return SettlementPaymentMode.cash;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
