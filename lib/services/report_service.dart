import '../models/bill.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../models/purchase_entry.dart';
import '../providers/cash_book_provider.dart';

// ─── Data classes ────────────────────────────────────────────────────────────

class PnLData {
  final double revenue;
  final double cogs;
  final double grossProfit;
  final double expenses;
  final double netProfit;
  final List<MonthlyPnL> monthly;

  const PnLData({
    this.revenue = 0,
    this.cogs = 0,
    this.grossProfit = 0,
    this.expenses = 0,
    this.netProfit = 0,
    this.monthly = const [],
  });
}

class MonthlyPnL {
  final String label; // 'Jan', 'Feb', ...
  final double revenue;
  final double expenses;

  const MonthlyPnL({
    required this.label,
    required this.revenue,
    required this.expenses,
  });
}

class SalesAnalyticsData {
  final Map<String, double> byPaymentMode; // mode → total
  final List<TopProduct> topProducts;
  final List<DailyTotal> dailyTotals;

  const SalesAnalyticsData({
    this.byPaymentMode = const {},
    this.topProducts = const [],
    this.dailyTotals = const [],
  });
}

class TopProduct {
  final String name;
  final double revenue;
  final double quantitySold;

  const TopProduct({
    required this.name,
    required this.revenue,
    required this.quantitySold,
  });
}

class DailyTotal {
  final DateTime date;
  final double total;

  const DailyTotal({required this.date, required this.total});
}

class InventoryReportData {
  final double totalStockValue;
  final int totalSkus;
  final List<Product> lowStockItems;
  final List<Product> outOfStockItems;
  final List<Product> deadStock30;
  final List<Product> deadStock60;
  final List<Product> deadStock90;

  const InventoryReportData({
    this.totalStockValue = 0,
    this.totalSkus = 0,
    this.lowStockItems = const [],
    this.outOfStockItems = const [],
    this.deadStock30 = const [],
    this.deadStock60 = const [],
    this.deadStock90 = const [],
  });
}

class CashFlowData {
  final double totalInflows;
  final double totalOutflows;
  final double netCashFlow;
  final List<DailyTotal> dailyBalance;

  const CashFlowData({
    this.totalInflows = 0,
    this.totalOutflows = 0,
    this.netCashFlow = 0,
    this.dailyBalance = const [],
  });
}

class GstSummaryData {
  final double totalTaxable;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final int totalBills;
  final Map<double, int> billsByGstSlab; // rate → count

  const GstSummaryData({
    this.totalTaxable = 0,
    this.totalCgst = 0,
    this.totalSgst = 0,
    this.totalIgst = 0,
    this.totalBills = 0,
    this.billsByGstSlab = const {},
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

class ReportService {
  ReportService._();

  static List<Bill> _filterBills(
    List<Bill> bills,
    DateTime from,
    DateTime to,
  ) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return bills
        .where(
          (b) =>
              !b.timestamp.isBefore(start) && !b.timestamp.isAfter(end),
        )
        .toList();
  }

  static List<Expense> _filterExpenses(
    List<Expense> expenses,
    DateTime from,
    DateTime to,
  ) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59);
    return expenses
        .where(
          (e) => !e.date.isBefore(start) && !e.date.isAfter(end),
        )
        .toList();
  }

  static PnLData getPnL({
    required List<Bill> bills,
    required List<Expense> expenses,
    required List<PurchaseEntry> purchases,
    required DateTime from,
    required DateTime to,
  }) {
    final filtered = _filterBills(bills, from, to);
    final filteredExpenses = _filterExpenses(expenses, from, to);

    final revenue = filtered.fold<double>(
      0,
      (sum, b) => sum + b.grandTotal,
    );

    // COGS: use product cost prices from bill line items (actual sold goods cost).
    // Falls back to purchase entries for products with no cost price set.
    final cogsfromBills = filtered.fold<double>(0, (sum, bill) {
      return sum +
          bill.lineItems.fold<double>(
            0,
            (s, item) => s + item.product.costPrice * item.quantity,
          );
    });
    final cogsStart = DateTime(from.year, from.month, from.day);
    final cogsEnd = DateTime(to.year, to.month, to.day, 23, 59, 59);
    final cogsFromPurchases = purchases
        .where(
          (p) =>
              !p.date.isBefore(cogsStart) && !p.date.isAfter(cogsEnd),
        )
        .fold<double>(0, (sum, p) => sum + p.totalAmount);
    // Prefer bill-level COGS if any products have cost prices set
    final cogs = cogsfromBills > 0 ? cogsfromBills : cogsFromPurchases;

    final grossProfit = revenue - cogs;
    final totalExpenses = filteredExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final netProfit = grossProfit - totalExpenses;

    // Build monthly breakdown (last 6 months within range)
    final monthly = _buildMonthlyPnL(filtered, filteredExpenses, from, to);

    return PnLData(
      revenue: revenue,
      cogs: cogs,
      grossProfit: grossProfit,
      expenses: totalExpenses,
      netProfit: netProfit,
      monthly: monthly,
    );
  }

