import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/supplier.dart';
import '../providers/supplier_provider.dart';
import 'add_edit_supplier_sheet.dart';
import 'app_snackbar.dart';
import 'app_text_input.dart';
import 'confirm_dialog.dart';

class SupplierDetailSheet extends StatelessWidget {
  final Supplier supplier;

  const SupplierDetailSheet({super.key, required this.supplier});

  static Future<void> show(BuildContext context, Supplier supplier) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SupplierProvider>(),
        child: SupplierDetailSheet(supplier: supplier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();
    final current = provider.getSupplierById(supplier.id) ?? supplier;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
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
                                current.name,
                                style: AppTypography.heading,
                              ),
                              if (current.phone != null)
                                Text(
                                  current.phone!,
                                  style: AppTypography.label,
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: AppColors.primary,
                          tooltip: AppStrings.editSupplier,
                          onPressed: () {
                            Navigator.pop(context);
                            AddEditSupplierSheet.show(context, current);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.person_off_outlined,
                            size: 20,
                          ),
                          color: AppColors.error,
                          tooltip: AppStrings.deactivateSupplier,
                          onPressed: () =>
                              _confirmDeactivate(context, current),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),

                    // Info rows
                    if (current.gstin != null && current.gstin!.isNotEmpty)
                      _infoRow(
                        Icons.receipt_long,
                        '${AppStrings.supplierGstinLabel}: ${current.gstin}',
                      ),
                    if (current.address != null &&
                        current.address!.isNotEmpty)
                      _infoRow(Icons.location_on_outlined, current.address!),
                    if (current.notes != null && current.notes!.isNotEmpty)
                      _infoRow(Icons.note_outlined, current.notes!),

                    if (current.productCategories.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.small),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: current.productCategories.map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              cat,
                              style: AppTypography.label.copyWith(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.medium),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.medium),

                    // Outstanding payable
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.outstandingPayable,
                          style: AppTypography.body,
                        ),
                        Text(
                          Formatters.currency(current.outstandingPayable),
                          style: AppTypography.currency.copyWith(
                            color: current.outstandingPayable > 0
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),

                    if (current.outstandingPayable > 0) ...[
                      const SizedBox(height: AppSpacing.medium),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _recordPayment(context, current),
                          icon: const Icon(Icons.payment, size: 18),
                          label: Text(
                            AppStrings.recordSupplierPayment,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.medium),
                    // Purchase history placeholder (will be populated in 2.4)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        border: Border.all(
                          color: AppColors.muted.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.muted.withValues(alpha: 0.4),
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppStrings.purchaseHistoryComingSoon,
                            style: AppTypography.label.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: AppTypography.label.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(
    BuildContext context,
    Supplier supplier,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deactivateSupplier,
      message: AppStrings.deactivateSupplierConfirm,
      confirmLabel: AppStrings.deactivateSupplier,
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<SupplierProvider>().deleteSupplier(supplier.id);
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.supplierDeactivated);
    }
  }

  Future<void> _recordPayment(
    BuildContext context,
    Supplier supplier,
  ) async {
    final amountController = TextEditingController();
    String? error;

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.medium,
            right: AppSpacing.medium,
            top: AppSpacing.medium,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.medium,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                AppStrings.recordSupplierPayment,
                style: AppTypography.heading,
              ),
              const SizedBox(height: 4),
              Text(
                '${AppStrings.outstandingPayable}: ${Formatters.currency(supplier.outstandingPayable)}',
                style: AppTypography.label.copyWith(color: AppColors.error),
              ),
              const SizedBox(height: AppSpacing.medium),
              AppTextInput(
                label: AppStrings.amountLabel,
                required: true,
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                prefix: 'Rs. ',
                errorText: error,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,2}'),
                  ),
                ],
                onChanged: (_) => setSheetState(() => error = null),
              ),
              const SizedBox(height: AppSpacing.large),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final amount =
                        double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      setSheetState(
                        () => error = AppStrings.amountGreaterThanZero,
                      );
                      return;
                    }
                    if (amount > supplier.outstandingPayable) {
                      setSheetState(
                        () => error = AppStrings.amountCannotExceedOutstanding,
                      );
                      return;
                    }
                    Navigator.pop(ctx, amount);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.buttonRadius,
                      ),
                    ),
                  ),
                  child: Text(
                    AppStrings.recordPayment,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && context.mounted) {
      context.read<SupplierProvider>().recordPayment(supplier.id, result);
      AppSnackbar.success(context, AppStrings.supplierPaymentRecorded);
    }
  }
}
