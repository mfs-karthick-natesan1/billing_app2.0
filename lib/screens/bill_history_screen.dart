import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
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

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  BillFilter _filter = BillFilter.all;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final filtered = billProvider.getFilteredBills(_searchQuery, _filter);

    return Scaffold(
      appBar: AppTopBar(title: AppStrings.billHistoryTitle, showBack: true),
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
            child: billProvider.bills.isEmpty
                ? EmptyState(
                    icon: Icons.receipt_long,
                    title: AppStrings.noBillsYet,
                    description: AppStrings.noBillsDesc,
                  )
                : filtered.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: AppStrings.noBillsFound,
                    description: AppStrings.noBillsFoundDesc,
                  )
                : ListView.separated(
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
        ],
      ),
    );
  }
}