  static List<MonthlyPnL> _buildMonthlyPnL(
    List<Bill> bills,
    List<Expense> expenses,
    DateTime from,
    DateTime to,
  ) {
    final result = <MonthlyPnL>[];
    var cursor = DateTime(from.year, from.month, 1);
    final endMonth = DateTime(to.year, to.month, 1);

    while (!cursor.isAfter(endMonth)) {
      final monthBills = bills.where(
        (b) =>
            b.timestamp.year == cursor.year &&
            b.timestamp.month == cursor.month,
      );
      final monthExpenses = expenses.where(
        (e) =>
            e.date.year == cursor.year && e.date.month == cursor.month,
      );
      result.add(MonthlyPnL(
        label: _monthLabel(cursor),
        revenue: monthBills.fold(0, (s, b) => s + b.grandTotal),
        expenses: monthExpenses.fold(0, (s, e) => s + e.amount),
      ));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
    return result;
  }

  static String _monthLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[d.month - 1];
  }

  static SalesAnalyticsData getSalesAnalytics({
    required List<Bill> bills,
    required DateTime from,
    required DateTime to,
  }) {
    final filtered = _filterBills(bills, from, to);

    // By payment mode
    final byMode = <String, double>{};
    for (final b in filtered) {
      final mode = b.paymentMode.name;
      byMode[mode] = (byMode[mode] ?? 0) + b.grandTotal;
    }

    // Top 10 products
    final productRevenue = <String, double>{};
    final productQty = <String, double>{};
    for (final b in filtered) {
      for (final item in b.lineItems) {
        final name = item.product.name;
        productRevenue[name] =
            (productRevenue[name] ?? 0) + item.subtotal;
        productQty[name] = (productQty[name] ?? 0) + item.quantity;
      }
    }
    final topProducts = productRevenue.entries
        .map(
          (e) => TopProduct(
            name: e.key,
            revenue: e.value,
            quantitySold: productQty[e.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    final top10 = topProducts.take(10).toList();

    // Daily totals
    final dailyMap = <String, double>{};
    for (final b in filtered) {
      final key =
          '${b.timestamp.year}-${b.timestamp.month}-${b.timestamp.day}';
      dailyMap[key] = (dailyMap[key] ?? 0) + b.grandTotal;
    }
    final dailyTotals = dailyMap.entries
        .map((e) {
          final parts = e.key.split('-');
          return DailyTotal(
            date: DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            ),
            total: e.value,
          );
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SalesAnalyticsData(
      byPaymentMode: byMode,
      topProducts: top10,
      dailyTotals: dailyTotals,
    );
  }

  static InventoryReportData getInventoryReport(List<Product> products) {
    final now = DateTime.now();
    final cutoff30 = now.subtract(const Duration(days: 30));
    final cutoff60 = now.subtract(const Duration(days: 60));
    final cutoff90 = now.subtract(const Duration(days: 90));

    double totalValue = 0;
    for (final p in products) {
      totalValue += p.sellingPrice * p.stockQuantity;
    }

    return InventoryReportData(
      totalStockValue: totalValue,
      totalSkus: products.length,
      lowStockItems: products
          .where(
            (p) =>
                p.stockQuantity > 0 &&
                p.stockQuantity <= p.lowStockThreshold &&
                p.lowStockThreshold > 0,
          )
          .toList(),
      outOfStockItems: products.where((p) => p.stockQuantity <= 0).toList(),
      deadStock30: products
          .where(
            (p) =>
                p.stockQuantity > 0 &&
                p.createdAt.isBefore(cutoff30),
          )
          .toList(),
      deadStock60: products
          .where(
            (p) =>
                p.stockQuantity > 0 &&
                p.createdAt.isBefore(cutoff60),
          )
          .toList(),
      deadStock90: products
          .where(
            (p) =>
                p.stockQuantity > 0 &&
                p.createdAt.isBefore(cutoff90),
          )
          .toList(),
    );
  }

  static CashFlowData getCashFlow({
    required CashBookProvider cashBookProvider,
    required DateTime from,
    required DateTime to,
  }) {
    double totalInflows = 0;
    double totalOutflows = 0;
    final dailyBalance = <DailyTotal>[];

    var cursor = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    while (!cursor.isAfter(end)) {
      final day = cashBookProvider.getCashBookDay(cursor);
      totalInflows += day.totalInflows;
      totalOutflows += day.totalOutflows;
      dailyBalance.add(
        DailyTotal(date: cursor, total: day.closingBalance),
      );
      cursor = cursor.add(const Duration(days: 1));
    }

    return CashFlowData(
      totalInflows: totalInflows,
      totalOutflows: totalOutflows,
      netCashFlow: totalInflows - totalOutflows,
      dailyBalance: dailyBalance,
    );
  }

  static GstSummaryData getGstSummary({
    required List<Bill> bills,
    required DateTime from,
    required DateTime to,
  }) {
    final filtered = _filterBills(bills, from, to);

    double totalTaxable = 0;
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;
    final slabCounts = <double, int>{};

    for (final b in filtered) {
      totalCgst += b.cgst;
      totalSgst += b.sgst;
      totalIgst += b.igst;
      for (final item in b.lineItems) {
        totalTaxable += item.taxableAmount;
        if (item.gstRate > 0) {
          slabCounts[item.gstRate] =
              (slabCounts[item.gstRate] ?? 0) + 1;
        }
      }
    }

    return GstSummaryData(
      totalTaxable: totalTaxable,
      totalCgst: totalCgst,
      totalSgst: totalSgst,
      totalIgst: totalIgst,
      totalBills: filtered.length,
      billsByGstSlab: slabCounts,
    );
  }
}
