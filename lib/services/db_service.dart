import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bill.dart';
import '../models/business_config.dart';
import '../models/cash_book_entry.dart';
import '../models/customer.dart';
import '../models/customer_payment_entry.dart';
import '../models/expense.dart';
import '../models/job_card.dart';
import '../models/persisted_app_state.dart';
import '../models/product.dart';
import '../models/purchase_entry.dart';
import '../models/quotation.dart';
import '../models/sales_return.dart';
import '../models/serial_number.dart';
import '../models/stock_adjustment.dart';
import '../models/supplier.dart';
import '../models/table_order.dart';
import '../models/app_user.dart';
import 'supabase_service.dart';

/// Reads and writes all app data to Supabase.
///
/// Schema per table: id (text/uuid) | business_id (uuid) | data (jsonb)
/// CashBookDay uses a date-string id; all other models use their UUID id field.
///
/// #42 JSONB→relational (slice 1–3): bills and products have flat columns
/// populated by DB triggers.  Slice 3 adds a product_batches relational table
/// and rewrites complete_bill() to use it.  Server-side helpers
/// (loadBillsForDateRange, loadBillsByCustomer, loadProductsByCategory,
/// loadLowStockProducts, loadExpiringBatches) use flat columns / views for
/// push-down filtering.
class DbService {
  final String businessId;

  DbService(this.businessId);

  SupabaseClient get _client => SupabaseService.client;

  // ── Retry helper ────────────────────────────────────────────────────────────

