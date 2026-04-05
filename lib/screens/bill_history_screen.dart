import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/bill_detail_sheet.dart';
import '../widgets/bill_history_card.dart';
import '../widgets/bill_history_filter_chips.dart';
import '../widgets/empty_state.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

enum _BillSort { dateDesc, dateAsc, amountDesc, amountAsc }

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  BillFilter _filter = BillFilter.all;
  String _searchQuery = '';
  _BillSort _sort = _BillSort.dateDesc;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _exportCsv(List<Bill> bills) async {
    final buf = StringBuffer();
    buf.writeln('Bill No,Date,Customer,Payment Mode,Total');
    for (final b in bills) {
      final row = [
        b.billNumber,
        Formatters.date(b.timestamp),
        b.customer?.name ?? '',
        b.paymentMode.name,
        b.grandTotal.toStringAsFixed(2),
      ].map((v) {
        final s = v.replaceAll('"', '""');
        return '"$s"';
      }).join(',');
      buf.writeln(row);
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/bills_export.csv');
    await file.writeAsString(buf.toString());
    await Share.shareXFiles([XFile(file.path)], subject: 'Bills Export');
    await file.delete();
  }

  List<Bill> _applySortBills(List<Bill> bills) {
    final sorted = bills.toList();
    switch (_sort) {
      case _BillSort.dateDesc:
        sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      case _BillSort.dateAsc:
        sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      case _BillSort.amountDesc:
        sorted.sort((a, b) => b.grandTotal.compareTo(a.grandTotal));
      case _BillSort.amountAsc:
        sorted.sort((a, b) => a.grandTotal.compareTo(b.grandTotal));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final filtered = _applySortBills(
      billProvider.getFilteredBills(_searchQuery, _filter),
    );

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.billHistoryTitle,
        showBack: true,
        actions: [
          PopupMenuButton<_BillSort>(
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _BillSort.dateDesc, child: Text('Newest first')),
              PopupMenuItem(value: _BillSort.dateAsc, child: Text('Oldest first')),
              PopupMenuItem(value: _BillSort.amountDesc, child: Text('Amount: high to low')),
              PopupMenuItem(value: _BillSort.amountAsc, child: Text('Amount: low to high')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.onSurface),
            onSelected: (v) {
              if (v == 'csv') _exportCsv(filtered);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'csv',
                child: Text(AppStrings.exportCsv, style: AppTypography.body),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: AppStrings.searchBills,
                hintStyle: AppTypography.body.copyWith(color: AppColors.muted),
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.muted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(
                    color: AppColors.muted.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(
                    color: AppColors.muted.withValues(alpha: 0.2),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Filter chips
          BillHistoryFilterChips(
            selected: _filter,
            allCount: billProvider.allBillCount,
            todayCount: billProvider.todayBillCount,
            thisWeekCount: billProvider.thisWeekBillCount,
            thisMonthCount: billProvider.thisMonthBillCount,
            cashCount: billProvider.cashBillCount,
            creditCount: billProvider.creditBillCount,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.small),
          // Bill list
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => billProvider.syncFromDb(),
              child: billProvider.bills.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EmptyState(
                          icon: Icons.receipt_long,
                          title: AppStrings.noBillsYet,
                          description: AppStrings.noBillsDesc,
                        ),
                      ],
                    )
                  : filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        EmptyState(
                          icon: Icons.search_off,
                          title: AppStrings.noBillsFound,
                          description: AppStrings.noBillsFoundDesc,
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.medium,
                        vertical: AppSpacing.small,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final bill = filtered[index];
                        return BillHistoryCard(
                          bill: bill,
                          onTap: () => BillDetailSheet.show(context, bill),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
