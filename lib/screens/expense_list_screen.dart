import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/app_fab.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_filter_chips.dart';

class ExpenseListScreen extends StatefulWidget {
  final bool showBack;

  const ExpenseListScreen({super.key, this.showBack = false});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  ExpenseDateFilter _dateFilter = ExpenseDateFilter.all;
  ExpenseCategory? _categoryFilter;
  ExpensePaymentMode? _paymentModeFilter;
  DateTime? _customFrom;
  DateTime? _customTo;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final filtered = provider.getFilteredExpenses(
      query: _searchController.text,
      dateFilter: _dateFilter,
      category: _categoryFilter,
      paymentMode: _paymentModeFilter,
      customFrom: _customFrom,
      customTo: _customTo,
    );

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.expensesTitle,
        showBack: widget.showBack,
      ),
      floatingActionButton: AppFab(
        heroTag: 'fab-expense',
        onPressed: () => AddExpenseSheet.show(context),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => provider.syncFromDb(),
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(provider: provider),
                  const SizedBox(height: AppSpacing.medium),
                  _buildSearch(),
                  const SizedBox(height: AppSpacing.small),
                  ExpenseDateFilterChips(
                    selected: _dateFilter,
                    onChanged: (filter) async {
                      if (filter == ExpenseDateFilter.customRange) {
                        await _pickCustomRange();
                      }
                      setState(() => _dateFilter = filter);
                    },
                  ),
                  if (_dateFilter == ExpenseDateFilter.customRange &&
                      _customFrom != null &&
                      _customTo != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${AppStrings.fromLabel}: ${Formatters.date(_customFrom!)}   ${AppStrings.toLabel}: ${Formatters.date(_customTo!)}',
                      style: AppTypography.label,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.small),
                  Text(AppStrings.byCategory, style: AppTypography.label),
                  const SizedBox(height: 6),
                  ExpenseCategoryChips(
                    selected: _categoryFilter,
                    onChanged: (value) =>
                        setState(() => _categoryFilter = value),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(AppStrings.byPaymentMode, style: AppTypography.label),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ExpensePaymentModeChips(
                      selected: _paymentModeFilter,
                      onChanged: (value) =>
                          setState(() => _paymentModeFilter = value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  if (_hasActiveFilters)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _clearFilters,
                        child: const Text(AppStrings.clearFilters),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.small),
                  _buildExpenseList(filtered),
                ],
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters {
    return _dateFilter != ExpenseDateFilter.all ||
        _categoryFilter != null ||
        _paymentModeFilter != null ||
        _searchController.text.trim().isNotEmpty;
  }

  Widget _buildSearch() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: AppStrings.searchExpenses,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
      ),
    );
  }

  Widget _buildExpenseList(List<Expense> filtered) {
    if (filtered.isEmpty) {
      if (_hasActiveFilters) {
        return const EmptyState(
          icon: Icons.search_off,
          title: AppStrings.noExpensesFound,
          description: AppStrings.noExpensesFoundDesc,
        );
      }
      return EmptyState(
        icon: Icons.receipt_long,
        title: AppStrings.noExpensesYet,
        description: AppStrings.noExpensesDesc,
        ctaLabel: AppStrings.addExpense,
        onCtaTap: () => AddExpenseSheet.show(context),
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.small),
      itemBuilder: (context, index) {
        final expense = filtered[index];
        return Dismissible(
          key: ValueKey(expense.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.errorLight(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
          confirmDismiss: (_) => _confirmDelete(expense),
          onDismissed: (_) {
            final deleted = expense;
            context.read<ExpenseProvider>().deleteExpense(deleted.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.expenseDeleted),
                action: SnackBarAction(
                  label: AppStrings.undo,
                  onPressed: () {
                    context.read<ExpenseProvider>().addExpense(deleted);
                  },
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          },
          child: ExpenseCard(
            expense: expense,
            onTap: () =>
                AddExpenseSheet.show(context, existingExpense: expense),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(Expense expense) {
    return ConfirmDialog.show(
      context,
      title: AppStrings.deleteExpense,
      message: AppStrings.deleteExpenseConfirm,
      confirmLabel: AppStrings.deleteExpense,
      isDestructive: true,
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: _customFrom != null && _customTo != null
          ? DateTimeRange(start: _customFrom!, end: _customTo!)
          : null,
      helpText: AppStrings.pickDateRange,
    );
    if (picked == null) return;
    _customFrom = picked.start;
    _customTo = picked.end;
  }

  void _clearFilters() {
    setState(() {
      _dateFilter = ExpenseDateFilter.all;
      _categoryFilter = null;
      _paymentModeFilter = null;
      _customFrom = null;
      _customTo = null;
      _searchController.clear();
    });
  }
}

class _SummaryCard extends StatelessWidget {
  final ExpenseProvider provider;

  const _SummaryCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final categoryBreakdown = provider.getCategoryBreakdown(monthStart, now);
    final topCategories = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxValue = topCategories.isEmpty ? 0.0 : topCategories.first.value;
    final displayBars = topCategories.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryValue(
                  label: AppStrings.todaysExpenses,
                  value: Formatters.currency(provider.todayTotal),
                ),
              ),
              Expanded(
                child: _SummaryValue(
                  label: AppStrings.monthlyTotal,
                  value: Formatters.currency(provider.thisMonthTotal),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          if (displayBars.isNotEmpty)
            SizedBox(
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: displayBars.map((entry) {
                  final ratio = maxValue <= 0 ? 0.0 : entry.value / maxValue;
                  final height = (ratio * 36).clamp(6, 36).toDouble();
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight(0.35),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            entry.key.label.split(' ').first,
                            style: AppTypography.label.copyWith(fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Text(AppStrings.trackYourExpenses, style: AppTypography.label),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTypography.currency),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.label),
      ],
    );
  }
}