  /// Retries [operation] up to [maxAttempts] times with exponential backoff
  /// (1 s, 2 s, 4 s). Rethrows the last error if all attempts fail.
  static Future<T> _retryWithBackoff<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
  }) async {
    var delay = const Duration(seconds: 1);
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(delay);
        delay *= 2;
      }
    }
    // Unreachable — the loop always returns or rethrows.
    throw StateError('_retryWithBackoff: unreachable');
  }

  // ── Generic helpers ─────────────────────────────────────────────────────────

  Future<void> _upsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    // .select() forces Supabase to throw on RLS violations instead of silently
    // doing nothing (upsert without .select() can return 0 rows with no error).
    await _retryWithBackoff(
      () => _client.from(table).upsert(rows).select(),
    );
  }

  Future<List<Map<String, dynamic>>> _selectAll(String table) async {
    try {
      return await _retryWithBackoff(() async {
        final rows = await _client
            .from(table)
            .select('data')
            .eq('business_id', businessId);
        return rows
            .map(
              (r) =>
                  (r['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
            )
            .toList();
      });
    } catch (e) {
      // Table may not exist in this deployment — return empty list rather than
      // failing the entire loadAll() call.
      debugPrint('BillReady: skipping table $table: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _toRows<T>(
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) {
    return items.map((item) {
      final data = toJson(item);
      return {'id': data['id'], 'business_id': businessId, 'data': data};
    }).toList();
  }

  // ── Per-collection writes ───────────────────────────────────────────────────

  Future<void> saveConfig(BusinessConfig config, {
    String? currentUserId,
    bool singleUserMode = true,
    bool requirePinOnOpen = true,
    int autoLockMinutes = 5,
  }) async {
    await _client.from('businesses').update({
      'config': {
        ...config.toJson(),
        'currentUserId': currentUserId,
        'singleUserMode': singleUserMode,
        'requirePinOnOpen': requirePinOnOpen,
        'autoLockMinutes': autoLockMinutes,
      },
    }).eq('id', businessId);
  }

  Future<void> deleteRecord(String table, String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  Future<void> saveProducts(List<Product> products) =>
      _upsert('products', _toRows(products, (p) => p.toJson()));

  Future<void> saveCustomers(List<Customer> customers) =>
      _upsert('customers', _toRows(customers, (c) => c.toJson()));

  Future<void> saveCustomerPaymentEntries(
    List<CustomerPaymentEntry> entries,
  ) => _upsert(
    'customer_payment_entries',
    _toRows(entries, (e) => e.toJson()),
  );

  Future<void> saveBills(List<Bill> bills) =>
      _upsert('bills', _toRows(bills, (b) => b.toJson()));

  Future<void> saveExpenses(List<Expense> expenses) =>
      _upsert('expenses', _toRows(expenses, (e) => e.toJson()));

  Future<void> saveCashBook(List<CashBookDay> days) async {
    if (days.isEmpty) return;
    final rows = days.map((day) {
      final data = day.toJson();
      final dateKey = day.date.toIso8601String().substring(0, 10);
      // Prefix with businessId to ensure uniqueness across businesses
      // (date-only keys would collide for the same date across different businesses)
      return {'id': '${businessId}_$dateKey', 'business_id': businessId, 'data': data};
    }).toList();
    await _client.from('cash_book').upsert(rows);
  }

  Future<void> saveSuppliers(List<Supplier> suppliers) =>
      _upsert('suppliers', _toRows(suppliers, (s) => s.toJson()));

  Future<void> savePurchases(List<PurchaseEntry> purchases) async {
    if (purchases.isNotEmpty) {
      await _upsert('purchases', _toRows(purchases, (p) => p.toJson()));
    }
    // Delete any rows in Supabase that are no longer in the current list
    final ids = purchases.map((p) => p.id).toList();
    if (ids.isEmpty) {
      await _client.from('purchases').delete().eq('business_id', businessId);
    } else {
      await _client
          .from('purchases')
          .delete()
          .eq('business_id', businessId)
          .not('id', 'in', ids);
    }
  }

  Future<void> saveSalesReturns(List<SalesReturn> returns) =>
      _upsert('sales_returns', _toRows(returns, (r) => r.toJson()));

  Future<void> saveStockAdjustments(List<StockAdjustment> adjustments) =>
      _upsert('stock_adjustments', _toRows(adjustments, (a) => a.toJson()));

  Future<void> saveQuotations(List<Quotation> quotations) =>
      _upsert('quotations', _toRows(quotations, (q) => q.toJson()));

  Future<void> saveUsers(List<AppUser> users) =>
      _upsert('users', _toRows(users, (u) => u.toJson()));

  Future<void> saveTableOrders(List<TableOrder> orders) =>
      _upsert('table_orders', _toRows(orders, (o) => o.toJson()));

  Future<void> saveJobCards(List<JobCard> jobCards) =>
      _upsert('job_cards', _toRows(jobCards, (j) => j.toJson()));

  Future<void> saveSerialNumbers(List<SerialNumber> serials) =>
      _upsert('serial_numbers', _toRows(serials, (s) => s.toJson()));

  // ── Bulk persist ─────────────────────────────────────────────────────────────

  Future<void> persistAll(PersistedAppState state) async {
    await Future.wait([
      saveConfig(
        state.businessConfig,
        currentUserId: state.currentUserId,
        singleUserMode: state.singleUserMode,
        requirePinOnOpen: state.requirePinOnOpen,
        autoLockMinutes: state.autoLockMinutes,
      ),
      saveProducts(state.products),
      saveCustomers(state.customers),
      saveCustomerPaymentEntries(state.customerPaymentEntries),
      saveBills(state.bills),
      saveExpenses(state.expenses),
      saveCashBook(state.cashBookDays),
      saveSuppliers(state.suppliers),
      savePurchases(state.purchases),
      saveSalesReturns(state.salesReturns),
      saveStockAdjustments(state.stockAdjustments),
      saveQuotations(state.quotations),
      saveUsers(state.users),
      saveTableOrders(state.tableOrders),
      saveJobCards(state.jobCards),
      saveSerialNumbers(state.serialNumbers),
    ]);
  }

  // ── Per-collection loads ─────────────────────────────────────────────────────

  Future<List<Bill>> loadBills() async {
    final rows = await _selectAll('bills');
    return rows
        .map((m) { try { return Bill.fromJson(m); } catch (_) { return null; } })
        .whereType<Bill>()
        .toList();
  }

  /// #42 slice 1 — server-side date-range filter using the flat
  /// [bill_timestamp] column.  Avoids loading all bills and filtering
  /// on the client.  Falls back to [loadBills] when the column is not
  /// yet populated (null timestamps from rows written before this
  /// migration).
  Future<List<Bill>> loadBillsForDateRange(
    DateTime from,
    DateTime to,
  ) async {
    try {
      final fromStr = DateTime(from.year, from.month, from.day)
          .toUtc()
          .toIso8601String();
      final toStr = DateTime(to.year, to.month, to.day, 23, 59, 59, 999)
          .toUtc()
          .toIso8601String();
      final rows = await _retryWithBackoff(
        () => _client
            .from('bills')
            .select('data')
            .eq('business_id', businessId)
            .gte('bill_timestamp', fromStr)
            .lte('bill_timestamp', toStr)
            .order('bill_timestamp', ascending: false),
      );
      return rows
          .map((r) {
            try {
              final m = (r['data'] as Map<String, dynamic>?) ?? {};
              return Bill.fromJson(m);
            } catch (_) {
              return null;
            }
          })
          .whereType<Bill>()
          .toList();
    } catch (_) {
      // Column not yet available — fall back to full load.
      return loadBills();
    }
  }

  /// #42 slice 1 — server-side customer filter using the flat
  /// [customer_id] column.
  Future<List<Bill>> loadBillsByCustomer(String customerId) async {
    try {
      final rows = await _retryWithBackoff(
        () => _client
            .from('bills')
            .select('data')
            .eq('business_id', businessId)
            .eq('customer_id', customerId)
            .order('bill_timestamp', ascending: false),
      );
      return rows
          .map((r) {
            try {
              final m = (r['data'] as Map<String, dynamic>?) ?? {};
              return Bill.fromJson(m);
            } catch (_) {
              return null;
            }
          })
          .whereType<Bill>()
          .toList();
    } catch (_) {
      return loadBills();
    }
  }

  Future<List<Product>> loadProducts() async {
    final rows = await _selectAll('products');
    return rows.map((m) { try { return Product.fromJson(m); } catch (_) { return null; } }).whereType<Product>().toList();
  }

  /// #42 slice 2 — server-side category filter using the flat
  /// [category] column.
  Future<List<Product>> loadProductsByCategory(String category) async {
    try {
      final rows = await _retryWithBackoff(
        () => _client
            .from('products')
            .select('data')
            .eq('business_id', businessId)
            .eq('category', category)
            .order('product_name'),
      );
      return rows
          .map((r) {
            try {
              final m = (r['data'] as Map<String, dynamic>?) ?? {};
              return Product.fromJson(m);
            } catch (_) {
              return null;
            }
          })
          .whereType<Product>()
          .toList();
    } catch (_) {
      return loadProducts();
    }
  }

  /// #42 slice 2 — returns products below their low-stock threshold
  /// using the [low_stock_products] view created by the migration.
  Future<List<Map<String, dynamic>>> loadLowStockProducts() async {
    try {
      return await _retryWithBackoff(
        () => _client
            .from('low_stock_products')
            .select()
            .eq('business_id', businessId),
      );
    } catch (_) {
      return [];
    }
  }

  /// #42 slice 3 — returns batches expiring within 90 days or already
  /// expired, using the [expiring_batches] view.
  Future<List<Map<String, dynamic>>> loadExpiringBatches() async {
    try {
      return await _retryWithBackoff(
        () => _client
            .from('expiring_batches')
            .select()
            .eq('business_id', businessId)
            .order('expiry_date'),
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Customer>> loadCustomers() async {
    final rows = await _selectAll('customers');
    return rows.map((m) { try { return Customer.fromJson(m); } catch (_) { return null; } }).whereType<Customer>().toList();
  }

  Future<List<Expense>> loadExpenses() async {
    final rows = await _selectAll('expenses');
    return rows.map((m) { try { return Expense.fromJson(m); } catch (_) { return null; } }).whereType<Expense>().toList();
  }

  Future<List<PurchaseEntry>> loadPurchases() async {
    final rows = await _selectAll('purchases');
    return rows.map((m) { try { return PurchaseEntry.fromJson(m); } catch (_) { return null; } }).whereType<PurchaseEntry>().toList();
  }

  Future<List<Quotation>> loadQuotations() async {
    final rows = await _selectAll('quotations');
    return rows.map((m) { try { return Quotation.fromJson(m); } catch (_) { return null; } }).whereType<Quotation>().toList();
  }

  Future<List<Supplier>> loadSuppliers() async {
    final rows = await _selectAll('suppliers');
    return rows.map((m) { try { return Supplier.fromJson(m); } catch (_) { return null; } }).whereType<Supplier>().toList();
  }

  // ── Load all ─────────────────────────────────────────────────────────────────

  Future<PersistedAppState> loadAll() async {
    final results = await Future.wait([
      _selectAll('products'),
      _selectAll('customers'),
      _selectAll('customer_payment_entries'),
      _selectAll('bills'),
      _selectAll('expenses'),
      _selectAll('cash_book'),
      _selectAll('suppliers'),
      _selectAll('purchases'),
      _selectAll('sales_returns'),
      _selectAll('stock_adjustments'),
      _selectAll('quotations'),
      _selectAll('users'),
      _selectAll('table_orders'),
      _selectAll('job_cards'),
      _selectAll('serial_numbers'),
    ]);

    final bizRow = await _client
        .from('businesses')
        .select('config')
        .eq('id', businessId)
        .single();
    final cfg = (bizRow['config'] as Map<String, dynamic>?) ?? {};

    BusinessConfig businessConfig;
    try {
      businessConfig = BusinessConfig.fromJson(cfg);
    } catch (_) {
      businessConfig = const BusinessConfig();
    }

    T? parse<T>(Map<String, dynamic> m, T Function(Map<String, dynamic>) f) {
      try {
        return f(m);
      } catch (_) {
        return null;
      }
    }

    return PersistedAppState(
      businessConfig: businessConfig,
      currentUserId: cfg['currentUserId'] as String?,
      singleUserMode: cfg['singleUserMode'] as bool? ?? true,
      requirePinOnOpen: cfg['requirePinOnOpen'] as bool? ?? true,
      autoLockMinutes: (cfg['autoLockMinutes'] as num?)?.toInt() ?? 5,
      products: results[0]
          .map((m) => parse(m, Product.fromJson))
          .whereType<Product>()
          .toList(),
      customers: results[1]
          .map((m) => parse(m, Customer.fromJson))
          .whereType<Customer>()
          .toList(),
      customerPaymentEntries: results[2]
          .map((m) => parse(m, CustomerPaymentEntry.fromJson))
          .whereType<CustomerPaymentEntry>()
          .toList(),
      bills: results[3]
          .map((m) => parse(m, Bill.fromJson))
          .whereType<Bill>()
          .toList(),
      expenses: results[4]
          .map((m) => parse(m, Expense.fromJson))
          .whereType<Expense>()
          .toList(),
      cashBookDays: results[5]
          .map((m) => parse(m, CashBookDay.fromJson))
          .whereType<CashBookDay>()
          .toList(),
      suppliers: results[6]
          .map((m) => parse(m, Supplier.fromJson))
          .whereType<Supplier>()
          .toList(),
      purchases: results[7]
          .map((m) => parse(m, PurchaseEntry.fromJson))
          .whereType<PurchaseEntry>()
          .toList(),
      salesReturns: results[8]
          .map((m) => parse(m, SalesReturn.fromJson))
          .whereType<SalesReturn>()
          .toList(),
      stockAdjustments: results[9]
          .map((m) => parse(m, StockAdjustment.fromJson))
          .whereType<StockAdjustment>()
          .toList(),
      quotations: results[10]
          .map((m) => parse(m, Quotation.fromJson))
          .whereType<Quotation>()
          .toList(),
      users: results[11]
          .map((m) => parse(m, AppUser.fromJson))
          .whereType<AppUser>()
          .toList(),
      tableOrders: results[12]
          .map((m) => parse(m, TableOrder.fromJson))
          .whereType<TableOrder>()
          .toList(),
      jobCards: results[13]
          .map((m) => parse(m, JobCard.fromJson))
          .whereType<JobCard>()
          .toList(),
      serialNumbers: results[14]
          .map((m) => parse(m, SerialNumber.fromJson))
          .whereType<SerialNumber>()
          .toList(),
    );
  }
}
