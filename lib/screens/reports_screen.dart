import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../providers/bill_provider.dart';
import '../providers/cash_book_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/product_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/report_service.dart';
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.reportsTitle, style: AppTypography.heading),
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: IconThemeData(color: AppColors.onSurface),
        automaticallyImplyLeading: true,
        actions: [
          TextButton.icon(
            onPressed: _pickDateRange,
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              '${_dateLabel(_from)} – ${_dateLabel(_to)}',
              style: AppTypography.label.copyWith(color: AppColors.primary),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'P&L'),
            Tab(text: 'Sales'),
            Tab(text: 'Inventory'),
            Tab(text: 'Cash Flow'),
            Tab(text: 'GST'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PnLTab(from: _from, to: _to),
          _SalesTab(from: _from, to: _to),
          _InventoryTab(),
          _CashFlowTab(from: _from, to: _to),
          _GstTab(from: _from, to: _to),
        ],
      ),
    );
  }

  static String _dateLabel(DateTime d) =>
      '${d.day}/${d.month}/${d.year.toString().substring(2)}';
}

// ─── P&L Tab ──────────────────────────────────────────────────────────────────

class _PnLTab extends StatelessWidget {
  final DateTime from;
  final DateTime to;

  const _PnLTab({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillProvider>().bills;
    final expenses = context.watch<ExpenseProvider>().expenses;
    final purchases = context.watch<PurchaseProvider>().purchases;
    final data = ReportService.getPnL(
      bills: bills,
      expenses: expenses,
      purchases: purchases,
      from: from,
      to: to,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(label: AppStrings.reportRevenue, value: data.revenue, color: AppColors.success),
          const SizedBox(height: AppSpacing.small),
          _SummaryCard(label: AppStrings.reportCogs, value: data.cogs, color: AppColors.warning),
          const SizedBox(height: AppSpacing.small),
          _SummaryCard(label: AppStrings.reportGrossProfit, value: data.grossProfit,
              color: data.grossProfit >= 0 ? AppColors.success : AppColors.error),
          const SizedBox(height: AppSpacing.small),
          _SummaryCard(label: AppStrings.reportExpenses, value: data.expenses, color: AppColors.error),
          const SizedBox(height: AppSpacing.small),
          _SummaryCard(label: AppStrings.reportNetProfit, value: data.netProfit,
              color: data.netProfit >= 0 ? AppColors.success : AppColors.error),
          if (data.monthly.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.large),
            Text(AppStrings.reportMonthlyTrend, style: AppTypography.heading.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.small),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: [
                    for (int i = 0; i < data.monthly.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: data.monthly[i].revenue,
                            color: AppColors.success.withValues(alpha: 0.8),
                            width: 10,
                          ),
                          BarChartRodData(
                            toY: data.monthly[i].expenses,
                            color: AppColors.error.withValues(alpha: 0.8),
                            width: 10,
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) => Text(
                          data.monthly[val.toInt()].label,
                          style: AppTypography.label.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                _Legend(color: AppColors.success, label: 'Revenue'),
                const SizedBox(width: 12),
                _Legend(color: AppColors.error, label: 'Expenses'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sales Tab ────────────────────────────────────────────────────────────────

class _SalesTab extends StatelessWidget {
  final DateTime from;
  final DateTime to;

  const _SalesTab({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillProvider>().bills;
    final data = ReportService.getSalesAnalytics(bills: bills, from: from, to: to);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Mode donut
          if (data.byPaymentMode.isNotEmpty) ...[
            Text(AppStrings.reportByPaymentMode, style: AppTypography.heading.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.small),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _paymentModeSections(data.byPaymentMode),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: 12,
              children: data.byPaymentMode.entries
                  .map((e) => _Legend(
                        color: _modeColor(e.key),
                        label: '${e.key}: ${Formatters.currency(e.value)}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.large),
          ],
          // Daily trend
          if (data.dailyTotals.isNotEmpty) ...[
            Text(AppStrings.reportDailyTrend, style: AppTypography.heading.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.small),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < data.dailyTotals.length; i++)
                          FlSpot(i.toDouble(), data.dailyTotals[i].total),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
          ],
          // Top products
          if (data.topProducts.isNotEmpty) ...[
            Text(AppStrings.reportTopProducts, style: AppTypography.heading.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.small),
            ...data.topProducts.map(
              (p) => _TopProductRow(product: p),
            ),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _paymentModeSections(Map<String, double> byMode) {
    final total = byMode.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return [];
    return byMode.entries.map((e) {
      final color = _modeColor(e.key);
      final pct = (e.value / total * 100).toStringAsFixed(1);
      return PieChartSectionData(
        value: e.value,
        color: color,
        radius: 60,
        title: '$pct%',
        titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
      );
    }).toList();
  }

  static Color _modeColor(String mode) {
    const colors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.error,
      AppColors.success,
    ];
    final idx = mode.hashCode.abs() % colors.length;
    return colors[idx];
  }
}

class _TopProductRow extends StatelessWidget {
  final TopProduct product;

  const _TopProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(product.name, style: AppTypography.body),
          ),
          Text(
            Formatters.currency(product.revenue),
            style: AppTypography.body.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Inventory Tab ────────────────────────────────────────────────────────────

class _InventoryTab extends StatelessWidget {
  const _InventoryTab();

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductProvider>().products;
    final data = ReportService.getInventoryReport(products);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: AppStrings.reportStockValue,
                  value: data.totalStockValue,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: _CountCard(
                  label: AppStrings.reportTotalSkus,
                  count: data.totalSkus,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          _ProductListSection(
            title: AppStrings.lowStockFilter,
            products: data.lowStockItems,
            badgeColor: AppColors.warning,
          ),
          _ProductListSection(
            title: AppStrings.outOfStockFilter,
            products: data.outOfStockItems,
            badgeColor: AppColors.error,
          ),
          _ProductListSection(
            title: AppStrings.reportDeadStock30,
            products: data.deadStock30,
            badgeColor: AppColors.muted,
          ),
        ],
      ),
    );
  }
}

class _ProductListSection extends StatelessWidget {
  final String title;
  final List<dynamic> products;
  final Color badgeColor;

  const _ProductListSection({
    required this.title,
    required this.products,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTypography.heading.copyWith(fontSize: 15)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${products.length}',
                style: AppTypography.label.copyWith(color: badgeColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        ...products.map(
          (p) => _InventoryRow(product: p as dynamic),
        ),
        const SizedBox(height: AppSpacing.medium),
      ],
    );
  }
}

class _InventoryRow extends StatelessWidget {
  final dynamic product;

  const _InventoryRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(product.name as String, style: AppTypography.body)),
          Text(
            'Qty: ${product.stockQuantity}',
            style: AppTypography.label.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ─── Cash Flow Tab ────────────────────────────────────────────────────────────

class _CashFlowTab extends StatelessWidget {
  final DateTime from;
  final DateTime to;

  const _CashFlowTab({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final cashBookProvider = context.watch<CashBookProvider>();
    final data = ReportService.getCashFlow(
      cashBookProvider: cashBookProvider,
      from: from,
      to: to,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryCard(label: AppStrings.totalInflows, value: data.totalInflows, color: AppColors.success),
          const SizedBox(height: AppSpacing.small),
          _SummaryCard(label: AppStrings.totalOutflows, value: data.totalOutflows, color: AppColors.error),
          const SizedBox(height: AppSpacing.small),
          _SummaryCard(
            label: AppStrings.netCashFlow,
            value: data.netCashFlow,
            color: data.netCashFlow >= 0 ? AppColors.success : AppColors.error,
          ),
          if (data.dailyBalance.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.large),
            Text(AppStrings.reportDailyBalance, style: AppTypography.heading.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.small),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < data.dailyBalance.length; i++)
                          FlSpot(i.toDouble(), data.dailyBalance[i].total),
                      ],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── GST Tab ──────────────────────────────────────────────────────────────────

class _GstTab extends StatelessWidget {
  final DateTime from;
  final DateTime to;

  const _GstTab({required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final bills = context.watch<BillProvider>().bills;
    final data = ReportService.getGstSummary(bills: bills, from: from, to: to);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CountCard(label: AppStrings.totalBills, count: data.totalBills),
          const SizedBox(height: AppSpacing.small),
          _SummaryCard(label: AppStrings.totalTaxableValue, value: data.totalTaxable),
          const SizedBox(height: AppSpacing.small),
          _SummaryCard(label: AppStrings.totalCgst, value: data.totalCgst, color: AppColors.primary),
          const SizedBox(height: AppSpacing.small),
          _SummaryCard(label: AppStrings.totalSgst, value: data.totalSgst, color: AppColors.primary),
          if (data.totalIgst > 0) ...[
            const SizedBox(height: AppSpacing.small),
            _SummaryCard(label: AppStrings.totalIgst, value: data.totalIgst, color: AppColors.warning),
          ],
          if (data.billsByGstSlab.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.large),
            Text(AppStrings.reportByGstSlab, style: AppTypography.heading.copyWith(fontSize: 15)),
            const SizedBox(height: AppSpacing.small),
            ...data.billsByGstSlab.entries.map(
              (e) => _GstSlabRow(rate: e.key, count: e.value),
            ),
          ],
          const SizedBox(height: AppSpacing.large),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/gstr1-export'),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text(AppStrings.gstr1Export),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GstSlabRow extends StatelessWidget {
  final double rate;
  final int count;

  const _GstSlabRow({required this.rate, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Text(
            'GST ${rate.toStringAsFixed(0)}%',
            style: AppTypography.body,
          ),
          const Spacer(),
          Text(
            '$count line items',
            style: AppTypography.label.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _SummaryCard({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.label),
          Text(
            Formatters.currency(value),
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int count;

  const _CountCard({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.label),
          Text(
            '$count',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.label.copyWith(fontSize: 11)),
      ],
    );
  }
}
