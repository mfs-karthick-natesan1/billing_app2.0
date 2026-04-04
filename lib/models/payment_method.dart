import '../constants/app_strings.dart';

/// Unified payment method enum for bills, expenses, and customer settlements.
enum PaymentMethod { cash, upi, credit, split, bankTransfer }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return AppStrings.cash;
      case PaymentMethod.upi:
        return AppStrings.upi;
      case PaymentMethod.credit:
        return AppStrings.creditUdhar;
      case PaymentMethod.split:
        return 'Split';
      case PaymentMethod.bankTransfer:
        return AppStrings.bankTransfer;
    }
  }

  bool get isCredit => this == PaymentMethod.credit;
  bool get isCash => this == PaymentMethod.cash;
  bool get isSplit => this == PaymentMethod.split;
  bool get isPaidNonCredit => this != PaymentMethod.credit;

  /// Modes applicable for bill payment.
  bool get applicableForBills =>
      const {
        PaymentMethod.cash,
        PaymentMethod.upi,
        PaymentMethod.credit,
        PaymentMethod.split,
      }.contains(this);

  /// Modes applicable for expense recording.
  bool get applicableForExpenses =>
      const {
        PaymentMethod.cash,
        PaymentMethod.upi,
        PaymentMethod.bankTransfer,
        PaymentMethod.credit,
      }.contains(this);

  /// Modes applicable for customer credit settlement.
  bool get applicableForSettlements =>
      const {
        PaymentMethod.cash,
        PaymentMethod.upi,
        PaymentMethod.bankTransfer,
      }.contains(this);

  static PaymentMethod fromString(String? value,
      {PaymentMethod fallback = PaymentMethod.cash}) {
    if (value == null) return fallback;
    for (final mode in PaymentMethod.values) {
      if (mode.name == value) return mode;
    }
    return fallback;
  }
}
