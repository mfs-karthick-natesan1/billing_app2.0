import 'customer.dart';
import 'payment_method.dart';
import '../core/utils/json_helpers.dart';

export 'payment_method.dart';

// Backward-compatible alias so existing code using PaymentMode continues to work.
typedef PaymentMode = PaymentMethod;

// Re-export PaymentMethodX members as PaymentModeX for backward compat.
// All existing references like `mode.isCredit`, `mode.isCash`, etc. work via
// PaymentMethodX extension on PaymentMethod (= PaymentMode).

enum CreditType { full, partial }

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
      mode: PaymentMethodX.fromString(json['mode'] as String?),
      creditType: _creditTypeFromString(json['creditType'] as String?),
      amountReceived: JsonHelpers.asDouble(json['amountReceived']),
      creditAmount: JsonHelpers.asDouble(json['creditAmount']),
      customer: _customerFromJson(json['customer']),
      splitCashAmount: json['splitCashAmount'] != null
          ? JsonHelpers.asDouble(json['splitCashAmount'])
          : null,
      splitUpiAmount: json['splitUpiAmount'] != null
          ? JsonHelpers.asDouble(json['splitUpiAmount'])
          : null,
    );
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
}
