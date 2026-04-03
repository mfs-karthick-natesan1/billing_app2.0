import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../providers/supplier_provider.dart';
import '../widgets/add_edit_supplier_sheet.dart';
import '../widgets/app_fab.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/supplier_detail_sheet.dart';

class SupplierListScreen extends StatefulWidget {
  final bool showBack;

  const SupplierListScreen({super.key, this.showBack = false});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final activeSuppliers = supplierProvider.getActiveSuppliers();
    final suppliers = _query.isEmpty
        ? activeSuppliers
        : supplierProvider.searchSuppliers(_query);

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.suppliersTitle,
        showBack: widget.showBack,
      ),
      body: activeSuppliers.isEmpty
          ? const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: AppStrings.noSuppliersYet,
              description: AppStrings.noSuppliersDesc,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchSuppliers,
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.muted,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.muted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.muted.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.muted.withValues(alpha: 0.2),
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: suppliers.length,
                    itemBuilder: (context, index) {
                      final supplier = suppliers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            supplier.name.isNotEmpty
                                ? supplier.name[0].toUpperCase()
                                : '?',
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          supplier.name,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (supplier.phone != null) ...[
                              Text(
                                supplier.phone!,
                                style: AppTypography.label,
                              ),
                              const SizedBox(width: AppSpacing.small),
                            ],
                            if (supplier.productCategories.isNotEmpty)
                              Expanded(
                                child: Text(
                                  supplier.productCategories.join(', '),
                                  style: AppTypography.label.copyWith(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        trailing: supplier.outstandingPayable > 0
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.currency(
                                      supplier.outstandingPayable,
                                    ),
                                    style: AppTypography.currency.copyWith(
                                      color: AppColors.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    AppStrings.payable,
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                AppStrings.noDues,
                                style: AppTypography.label.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                        onTap: () =>
                            SupplierDetailSheet.show(context, supplier),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: AppFab(
        icon: Icons.add,
        onPressed: () => AddEditSupplierSheet.show(context),
      ),
    );
  }
}
