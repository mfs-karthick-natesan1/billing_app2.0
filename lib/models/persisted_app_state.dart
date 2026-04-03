import 'bill.dart';
import 'business_config.dart';
import 'serial_number.dart';
import 'cash_book_entry.dart';
import 'customer.dart';
import 'customer_payment_entry.dart';
import 'expense.dart';
import 'job_card.dart';
import 'product.dart';
import 'purchase_entry.dart';
import 'quotation.dart';
import 'sales_return.dart';
import 'stock_adjustment.dart';
import 'supplier.dart';
import 'table_order.dart';
import 'app_user.dart';

class PersistedAppState {
  final int schemaVersion;
  final DateTime? savedAt;
  final BusinessConfig businessConfig;
  final List<Product> products;
  final List<Customer> customers;
  final List<Bill> bills;
  final List<Expense> expenses;
  final List<CustomerPaymentEntry> customerPaymentEntries;
  final List<CashBookDay> cashBookDays;
  final List<Supplier> suppliers;
  final List<PurchaseEntry> purchases;
  final List<SalesReturn> salesReturns;
  final List<StockAdjustment> stockAdjustments;
  final List<Quotation> quotations;
  final List<AppUser> users;
  final String? currentUserId;
  final bool singleUserMode;
  final bool requirePinOnOpen;
  final int autoLockMinutes;
  final List<TableOrder> tableOrders;
  final List<JobCard> jobCards;
  final List<SerialNumber> serialNumbers;

  const PersistedAppState({
    this.schemaVersion = 1,
    this.savedAt,
    this.businessConfig = const BusinessConfig(),
    this.products = const [],
    this.customers = const [],
    this.bills = const [],
    this.expenses = const [],
    this.customerPaymentEntries = const [],
    this.cashBookDays = const [],
    this.suppliers = const [],
    this.purchases = const [],
    this.salesReturns = const [],
    this.stockAdjustments = const [],
    this.quotations = const [],
    this.users = const [],
    this.currentUserId,
    this.singleUserMode = true,
    this.requirePinOnOpen = true,
    this.autoLockMinutes = 5,
    this.tableOrders = const [],
    this.jobCards = const [],
    this.serialNumbers = const [],
  });

  bool get hasData =>
      businessConfig.setupCompleted ||
      products.isNotEmpty ||
      customers.isNotEmpty ||
      bills.isNotEmpty ||
      expenses.isNotEmpty ||
      customerPaymentEntries.isNotEmpty ||
      cashBookDays.isNotEmpty ||
      suppliers.isNotEmpty ||
      purchases.isNotEmpty ||
      salesReturns.isNotEmpty ||
      stockAdjustments.isNotEmpty ||
      quotations.isNotEmpty ||
      users.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'savedAt': (savedAt ?? DateTime.now()).toIso8601String(),
      'businessConfig': businessConfig.toJson(),
      'products': products.map((product) => product.toJson()).toList(),
      'customers': customers.map((customer) => customer.toJson()).toList(),
      'bills': bills.map((bill) => bill.toJson()).toList(),
      'expenses': expenses.map((expense) => expense.toJson()).toList(),
      'customerPaymentEntries': customerPaymentEntries
          .map((entry) => entry.toJson())
          .toList(),
      'cashBookDays': cashBookDays.map((day) => day.toJson()).toList(),
      'suppliers': suppliers.map((s) => s.toJson()).toList(),
      'purchases': purchases.map((p) => p.toJson()).toList(),
      'salesReturns': salesReturns.map((r) => r.toJson()).toList(),
      'stockAdjustments': stockAdjustments.map((a) => a.toJson()).toList(),
      'quotations': quotations.map((q) => q.toJson()).toList(),
      'users': users.map((user) => user.toJson()).toList(),
      'currentUserId': currentUserId,
      'singleUserMode': singleUserMode,
      'requirePinOnOpen': requirePinOnOpen,
      'autoLockMinutes': autoLockMinutes,
      'tableOrders': tableOrders.map((t) => t.toJson()).toList(),
      'jobCards': jobCards.map((j) => j.toJson()).toList(),
      'serialNumbers': serialNumbers.map((s) => s.toJson()).toList(),
    };
  }

  factory PersistedAppState.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] as List<dynamic>? ?? const [];
    final rawCustomers = json['customers'] as List<dynamic>? ?? const [];
    final rawBills = json['bills'] as List<dynamic>? ?? const [];
    final rawExpenses = json['expenses'] as List<dynamic>? ?? const [];
    final rawPaymentEntries =
        json['customerPaymentEntries'] as List<dynamic>? ?? const [];
    final rawCashBookDays = json['cashBookDays'] as List<dynamic>? ?? const [];
    final rawSuppliers = json['suppliers'] as List<dynamic>? ?? const [];
    final rawPurchases = json['purchases'] as List<dynamic>? ?? const [];
    final rawSalesReturns =
        json['salesReturns'] as List<dynamic>? ?? const [];
    final rawStockAdjustments =
        json['stockAdjustments'] as List<dynamic>? ?? const [];
    final rawQuotations = json['quotations'] as List<dynamic>? ?? const [];
    final rawUsers = json['users'] as List<dynamic>? ?? const [];
    final rawTableOrders = json['tableOrders'] as List<dynamic>? ?? const [];
    final rawJobCards = json['jobCards'] as List<dynamic>? ?? const [];
    final rawSerialNumbers = json['serialNumbers'] as List<dynamic>? ?? const [];
    final businessConfigJson =
        _mapOrNull(json['businessConfig']) ?? const <String, dynamic>{};

    return PersistedAppState(
      schemaVersion: _asInt(json['schemaVersion'], fallback: 1),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? ''),
      businessConfig: BusinessConfig.fromJson(businessConfigJson),
      products: rawProducts
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(Product.fromJson)
          .toList(),
      customers: rawCustomers
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(Customer.fromJson)
          .toList(),
      bills: rawBills
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(Bill.fromJson)
          .toList(),
      expenses: rawExpenses
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(Expense.fromJson)
          .toList(),
      customerPaymentEntries: rawPaymentEntries
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(CustomerPaymentEntry.fromJson)
          .toList(),
      cashBookDays: rawCashBookDays
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(CashBookDay.fromJson)
          .toList(),
      suppliers: rawSuppliers
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(Supplier.fromJson)
          .toList(),
      purchases: rawPurchases
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(PurchaseEntry.fromJson)
          .toList(),
      salesReturns: rawSalesReturns
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(SalesReturn.fromJson)
          .toList(),
      stockAdjustments: rawStockAdjustments
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(StockAdjustment.fromJson)
          .toList(),
      quotations: rawQuotations
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(Quotation.fromJson)
          .toList(),
      users: rawUsers
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(AppUser.fromJson)
          .toList(),
      currentUserId: json['currentUserId'] as String?,
      singleUserMode: json['singleUserMode'] as bool? ?? true,
      requirePinOnOpen: json['requirePinOnOpen'] as bool? ?? true,
      autoLockMinutes: _asInt(json['autoLockMinutes'], fallback: 5),
      tableOrders: rawTableOrders
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(TableOrder.fromJson)
          .toList(),
      jobCards: rawJobCards
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(JobCard.fromJson)
          .toList(),
      serialNumbers: rawSerialNumbers
          .map(_mapOrNull)
          .whereType<Map<String, dynamic>>()
          .map(SerialNumber.fromJson)
          .toList(),
    );
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }
}
