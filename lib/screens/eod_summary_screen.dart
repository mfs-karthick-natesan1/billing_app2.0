import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/expense_category.dart';
import '../models/payment_info.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/cash_book_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/return_provider.dart';

class EodSummaryScreen extends StatelessWidget {
  final DateTime? date;

  const EodSummaryScreen({super.key, this.date});

  @override
  Widget build(BuildContext context) {
    final targetDate = date ?? DateTime.now();
    final businessConfig = context.watch<BusinessConfigProvider>();
    final billProvider = context.watch<BillProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final purchaseProvider = context.watch<PurchaseProvider>();
    final returnProvider = context.watch<ReturnProvider>();
    final cashBookProvider = context.watch<CashBookProvider>();

    // Bills for the target date
    final dayBills = billProvider.bills.where((b) =>
        b.timestamp.year == targetDate.year &&
        b.timestamp.month == targetDate.month &&
        b.timestamp.day == targetDate.day).toList();

    final totalRevenue = dayBills.fold(0.0, (s, b) => s + b.grandTotal);
    final billCount = dayBills.length;
    final cashCollected = dayBills
        .where((b) => b.paymentMode == PaymentMode.cash)
        .fold(0.0, (s, b) => s + b.grandTotal);
    final upiCollected = dayBills
        .where((b) => b.paymentMode == PaymentMode.upi)
        .fold(0.0, (s, b) => s + b.grandTotal);
    final creditBills =
        dayBills.where((b) => b.paymentMode == PaymentMode.credit).toList();
    final creditGiven =
        creditBills.fold(0.0, (s, b) => s + b.creditAmount);
    final creditCustomerCount = creditBills
        .map((b) => b.customer?.id)
        .where((id) => id != null)
        .toSet()
        .length;
    final totalDiscount = dayBills.fold(0.0, (s, b) => s + b.totalDiscount);

    // Top products
    final productSales = <String, _ProductStat>{};
    for (final bill in dayBills) {
      for (final item in bill.lineItems) {
        final key = item.product.id;
        final existing = productSales[key];
        if (existing != null) {
          existing.qty += item.quantity;
          existing.amount += item.subtotal;
        } else {
          productSales[key] = _ProductStat(
            name: item.product.name,
            qty: item.quantity,
            amount: item.subtotal,
          );
        }
      }
    }
    final topProducts = productSales.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top5 = topProducts.take(5).toList();

    // Expenses
    final dayExpenses = expenseProvider.getExpensesByDateRange(
      targetDate,
      targetDate,
    );
    final totalExpenses =
        dayExpenses.fold(0.0, (s, e) => s + e.amount);
    // Top 3 categories
    final catBreakdown = <String, double>{};
    for (final e in dayExpenses) {
      final label = e.customCategoryName ?? e.category.label;
      catBreakdown.update(label, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    final topCategories = catBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Purchases
    final dayPurchases = purchaseProvider.getPurchasesByDateRange(
      targetDate,
      targetDate,
    );
    final totalPurchases =
        dayPurchases.fold(0.0, (s, p) => s + p.totalAmount);

    // Returns
    final dayReturns = returnProvider.getReturnsByDateRange(
      targetDate,
      targetDate,
    );
    final totalReturns =
        dayReturns.fold(0.0, (s, r) => s + r.totalRefundAmount);

    // Net
    final netProfit = totalRevenue - totalExpenses - totalReturns;

    // Cash book
    final cashBook = cashBookProvider.getCashBookDay(targetDate);

    final businessName = businessConfig.businessName;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.eodTitle, style: AppTypography.heading),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSummary(
              context,
              businessName: businessName,
              date: targetDate,
              totalRevenue: totalRevenue,
              billCount: billCount,
              cashCollected: cashCollected,
              upiCollected: upiCollected,
              creditGiven: creditGiven,
              top5: top5,
              totalExpenses: totalExpenses,
              totalPurchases: totalPurchases,
              totalReturns: totalReturns,
              netProfit: netProfit,
              closingBalance: cashBook.closingBalance,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Column(
                children: [
                  Text(
                    businessName.isNotEmpty
                        ? businessName
                        : AppStrings.appName,
                    style: AppTypography.heading,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.date(targetDate),
                    style: AppTypography.label,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),

            // Sales Section
            _SectionHeader(title: AppStrings.eodSalesSection),
            const SizedBox(height: AppSpacing.small),
            _InfoRow(
              label: AppStrings.eodTotalBills,
              value: '$billCount ${AppStrings.eodBillsSuffix}',
            ),
            _InfoRow(
              label: AppStrings.eodCashCollected,
              value: Formatters.currency(cashCollected),
            ),
            _InfoRow(
              label: AppStrings.eodUpiCollected,
              value: Formatters.currency(upiCollected),
            ),
            if (creditGiven > 0)
              _InfoRow(
                label: AppStrings.eodCreditGiven,
                value:
                    '${Formatters.currency(creditGiven)} (${AppStrings.eodToCustomers} $creditCustomerCount ${AppStrings.eodCustomersSuffix})',
                valueColor: AppColors.error,
              ),
            if (totalDiscount > 0)
              _InfoRow(
                label: AppStrings.eodDiscounts,
                value: Formatters.currency(totalDiscount),
                valueColor: AppColors.error,
              ),
            const Divider(height: 24),
            _InfoRow(
              label: AppStrings.eodTotalRevenue,
              value: Formatters.currency(totalRevenue),
              isBold: true,
              valueColor: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.medium),

            // Top Products
            if (top5.isNotEmpty) ...[
              _SectionHeader(title: AppStrings.eodTopProducts),
              const SizedBox(height: AppSpacing.small),
              ...top5.asMap().entries.map(
                    (entry) => _InfoRow(
                      label:
                          '${entry.key + 1}. ${entry.value.name} (×${Formatters.qty(entry.value.qty)})',
                      value: Formatters.currency(entry.value.amount),
                    ),
                  ),
              const SizedBox(height: AppSpacing.medium),
            ],

            // Expenses
            if (totalExpenses > 0) ...[
              _SectionHeader(title: AppStrings.eodExpensesSection),
              const SizedBox(height: AppSpacing.small),
              ...topCategories.take(3).map(
                    (cat) => _InfoRow(
                      label: cat.key,
                      value: Formatters.currency(cat.value),
                    ),
                  ),
              if (topCategories.length > 3)
                _InfoRow(
                  label:
                      '+ ${topCategories.length - 3} more',
                  value: Formatters.currency(
                    topCategories
                        .skip(3)
                        .fold(0.0, (s, e) => s + e.value),
                  ),
                ),
              const Divider(height: 24),
              _InfoRow(
                label: AppStrings.eodExpensesSection,
                value: Formatters.currency(totalExpenses),
                isBold: true,
                valueColor: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.medium),
            ],

            // Purchases
            if (totalPurchases > 0) ...[
              _SectionHeader(title: AppStrings.eodPurchasesSection),
              const SizedBox(height: AppSpacing.small),
              _InfoRow(
                label: AppStrings.eodPurchasesSection,
                value: Formatters.currency(totalPurchases),
                valueColor: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.medium),
            ],

            // Returns
            if (totalReturns > 0) ...[
              _SectionHeader(title: AppStrings.eodReturnsSection),
              const SizedBox(height: AppSpacing.small),
              _InfoRow(
                label: '${dayReturns.length} returns',
                value: Formatters.currency(totalReturns),
                valueColor: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.medium),
            ],

            // Net Profit
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: netProfit >= 0
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.eodNetProfit,
                      style: AppTypography.heading.copyWith(fontSize: 16)),
                  Text(
                    Formatters.currency(netProfit),
                    style: AppTypography.currency.copyWith(
                      color: netProfit >= 0
                          ? AppColors.success
                          : AppColors.error,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),

            // Cash in Hand
            _SectionHeader(title: AppStrings.eodCashInHand),
            const SizedBox(height: AppSpacing.small),
            _InfoRow(
              label: AppStrings.eodOpeningBalance,
              value: Formatters.currency(cashBook.openingBalance),
            ),
            _InfoRow(
              label: AppStrings.eodClosingBalance,
              value: Formatters.currency(cashBook.closingBalance),
              isBold: true,
              valueColor: cashBook.closingBalance >= 0
                  ? AppColors.success
                  : AppColors.error,
            ),
            const SizedBox(height: AppSpacing.large),

            // Close Day button
            if (!cashBook.isClosed &&
                _isSameDay(targetDate, DateTime.now()))
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    cashBookProvider.closeDay(targetDate);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(AppStrings.dayClosedSuccess),
                      ),
                    );
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: Text(AppStrings.eodCloseCashBook),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                ),
              ),
            if (cashBook.isClosed)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.dayClosedBadge,
                      style: AppTypography.label.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.large),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _shareSummary(
    BuildContext context, {
    required String businessName,
    required DateTime date,
    required double totalRevenue,
    required int billCount,
    required double cashCollected,
    required double upiCollected,
    required double creditGiven,
    required List<_ProductStat> top5,
    required double totalExpenses,
    required double totalPurchases,
    required double totalReturns,
    required double netProfit,
    required double closingBalance,
  }) {
    final topItemNames =
        top5.take(3).map((p) => p.name).join(', ');

    final text = StringBuffer()
      ..writeln(
          '\u{1F4CA} *Daily Summary \u2014 ${businessName.isNotEmpty ? businessName : AppStrings.appName}*')
      ..writeln('\u{1F4C5} ${Formatters.date(date)}')
      ..writeln('\u2500' * 20)
      ..writeln(
          '\u{1F4B0} Sales: ${Formatters.currency(totalRevenue)} ($billCount bills)')
      ..writeln(
          '  Cash: ${Formatters.currency(cashCollected)} | UPI: ${Formatters.currency(upiCollected)}');
    if (creditGiven > 0) {
      text.writeln(
          '  Credit: ${Formatters.currency(creditGiven)}');
    }
    if (topItemNames.isNotEmpty) {
      text.writeln(
          '\u{1F4E6} Top Items: $topItemNames');
    }
    if (totalExpenses > 0) {
      text.writeln(
          '\u{1F4B8} Expenses: ${Formatters.currency(totalExpenses)}');
    }
    if (totalPurchases > 0) {
      text.writeln(
          '\u{1F6D2} Purchases: ${Formatters.currency(totalPurchases)}');
    }
    if (totalReturns > 0) {
      text.writeln(
          '\u21A9\uFE0F Returns: ${Formatters.currency(totalReturns)}');
    }
    text
      ..writeln('\u2500' * 20)
      ..writeln(
          '\u{1F4C8} Net Profit: ${Formatters.currency(netProfit)}')
      ..writeln(
          '\u{1F4B5} Cash in Hand: ${Formatters.currency(closingBalance)}');

    final shareText = text.toString();

    Share.share(shareText);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.heading.copyWith(fontSize: 16),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: isBold
                  ? AppTypography.body.copyWith(fontWeight: FontWeight.bold)
                  : AppTypography.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: (isBold
                    ? AppTypography.currency
                    : AppTypography.body)
                .copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _ProductStat {
  final String name;
  double qty;
  double amount;

  _ProductStat({
    required this.name,
    required this.qty,
    required this.amount,
  });
}
