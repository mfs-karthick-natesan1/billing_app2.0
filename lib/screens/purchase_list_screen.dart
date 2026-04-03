import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/payment_info.dart';
import '../models/purchase_entry.dart';
import '../models/purchase_line_item.dart';
import '../providers/product_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/supplier_provider.dart';
import '../widgets/add_purchase_sheet.dart';
import '../widgets/app_fab.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';

class PurchaseListScreen extends StatefulWidget {
  final bool showBack;

  const PurchaseListScreen({super.key, this.showBack = false});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

enum _PurchaseFilter { all, today, thisWeek, thisMonth }

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  _PurchaseFilter _filter = _PurchaseFilter.all;

  List<PurchaseEntry> _getFiltered(PurchaseProvider provider) {
    final now = DateTime.now();
    switch (_filter) {
      case _PurchaseFilter.all:
        return provider.purchases.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case _PurchaseFilter.today:
        return provider.getTodayPurchases();
      case _PurchaseFilter.thisWeek:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return provider.getPurchasesByDateRange(weekStart, now);
      case _PurchaseFilter.thisMonth:
        return provider.getThisMonthPurchases();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseProvider>();
    final filtered = _getFiltered(provider);
    final todayTotal = provider.todayPurchaseTotal;
    final monthTotal = provider.getThisMonthPurchases().fold(
          0.0,
          (sum, p) => sum + p.totalAmount,
        );

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.purchasesTitle,
        showBack: widget.showBack,
      ),
      body: provider.purchases.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: AppStrings.noPurchasesYet,
              description: AppStrings.noPurchasesDesc,
            )
          : Column(
              children: [
                // Summary cards
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Row(
                    children: [
                      Expanded(
                        child: _summaryCard(
                          AppStrings.todaysPurchases,
                          Formatters.currency(todayTotal),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: _summaryCard(
                          AppStrings.thisMonthPurchases,
                          Formatters.currency(monthTotal),
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  child: Row(
                    children: [
                      _chip(AppStrings.all, _PurchaseFilter.all),
                      const SizedBox(width: 6),
                      _chip(AppStrings.today, _PurchaseFilter.today),
                      const SizedBox(width: 6),
                      _chip(AppStrings.thisWeek, _PurchaseFilter.thisWeek),
                      const SizedBox(width: 6),
                      _chip(AppStrings.thisMonth, _PurchaseFilter.thisMonth),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                // List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            AppStrings.noPurchasesFound,
                            style: AppTypography.label,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            return Dismissible(
                              key: ValueKey(entry.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(
                                    bottom: AppSpacing.small),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.cardRadius),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (_) => ConfirmDialog.show(
                                context,
                                title: 'Delete Purchase?',
                                message:
                                    'This purchase entry will be permanently deleted.',
                                confirmLabel: 'Delete',
                                isDestructive: true,
                              ),
                              onDismissed: (_) =>
                                  context.read<PurchaseProvider>().deletePurchase(
                                        entry.id,
                                        productProvider:
                                            context.read<ProductProvider>(),
                                        supplierProvider:
                                            context.read<SupplierProvider>(),
                                      ),
                              child: _purchaseCard(
                                entry,
                                onTap: () =>
                                    _showPurchaseDetail(context, entry),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: AppFab(
        onPressed: () => AddPurchaseSheet.show(context),
      ),
    );
  }

  Widget _summaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.label.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.currency.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _PurchaseFilter filter) {
    final selected = _filter == filter;
    return InkWell(
      onTap: () => setState(() => _filter = filter),
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight(0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            fontSize: 12,
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }

  void _showPurchaseDetail(BuildContext context, PurchaseEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.supplierName ?? AppStrings.adHocPurchase,
                          style: AppTypography.heading,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd MMM yyyy, hh:mm a').format(entry.date),
                          style: AppTypography.label
                              .copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: AppColors.primary,
                    tooltip: 'Edit',
                    onPressed: () {
                      Navigator.pop(context);
                      AddPurchaseSheet.show(context, entry);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppColors.error,
                    tooltip: 'Delete',
                    onPressed: () async {
                      Navigator.pop(context);
                      final confirm = await ConfirmDialog.show(
                        context,
                        title: 'Delete Purchase?',
                        message: 'This purchase entry will be permanently deleted.',
                        confirmLabel: 'Delete',
                        isDestructive: true,
                      );
                      if (confirm && context.mounted) {
                        context.read<PurchaseProvider>().deletePurchase(
                          entry.id,
                          productProvider: context.read<ProductProvider>(),
                          supplierProvider: context.read<SupplierProvider>(),
                        );
                      }
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: entry.paymentMode.isCredit
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.paymentMode.label,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.bold,
                        color: entry.paymentMode.isCredit
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (entry.invoiceNumber != null &&
                entry.invoiceNumber!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${AppStrings.invoiceNumberLabel}: ',
                      style: AppTypography.label
                          .copyWith(color: AppColors.muted),
                    ),
                    Text(
                      entry.invoiceNumber!,
                      style: AppTypography.label
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            if (entry.notes != null && entry.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes: ',
                      style: AppTypography.label
                          .copyWith(color: AppColors.muted),
                    ),
                    Expanded(
                      child: Text(
                        entry.notes!,
                        style: AppTypography.label,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),
            // Items table header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Item',
                        style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  Text('Qty',
                      style: AppTypography.label.copyWith(
                          fontWeight: FontWeight.bold, fontSize: 11)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: Text('Rate',
                        textAlign: TextAlign.right,
                        style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 70,
                    child: Text('Amount',
                        textAlign: TextAlign.right,
                        style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Items list
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ...entry.items.map((item) => _detailItemRow(item)),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Total  ',
                          style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold)),
                      Text(
                        Formatters.currency(entry.totalAmount),
                        style: AppTypography.currency,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailItemRow(PurchaseLineItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(item.productName, style: AppTypography.body),
              ),
              Text(
                item.quantity
                    .toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2),
                style: AppTypography.body,
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 70,
                child: Text(
                  Formatters.currency(item.purchasePricePerUnit),
                  textAlign: TextAlign.right,
                  style: AppTypography.body,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 70,
                child: Text(
                  Formatters.currency(item.totalCost),
                  textAlign: TextAlign.right,
                  style: AppTypography.body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (item.gstRate > 0) ...[
            const SizedBox(height: 2),
            Text(
              'GST ${item.gstRate.toStringAsFixed(0)}%${item.isTaxInclusive ? ' (incl.)' : ''}  Tax: ${Formatters.currency(item.taxAmount)}',
              style: AppTypography.label
                  .copyWith(fontSize: 11, color: AppColors.muted),
            ),
          ],
          if (item.batchNumber != null && item.batchNumber!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Batch: ${item.batchNumber}${item.expiryDate != null ? '  Exp: ${DateFormat('MMM yyyy').format(item.expiryDate!)}' : ''}',
              style: AppTypography.label
                  .copyWith(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _purchaseCard(PurchaseEntry entry, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.small),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.supplierName ?? AppStrings.adHocPurchase,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(entry.date)}  ${entry.items.length} ${AppStrings.items}',
                      style: AppTypography.label.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(entry.totalAmount),
                    style: AppTypography.currency.copyWith(fontSize: 14),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: entry.paymentMode.isCredit
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      entry.paymentMode.label,
                      style: AppTypography.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: entry.paymentMode.isCredit
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (entry.invoiceNumber != null &&
              entry.invoiceNumber!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${AppStrings.invoiceNumberLabel}: ${entry.invoiceNumber}',
              style: AppTypography.label.copyWith(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
