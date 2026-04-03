import 'customer.dart';
import '../constants/app_strings.dart';

enum PaymentMode { cash, upi, credit, split }

enum CreditType { full, partial }

extension PaymentModeX on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash:
        return AppStrings.cash;
      case PaymentMode.upi:
        return AppStrings.upi;
      case PaymentMode.credit:
        return AppStrings.creditUdhar;
      case PaymentMode.split:
        return 'Split';
    }
  }

  bool get isCredit => this == PaymentMode.credit;
  bool get isCash => this == PaymentMode.cash;
  bool get isSplit => this == PaymentMode.split;
  bool get isPaidNonCredit => this != PaymentMode.credit;
}

class PaymentInfo {
  final PaymentMode mode;
  final CreditType? creditType;
  final double amountReceived;
  final double creditAmount;
  final Customer? customer;
  final double? splitCashAmount;
  final double? splitUpiAmount;

  const PaymentInfo({
    required this.mode,
    this.creditType,
    this.amountReceived = 0,
    this.creditAmount = 0,
    this.customer,
    this.splitCashAmount,
    this.splitUpiAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,
      'creditType': creditType?.name,
      'amountReceived': amountReceived,
      'creditAmount': creditAmount,
      'customer': customer?.toJson(),
      'splitCashAmount': splitCashAmount,
      'splitUpiAmount': splitUpiAmount,
    };
  }

  factory PaymentInfo.fromJson(Map<String, dynamic> json) {
    return PaymentInfo(
      mode: _paymentModeFromString(json['mode'] as String?),
      creditType: _creditTypeFromString(json['creditType'] as String?),
      amountReceived: _asDouble(json['amountReceived']),
      creditAmount: _asDouble(json['creditAmount']),
      customer: _customerFromJson(json['customer']),
      splitCashAmount: json['splitCashAmount'] != null ? _asDouble(json['splitCashAmount']) : null,
      splitUpiAmount: json['splitUpiAmount'] != null ? _asDouble(json['splitUpiAmount']) : null,
    );
  }

  static PaymentMode _paymentModeFromString(String? value) {
    if (value == null) return PaymentMode.cash;
    for (final mode in PaymentMode.values) {
      if (mode.name == value) return mode;
    }
    return PaymentMode.cash;
  }

  static CreditType? _creditTypeFromString(String? value) {
    if (value == null) return null;
    for (final type in CreditType.values) {
      if (type.name == value) return type;
    }
    return null;
  }

  static Customer? _customerFromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Customer.fromJson(value);
    }
    if (value is Map) {
      return Customer.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }

  static double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
