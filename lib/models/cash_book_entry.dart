import 'package:uuid/uuid.dart';
import '../core/utils/json_helpers.dart';

enum CashEntryType { cashIn, cashOut }

class CashBookManualEntry {
  final String id;
  final double amount;
  final String description;
  final CashEntryType type;
  final String? category;
  final DateTime createdAt;
  final String? createdBy;

  CashBookManualEntry({
    String? id,
    required this.amount,
    required this.description,
    required this.type,
    this.category,
    DateTime? createdAt,
    this.createdBy,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  CashBookManualEntry copyWith({
    double? amount,
    String? description,
    CashEntryType? type,
    String? category,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return CashBookManualEntry(
      id: id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'type': type.name,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory CashBookManualEntry.fromJson(Map<String, dynamic> json) {
    return CashBookManualEntry(
      id: json['id'] as String?,
      amount: JsonHelpers.asDouble(json['amount']),
      description: json['description'] as String? ?? '',
      type: _entryTypeFromString(json['type'] as String?),
      category: json['category'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      createdBy: json['createdBy'] as String?,
    );
  }

  static CashEntryType _entryTypeFromString(String? value) {
    if (value == null) return CashEntryType.cashIn;
    for (final type in CashEntryType.values) {
      if (type.name == value) return type;
    }
    return CashEntryType.cashIn;
  }
}

class CashBookDay {
  final DateTime date;
  final double openingBalance;
  final bool openingBalanceOverridden;
  final double cashSales;
  final double cashReceived;
  final List<CashBookManualEntry> otherCashIn;
  final double cashExpenses;
  final double cashPaidToSuppliers;
  final List<CashBookManualEntry> otherCashOut;
  final double closingBalance;
  final String? notes;
  final bool isClosed;
  final DateTime? closedAt;
  final String? closedBy;

  CashBookDay({
    required this.date,
    this.openingBalance = 0,
    this.openingBalanceOverridden = false,
    this.cashSales = 0,
    this.cashReceived = 0,
    List<CashBookManualEntry>? otherCashIn,
    this.cashExpenses = 0,
    this.cashPaidToSuppliers = 0,
    List<CashBookManualEntry>? otherCashOut,
    this.closingBalance = 0,
    this.notes,
    this.isClosed = false,
    this.closedAt,
    this.closedBy,
  }) : otherCashIn = otherCashIn ?? const [],
       otherCashOut = otherCashOut ?? const [];

  double get totalOtherCashIn =>
      otherCashIn.fold(0, (sum, entry) => sum + entry.amount);

  double get totalOtherCashOut =>
      otherCashOut.fold(0, (sum, entry) => sum + entry.amount);

  double get totalInflows => cashSales + cashReceived + totalOtherCashIn;

  double get totalOutflows =>
      cashExpenses + cashPaidToSuppliers + totalOtherCashOut;

  CashBookDay copyWith({
    DateTime? date,
    double? openingBalance,
    bool? openingBalanceOverridden,
    double? cashSales,
    double? cashReceived,
    List<CashBookManualEntry>? otherCashIn,
    double? cashExpenses,
    double? cashPaidToSuppliers,
    List<CashBookManualEntry>? otherCashOut,
    double? closingBalance,
    String? notes,
    bool? isClosed,
    DateTime? closedAt,
    String? closedBy,
    bool clearClosedAt = false,
    bool clearClosedBy = false,
  }) {
    return CashBookDay(
      date: date ?? this.date,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceOverridden:
          openingBalanceOverridden ?? this.openingBalanceOverridden,
      cashSales: cashSales ?? this.cashSales,
      cashReceived: cashReceived ?? this.cashReceived,
      otherCashIn: otherCashIn ?? this.otherCashIn,
      cashExpenses: cashExpenses ?? this.cashExpenses,
      cashPaidToSuppliers: cashPaidToSuppliers ?? this.cashPaidToSuppliers,
      otherCashOut: otherCashOut ?? this.otherCashOut,
      closingBalance: closingBalance ?? this.closingBalance,
      notes: notes ?? this.notes,
      isClosed: isClosed ?? this.isClosed,
      closedAt: clearClosedAt ? null : closedAt ?? this.closedAt,
      closedBy: clearClosedBy ? null : closedBy ?? this.closedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'openingBalance': openingBalance,
      'openingBalanceOverridden': openingBalanceOverridden,
      'cashSales': cashSales,
      'cashReceived': cashReceived,
      'otherCashIn': otherCashIn.map((entry) => entry.toJson()).toList(),
      'cashExpenses': cashExpenses,
      'cashPaidToSuppliers': cashPaidToSuppliers,
      'otherCashOut': otherCashOut.map((entry) => entry.toJson()).toList(),
      'closingBalance': closingBalance,
      'notes': notes,
      'isClosed': isClosed,
      'closedAt': closedAt?.toIso8601String(),
      'closedBy': closedBy,
    };
  }

  factory CashBookDay.fromJson(Map<String, dynamic> json) {
    return CashBookDay(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      openingBalance: JsonHelpers.asDouble(json['openingBalance']),
      openingBalanceOverridden:
          json['openingBalanceOverridden'] as bool? ?? false,
      cashSales: JsonHelpers.asDouble(json['cashSales']),
      cashReceived: JsonHelpers.asDouble(json['cashReceived']),
      otherCashIn: _entryList(json['otherCashIn']),
      cashExpenses: JsonHelpers.asDouble(json['cashExpenses']),
      cashPaidToSuppliers: JsonHelpers.asDouble(json['cashPaidToSuppliers']),
      otherCashOut: _entryList(json['otherCashOut']),
      closingBalance: JsonHelpers.asDouble(json['closingBalance']),
      notes: json['notes'] as String?,
      isClosed: json['isClosed'] as bool? ?? false,
      closedAt: DateTime.tryParse(json['closedAt'] as String? ?? ''),
      closedBy: json['closedBy'] as String?,
    );
  }

  static List<CashBookManualEntry> _entryList(dynamic value) {
    final list = value as List<dynamic>? ?? const [];
    return list
        .map(_mapOrNull)
        .whereType<Map<String, dynamic>>()
        .map(CashBookManualEntry.fromJson)
        .toList();
  }

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

}

class CashBookDayBreakdown {
  final CashBookDay day;

  const CashBookDayBreakdown(this.day);

  double get inflows => day.totalInflows;
  double get outflows => day.totalOutflows;
}

class CashBookMonthSummary {
  final double totalInflows;
  final double totalOutflows;
  final double net;
  final double openingBalance;
  final double closingBalance;

  const CashBookMonthSummary({
    this.totalInflows = 0,
    this.totalOutflows = 0,
    this.net = 0,
    this.openingBalance = 0,
    this.closingBalance = 0,
  });
}
