import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../constants/uom_constants.dart';
import '../models/bill.dart';
import '../models/payment_info.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/return_provider.dart';
import 'confirm_dialog.dart';
import 'create_return_sheet.dart';
import 'credit_note_sheet.dart';
import 'invoice_share_actions.dart';

class BillDetailSheet extends StatelessWidget {
  final Bill bill;

  const BillDetailSheet({super.key, required this.bill});

  static void show(BuildContext context, Bill bill) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<ReturnProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<ProductProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<CustomerProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<BillProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<BusinessConfigProvider>(),
          ),
        ],
        child: BillDetailSheet(bill: bill),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = bill.paymentMode == PaymentMode.credit;
    final isMobileShop = context.watch<BusinessConfigProvider>().isMobileShop;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Text(AppStrings.billDetails, style: AppTypography.heading),
              const SizedBox(height: AppSpacing.medium),
              // Bill info
              _InfoRow(label: 'Bill #', value: bill.billNumber),
              _InfoRow(
                label: 'Date',
                value:
                    '${Formatters.date(bill.timestamp)}  ${Formatters.time(bill.timestamp)}',
              ),
              if (bill.customer != null)
                _InfoRow(
                  label: AppStrings.customer,
                  value: bill.customer!.name,
                ),
              if (isMobileShop) ...[
                if (bill.vehicleModel != null && bill.vehicleModel!.isNotEmpty)
                  _InfoRow(label: 'Model', value: bill.vehicleModel!),
                if (bill.vehicleMake != null && bill.vehicleMake!.isNotEmpty)
                  _InfoRow(label: 'Brand', value: bill.vehicleMake!),
                if (bill.vehicleReg != null && bill.vehicleReg!.isNotEmpty)
                  _InfoRow(label: 'IMEI No', value: bill.vehicleReg!),
                if (bill.kmReading != null && bill.kmReading!.isNotEmpty)
                  _InfoRow(label: 'Color / Storage', value: bill.kmReading!),
              ] else ...[
                if (bill.vehicleReg != null && bill.vehicleReg!.isNotEmpty)
                  _InfoRow(
                    label: 'Vehicle',
                    value: [
                      bill.vehicleReg!,
                      if (bill.vehicleModel != null && bill.vehicleModel!.isNotEmpty)
                        bill.vehicleModel!,
                      if (bill.vehicleMake != null && bill.vehicleMake!.isNotEmpty)
                        bill.vehicleMake!,
                    ].join(' · '),
                  ),
                if (bill.kmReading != null && bill.kmReading!.isNotEmpty)
                  _InfoRow(label: 'KM Reading', value: '${bill.kmReading} km'),
              ],
              if (bill.diagnosis != null && bill.diagnosis!.isNotEmpty)
                _InfoRow(
                  label: AppStrings.diagnosisLabel,
                  value: bill.diagnosis!,
                ),
              if (bill.visitNotes != null && bill.visitNotes!.isNotEmpty)
                _InfoRow(
                  label: AppStrings.visitNotesLabel,
                  value: bill.visitNotes!,
                ),
              const Divider(height: AppSpacing.large),
              // Line items header
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Item', style: AppTypography.label),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.qty,
                      style: AppTypography.label,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.price,
                      style: AppTypography.label,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.subtotal,
                      style: AppTypography.label,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              // Line items
              ...bill.lineItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.product.name,
                          style: AppTypography.body.copyWith(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          UomConstants.display(item.product.displayUom, item.quantity),
                          style: AppTypography.body.copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          Formatters.currency(item.product.sellingPrice),
                          style: AppTypography.body.copyWith(fontSize: 13),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          Formatters.currency(item.subtotal),
                          style: AppTypography.body.copyWith(fontSize: 13),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: AppSpacing.large),
              // Totals
              _TotalRow(
                label: AppStrings.subtotal,
                value: Formatters.currency(bill.subtotal),
              ),
              if (bill.discount > 0)
                _TotalRow(
                  label: AppStrings.discount,
                  value: '- ${Formatters.currency(bill.discount)}',
                ),
              if (!bill.isInterState && bill.cgst > 0)
                _TotalRow(
                  label: AppStrings.cgst,
                  value: Formatters.currency(bill.cgst),
                ),
              if (!bill.isInterState && bill.sgst > 0)
                _TotalRow(
                  label: AppStrings.sgst,
                  value: Formatters.currency(bill.sgst),
                ),
              if (bill.isInterState && bill.igst > 0)
                _TotalRow(
                  label: AppStrings.igst,
                  value: Formatters.currency(bill.igst),
                ),
              const SizedBox(height: AppSpacing.small),
              _TotalRow(
                label: AppStrings.grandTotal,
                value: Formatters.currency(bill.grandTotal),
                bold: true,
              ),
              const Divider(height: AppSpacing.large),
              // Payment info
              _InfoRow(
                label: AppStrings.payment,
                value: bill.paymentMode.label,
              ),
              if (bill.paymentMode == PaymentMode.split) ...[
                _InfoRow(
                  label: 'Cash',
                  value: Formatters.currency(bill.splitCashAmount ?? 0),
                ),
                _InfoRow(
                  label: 'UPI',
                  value: Formatters.currency(bill.splitUpiAmount ?? 0),
                ),
              ] else if (!isCredit && bill.amountReceived > 0)
                _InfoRow(
                  label: AppStrings.amountReceived,
                  value: Formatters.currency(bill.amountReceived),
                ),
              if (bill.paymentMode == PaymentMode.cash &&
                  bill.amountReceived > bill.grandTotal)
                _InfoRow(
                  label: AppStrings.change,
                  value: Formatters.currency(
                    bill.amountReceived - bill.grandTotal,
                  ),
                ),
              if (isCredit && bill.creditAmount > 0)
                _InfoRow(
                  label: AppStrings.creditAmount,
                  value: Formatters.currency(bill.creditAmount),
                ),
              if (bill.advanceUsed > 0)
                _InfoRow(
                  label: 'Advance Used',
                  value: Formatters.currency(bill.advanceUsed),
                ),
              const SizedBox(height: AppSpacing.large),
              // Return section
              Builder(
                builder: (ctx) {
                  final returnProvider = ctx.watch<ReturnProvider>();
                  final billReturns = returnProvider.getReturnsByBill(bill.id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (billReturns.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.small),
                          margin: const EdgeInsets.only(
                            bottom: AppSpacing.small,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.cardRadius,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.assignment_return,
                                    size: 16,
                                    color: AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    AppStrings.returnMade,
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ...billReturns.map(
                                (r) => InkWell(
                                  onTap: () => CreditNoteSheet.show(ctx, r),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${r.returnNumber} - ${Formatters.date(r.date)}',
                                          style: AppTypography.label.copyWith(
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          Formatters.currency(
                                            r.totalRefundAmount,
                                          ),
                                          style: AppTypography.body.copyWith(
                                            fontSize: 12,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final result =
                                await CreateReturnSheet.show(ctx, bill);
                            if (result != null && ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                          },
                          icon: const Icon(Icons.assignment_return, size: 18),
                          label: const Text(AppStrings.returnItems),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.small),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Delete Bill',
                      message:
                          'Are you sure you want to delete bill ${bill.billNumber}? This cannot be undone.',
                      confirmLabel: 'Delete',
                    );
                    if (confirmed == true && context.mounted) {
                      context.read<BillProvider>().deleteBill(
                        bill.billNumber,
                        productProvider: context.read<ProductProvider>(),
                      );
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Delete Bill'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<BillProvider>().loadBillForEdit(bill);
                    Navigator.pop(context); // close detail sheet
                    Navigator.pushNamed(context, '/create-bill');
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Bill'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                ),
              ),
              InvoiceShareActions(bill: bill, compact: true),
            ],
          ),
        );
      },
    );
  }

}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.label),
          Text(value, style: AppTypography.body.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: bold
                ? AppTypography.body.copyWith(fontWeight: FontWeight.w700)
                : AppTypography.label,
          ),
          Text(
            value,
            style: bold
                ? AppTypography.currency
                : AppTypography.body.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
