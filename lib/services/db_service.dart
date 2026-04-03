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
import '../models/stock_adjustment.dart';
import '../models/supplier.dart';
import '../models/table_order.dart';
import '../models/app_user.dart';
import 'supabase_service.dart';

/// Reads and writes all app data to Supabase.
///
/// Schema per table: id (text/uuid) | business_id (uuid) | data (jsonb)
/// CashBookDay uses a date-string id; all other models use their UUID id field.
class DbService {
  final String businessId;

  DbService(this.businessId);

  SupabaseClient get _client => SupabaseService.client;

  // ── Generic helpers ─────────────────────────────────────────────────────────

  Future<void> _upsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    // .select() forces Supabase to throw on RLS violations instead of silently
    // doing nothing (upsert without .select() can return 0 rows with no error).
    await _client.from(table).upsert(rows).select();
  }

  Future<List<Map<String, dynamic>>> _selectAll(String table) async {
    final rows = await _client
        .from(table)
        .select('data')
        .eq('business_id', businessId);
    return rows
        .map(
          (r) => (r['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        )
        .toList();
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
    );
  }
}
