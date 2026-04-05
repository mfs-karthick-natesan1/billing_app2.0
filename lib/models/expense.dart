import 'package:uuid/uuid.dart';

import '../constants/app_strings.dart';
import '../core/utils/json_helpers.dart';
import 'expense_category.dart';
import 'payment_method.dart';

export 'payment_method.dart';

// Backward-compatible alias so existing code using ExpensePaymentMode continues to work.
typedef ExpensePaymentMode = PaymentMethod;

enum RecurringFrequency { daily, weekly, monthly, yearly }

extension RecurringFrequencyX on RecurringFrequency {
  String get label {
    switch (this) {
      case RecurringFrequency.daily:
        return AppStrings.recurringDaily;
      case RecurringFrequency.weekly:
        return AppStrings.recurringWeekly;
      case RecurringFrequency.monthly:
        return AppStrings.recurringMonthly;
      case RecurringFrequency.yearly:
        return AppStrings.recurringYearly;
    }
  }
}

class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String? customCategoryName;
  final String? customCategoryIconKey;
  final String? description;
  final DateTime date;
  final ExpensePaymentMode paymentMode;
  final String? receiptImagePath;
  final String? vendorName;
  final bool isRecurring;
  final RecurringFrequency? recurringFrequency;
  final String? createdBy;
  final String? billReference;
  final bool autoCreate;
  final DateTime? lastCreatedAt;

  Expense({
    String? id,
    required this.amount,
    required this.category,
    this.customCategoryName,
    this.customCategoryIconKey,
    this.description,
    DateTime? date,
    this.paymentMode = ExpensePaymentMode.cash,
    this.receiptImagePath,
    this.vendorName,
    this.isRecurring = false,
    this.recurringFrequency,
    this.createdBy,
    this.billReference,
    this.autoCreate = false,
    this.lastCreatedAt,
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now();

  /// Computes the next due date from [date] and [recurringFrequency].
  DateTime? get nextDueDate {
    if (!isRecurring || recurringFrequency == null) return null;
    final now = DateTime.now();
    var next = date;
    for (var i = 0; i < 1000; i++) {
      if (next.isAfter(now) ||
          (next.year == now.year &&
              next.month == now.month &&
              next.day == now.day)) {
        return next;
      }
      switch (recurringFrequency!) {
        case RecurringFrequency.daily:
          next = next.add(const Duration(days: 1));
        case RecurringFrequency.weekly:
          next = next.add(const Duration(days: 7));
        case RecurringFrequency.monthly:
          next = DateTime(next.year, next.month + 1, next.day);
        case RecurringFrequency.yearly:
          next = DateTime(next.year + 1, next.month, next.day);
      }
    }
    return null;
  }

  String get categoryLabel {
    if (category == ExpenseCategory.custom &&
        customCategoryName != null &&
        customCategoryName!.trim().isNotEmpty) {
      return customCategoryName!.trim();
    }
    return category.label;
  }

  String get categoryIconKey {
    if (category == ExpenseCategory.custom &&
        customCategoryIconKey != null &&
        customCategoryIconKey!.trim().isNotEmpty) {
      return customCategoryIconKey!.trim();
    }
    return category.iconKey;
  }

  Expense copyWith({
    double? amount,
    ExpenseCategory? category,
    String? customCategoryName,
    String? customCategoryIconKey,
    String? description,
    DateTime? date,
    ExpensePaymentMode? paymentMode,
    String? receiptImagePath,
    String? vendorName,
    bool? isRecurring,
    RecurringFrequency? recurringFrequency,
    bool clearRecurringFrequency = false,
    String? createdBy,
    String? billReference,
    bool? autoCreate,
    DateTime? lastCreatedAt,
    bool clearLastCreatedAt = false,
  }) {
    return Expense(
      id: id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      customCategoryName: customCategoryName ?? this.customCategoryName,
      customCategoryIconKey:
          customCategoryIconKey ?? this.customCategoryIconKey,
      description: description ?? this.description,
      date: date ?? this.date,
      paymentMode: paymentMode ?? this.paymentMode,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      vendorName: vendorName ?? this.vendorName,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: clearRecurringFrequency
          ? null
          : recurringFrequency ?? this.recurringFrequency,
      createdBy: createdBy ?? this.createdBy,
      billReference: billReference ?? this.billReference,
      autoCreate: autoCreate ?? this.autoCreate,
      lastCreatedAt: clearLastCreatedAt
          ? null
          : lastCreatedAt ?? this.lastCreatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Expense && other.id == id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category.name,
      'customCategoryName': customCategoryName,
      'customCategoryIconKey': customCategoryIconKey,
      'description': description,
      'date': date.toIso8601String(),
      'paymentMode': paymentMode.name,
      'receiptImagePath': receiptImagePath,
      'vendorName': vendorName,
      'isRecurring': isRecurring,
      'recurringFrequency': recurringFrequency?.name,
      'createdBy': createdBy,
      'billReference': billReference,
      'autoCreate': autoCreate,
      'lastCreatedAt': lastCreatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Expense(id: $id, amount: $amount, category: ${category.label}, date: $date)';

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String?,
      amount: JsonHelpers.asDouble(json['amount']),
      category: expenseCategoryFromString(json['category'] as String?),
      customCategoryName: json['customCategoryName'] as String?,
      customCategoryIconKey: json['customCategoryIconKey'] as String?,
      description: json['description'] as String?,
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      paymentMode: PaymentMethodX.fromString(json['paymentMode'] as String?),
      receiptImagePath: json['receiptImagePath'] as String?,
      vendorName: json['vendorName'] as String?,
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurringFrequency: _recurringFromString(
        json['recurringFrequency'] as String?,
      ),
      createdBy: json['createdBy'] as String?,
      billReference: json['billReference'] as String?,
      autoCreate: json['autoCreate'] as bool? ?? false,
      lastCreatedAt: json['lastCreatedAt'] != null
          ? DateTime.tryParse(json['lastCreatedAt'] as String)
          : null,
    );
  }

  static RecurringFrequency? _recurringFromString(String? value) {
    if (value == null) return null;
    for (final frequency in RecurringFrequency.values) {
      if (frequency.name == value) return frequency;
    }
    return null;
  }
}
