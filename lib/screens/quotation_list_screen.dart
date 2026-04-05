import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/quotation.dart';
import '../providers/quotation_provider.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/quotation_detail_sheet.dart';
import 'create_bill_screen.dart';

enum QuotationFilter { all, active, sent, approved, expired }

class QuotationListScreen extends StatefulWidget {
  final bool showBack;

  const QuotationListScreen({super.key, this.showBack = false});

  @override
  State<QuotationListScreen> createState() => _QuotationListScreenState();
}

class _QuotationListScreenState extends State<QuotationListScreen> {
  QuotationFilter _filter = QuotationFilter.all;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuotationProvider>();
    final filtered = _getFiltered(provider);

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.quotationsTitle,
        showBack: widget.showBack,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: '${AppStrings.filterAll} (${provider.quotations.length})',
                  selected: _filter == QuotationFilter.all,
                  onTap: () => setState(() => _filter = QuotationFilter.all),
                ),
                const SizedBox(width: AppSpacing.small),
                _FilterChip(
                  label: '${AppStrings.filterActive} (${provider.getActiveQuotations().length})',
                  selected: _filter == QuotationFilter.active,
                  onTap: () => setState(() => _filter = QuotationFilter.active),
                ),
                const SizedBox(width: AppSpacing.small),
                _FilterChip(
                  label: '${AppStrings.filterSent} (${provider.getByStatus(QuotationStatus.sent).length})',
                  selected: _filter == QuotationFilter.sent,
                  onTap: () => setState(() => _filter = QuotationFilter.sent),
                ),
                const SizedBox(width: AppSpacing.small),
                _FilterChip(
                  label: '${AppStrings.filterApproved} (${provider.getByStatus(QuotationStatus.approved).length})',
                  selected: _filter == QuotationFilter.approved,
                  onTap: () => setState(() => _filter = QuotationFilter.approved),
                ),
                const SizedBox(width: AppSpacing.small),
                _FilterChip(
                  label: '${AppStrings.filterExpired} (${provider.getExpiredQuotations().length})',
                  selected: _filter == QuotationFilter.expired,
                  onTap: () => setState(() => _filter = QuotationFilter.expired),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: AppStrings.searchQuotations,
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.muted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
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
          // Quotation list
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => provider.syncFromDb(),
              child: provider.quotations.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        EmptyState(
                          icon: Icons.description_outlined,
                          title: AppStrings.noQuotations,
                          description: AppStrings.noQuotationsDesc,
                        ),
                      ],
                    )
                  : filtered.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            EmptyState(
                              icon: Icons.search_off,
                              title: AppStrings.noQuotations,
                              description: AppStrings.noQuotationsDesc,
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
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final quotation = filtered[index];
                            return _QuotationCard(
                              quotation: quotation,
                              onTap: () =>
                                  QuotationDetailSheet.show(context, quotation),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-quotation',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateBillScreen(isQuotation: true),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Quotation> _getFiltered(QuotationProvider provider) {
    List<Quotation> base;
    switch (_filter) {
      case QuotationFilter.all:
        base = provider.quotations.toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case QuotationFilter.active:
        base = provider.getActiveQuotations();
      case QuotationFilter.sent:
        base = provider.getByStatus(QuotationStatus.sent);
      case QuotationFilter.approved:
        base = provider.getByStatus(QuotationStatus.approved);
      case QuotationFilter.expired:
        base = provider.getExpiredQuotations();
    }
    if (_query.length < 2) return base;
    return provider.searchQuotations(_query)
        .where((q) => base.any((b) => b.id == q.id))
        .toList();
  }
}

class _QuotationCard extends StatelessWidget {
  final Quotation quotation;
  final VoidCallback? onTap;

  const _QuotationCard({required this.quotation, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(quotation.status);
    final statusBg = statusColor.withValues(alpha: 0.10);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small + 4,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quotation.quotationNumber,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    quotation.customerName ??
                        quotation.customer?.name ??
                        '',
                    style: AppTypography.label,
                  ),
                  Text(
                    '${AppStrings.validUntil}: ${Formatters.date(quotation.validUntil)}',
                    style: AppTypography.label.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.currency(quotation.grandTotal),
                  style: AppTypography.currency,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(
                      AppSpacing.buttonRadius,
                    ),
                  ),
                  child: Text(
                    quotation.status.label,
                    style: AppTypography.label.copyWith(
                      fontSize: 12,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(QuotationStatus status) {
    switch (status) {
      case QuotationStatus.draft:
        return AppColors.muted;
      case QuotationStatus.sent:
        return AppColors.primary;
      case QuotationStatus.approved:
        return AppColors.success;
      case QuotationStatus.rejected:
        return AppColors.error;
      case QuotationStatus.expired:
        return AppColors.warning;
      case QuotationStatus.converted:
        return AppColors.primary;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight(0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
