import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/cash_book_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/return_provider.dart';
import '../widgets/app_fab.dart';
import '../widgets/web_constraint.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/bill_detail_sheet.dart';
import '../widgets/bill_history_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final businessConfig = context.watch<BusinessConfigProvider>();
    final billProvider = context.watch<BillProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final cashBookProvider = context.watch<CashBookProvider>();

    // Select only scalar values from providers to avoid full rebuilds on unrelated changes
    final lowStock = context.select<ProductProvider, int>((p) => p.lowStockCount);
    final outstanding = context.select<CustomerProvider, double>((p) => p.totalOutstanding);
    final todaysPurchases = context.select<PurchaseProvider, double>((p) => p.todayPurchaseTotal);
    final todayRefundTotal = context.select<ReturnProvider, double>((p) => p.todayRefundTotal);

    final todaysSales = billProvider.todaysSales;
    final billCount = billProvider.todaysBillCount;
    final recentBills = billProvider.recentBills;
    final todaysExpenses = expenseProvider.todayTotal;
    final recentExpenses = expenseProvider
        .getFilteredExpenses()
        .take(3)
        .toList();
    final todayCashBook = cashBookProvider.getTodayCashBook();
    final yesterdayCashBook = cashBookProvider.getCashBookDay(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final pendingCashBookDays = cashBookProvider.pendingDaysCount();

    return Scaffold(
      appBar: AppTopBar(
        title: businessConfig.businessName.isNotEmpty
            ? businessConfig.businessName
            : AppStrings.homeTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      floatingActionButton: AppFab(
        heroTag: 'fab-dashboard',
        onPressed: () => Navigator.pushNamed(context, '/create-bill'),
      ),
      body: recentBills.isEmpty && todaysSales == 0 && todaysExpenses == 0
          ? EmptyState(
              icon: Icons.receipt_long,
              title: AppStrings.noBillsYet,
              description: AppStrings.noBillsDesc,
              ctaLabel: AppStrings.createBill,
              onCtaTap: () => Navigator.pushNamed(context, '/create-bill'),
            )
          : WebConstraint(
              child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                final billProvider = context.read<BillProvider>();
                try {
                  await billProvider.pendingSave;
                } catch (_) {
                  // Save failed — keep in-memory data, don't sync from DB
                  return;
                }
                await billProvider.syncFromDb();
              },
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: AppStrings.todaysSales,
                          value: Formatters.currency(todaysSales),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: StatCard(
                          label: AppStrings.billsToday,
                          value: '$billCount',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: AppStrings.cashInHand,
                          value: Formatters.currency(
                            todayCashBook.closingBalance,
                          ),
                          valueColor: todayCashBook.closingBalance < 0
                              ? AppColors.error
                              : AppColors.success,
                          onTap: () =>
                              Navigator.pushNamed(context, '/cash-book'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: StatCard(
                          label: AppStrings.yesterdayClose,
                          value: Formatters.currency(
                            yesterdayCashBook.closingBalance,
                          ),
                          onTap: () =>
                              Navigator.pushNamed(context, '/cash-book'),
                        ),
                      ),
                    ],
                  ),
                  if (pendingCashBookDays > 0) ...[
                    const SizedBox(height: AppSpacing.small),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.small),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                      ),
                      child: Text(
                        '${AppStrings.pendingDaysWarning}: $pendingCashBookDays ${AppStrings.pendingDaysCountSuffix}',
                        style: AppTypography.label.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  if (billProvider.todaysTotalDiscount > 0) ...[
                    const SizedBox(height: AppSpacing.small),
                    StatCard(
                      label: AppStrings.discountGivenToday,
                      value: Formatters.currency(
                        billProvider.todaysTotalDiscount,
                      ),
                      valueColor: AppColors.error,
                    ),
                  ],
                  if (todayRefundTotal > 0) ...[
                    const SizedBox(height: AppSpacing.small),
                    StatCard(
                      label: AppStrings.todaysReturns,
                      value: Formatters.currency(todayRefundTotal),
                      valueColor: AppColors.error,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: AppStrings.todaysExpenses,
                          value: Formatters.currency(todaysExpenses),
                          valueColor: todaysExpenses > 0
                              ? AppColors.error
                              : null,
                          onTap: () =>
                              context.read<NavigationProvider>().setTab(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: StatCard(
                          label: AppStrings.expensesCount,
                          value: '${expenseProvider.getTodayExpenses().length}',
                          onTap: () =>
                              context.read<NavigationProvider>().setTab(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: AppStrings.todaysPurchases,
                          value: Formatters.currency(todaysPurchases),
                          valueColor: todaysPurchases > 0
                              ? AppColors.error
                              : null,
                          onTap: () =>
                              Navigator.pushNamed(context, '/purchases'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: StatCard(
                          label: AppStrings.lowStock,
                          value: lowStock > 0 ? '$lowStock items' : '0',
                          valueColor: lowStock > 0 ? AppColors.error : null,
                          onTap: lowStock > 0
                              ? () => Navigator.pushNamed(context, '/reorder')
                              : () => context
                                    .read<NavigationProvider>()
                                    .setTab(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  if (outstanding > 0)
                    StatCard(
                      label: AppStrings.outstandingCredit,
                      value: Formatters.currency(outstanding),
                      valueColor: AppColors.error,
                      onTap: () =>
                          context.read<NavigationProvider>().setTab(4),
                    ),
                  const SizedBox(height: AppSpacing.small),
                  // EOD nudge after 8pm
                  if (DateTime.now().hour >= 20 &&
                      !todayCashBook.isClosed) ...[
                    InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, '/eod-summary'),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          border: Border.all(
                            color: AppColors.primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.nightlight_round,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.eodNudge,
                                style: AppTypography.label.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                  ],
                  // Recurring expenses due this week
                  if (expenseProvider
                      .getUpcomingRecurring(7)
                      .isNotEmpty) ...[
                    InkWell(
                      onTap: () =>
                          Navigator.pushNamed(context, '/expenses'),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          color:
                              AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          border: Border.all(
                            color:
                                AppColors.warning.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.replay,
                                color: AppColors.warning, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${expenseProvider.getUpcomingRecurring(7).length} ${AppStrings.recurringDueThisWeek}',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: AppColors.warning),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                  ],
                  // View Day Summary button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/eod-summary'),
                          icon: const Icon(Icons.summarize, size: 18),
                          label: Text(AppStrings.eodViewDaySummary),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/reports'),
                          icon: const Icon(Icons.bar_chart, size: 18),
                          label: Text(AppStrings.reportsTitle),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.large),
                  // Recent Bills
                  if (recentBills.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.recentBills,
                          style: AppTypography.heading.copyWith(fontSize: 16),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/bill-history'),
                          child: Text(
                            AppStrings.viewAll,
                            style: AppTypography.label.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...recentBills.map(
                      (bill) => BillHistoryCard(
                        bill: bill,
                        onTap: () => BillDetailSheet.show(context, bill),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.expensesTitle,
                        style: AppTypography.heading.copyWith(fontSize: 16),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/expenses'),
                        child: Text(
                          AppStrings.viewAll,
                          style: AppTypography.label.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (recentExpenses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        border: Border.all(
                          color: AppColors.muted.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        AppStrings.trackYourExpenses,
                        style: AppTypography.label,
                      ),
                    )
                  else
                    ...recentExpenses.map(
                      (expense) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        child: ExpenseCard(
                          expense: expense,
                          onTap: () =>
                              Navigator.pushNamed(context, '/expenses'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ),
            ),
    );
  }
}
