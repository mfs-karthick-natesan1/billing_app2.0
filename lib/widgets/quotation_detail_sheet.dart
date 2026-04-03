import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../constants/uom_constants.dart';
import '../models/quotation.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/quotation_provider.dart';
import '../services/invoice_service.dart';
import '../services/pdf_invoice_service.dart';
import 'app_snackbar.dart';
import 'confirm_dialog.dart';

class QuotationDetailSheet extends StatelessWidget {
  final Quotation quotation;

  const QuotationDetailSheet({super.key, required this.quotation});

  static void show(BuildContext context, Quotation quotation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<QuotationProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<BillProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<BusinessConfigProvider>(),
          ),
        ],
        child: QuotationDetailSheet(quotation: quotation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quotationProvider = context.watch<QuotationProvider>();
    // Re-fetch to get latest status
    final current = quotationProvider.quotations
            .cast<Quotation?>()
            .firstWhere((q) => q!.id == quotation.id, orElse: () => null) ??
        quotation;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.quotationDetails,
                      style: AppTypography.heading,
                    ),
                  ),
                  _StatusBadge(status: current.status),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              // Info rows
              _InfoRow(
                label: AppStrings.quotationNumber,
                value: current.quotationNumber,
              ),
              _InfoRow(
                label: AppStrings.dateLabel,
                value: Formatters.date(current.date),
              ),
              _InfoRow(
                label: AppStrings.validUntil,
                value: Formatters.date(current.validUntil),
              ),
              if (current.customerName != null ||
                  current.customer?.name != null)
                _InfoRow(
                  label: AppStrings.customer,
                  value: current.customerName ??
                      current.customer?.name ??
                      '',
                ),
              if ((current.customerPhone ?? current.customer?.phone) != null &&
                  (current.customerPhone ?? current.customer?.phone)!.isNotEmpty)
                _InfoRow(
                  label: 'Phone',
                  value: current.customerPhone ?? current.customer!.phone!,
                ),
              if (current.vehicleReg != null)
                _InfoRow(label: 'Vehicle Reg', value: current.vehicleReg!),
              if (current.vehicleMake != null || current.vehicleModel != null)
                _InfoRow(
                  label: 'Vehicle',
                  value: '${current.vehicleMake ?? ''} ${current.vehicleModel ?? ''}'.trim(),
                ),
              if (current.kmReading != null)
                _InfoRow(label: 'KM Reading', value: current.kmReading!),
              if (current.notes != null && current.notes!.isNotEmpty)
                _InfoRow(
                  label: AppStrings.quotationNotes,
                  value: current.notes!,
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
              ...current.items.map(
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
                          UomConstants.display(
                            item.product.displayUom,
                            item.quantity,
                          ),
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
                value: Formatters.currency(current.subtotal),
              ),
              if (current.discount > 0)
                _TotalRow(
                  label: AppStrings.discount,
                  value: '- ${Formatters.currency(current.discount)}',
                ),
              if (!current.isInterState && current.cgst > 0)
                _TotalRow(
                  label: AppStrings.cgst,
                  value: Formatters.currency(current.cgst),
                ),
              if (!current.isInterState && current.sgst > 0)
                _TotalRow(
                  label: AppStrings.sgst,
                  value: Formatters.currency(current.sgst),
                ),
              if (current.isInterState && current.igst > 0)
                _TotalRow(
                  label: AppStrings.igst,
                  value: Formatters.currency(current.igst),
                ),
              const SizedBox(height: AppSpacing.small),
              _TotalRow(
                label: AppStrings.grandTotal,
                value: Formatters.currency(current.grandTotal),
                bold: true,
              ),
              const Divider(height: AppSpacing.large),
              // Status actions
              if (current.status == QuotationStatus.draft ||
                  current.status == QuotationStatus.sent ||
                  current.status == QuotationStatus.approved) ...[
                Text(
                  'Actions',
                  style: AppTypography.heading.copyWith(fontSize: 15),
                ),
                const SizedBox(height: AppSpacing.small),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    if (current.status == QuotationStatus.draft)
                      _ActionChip(
                        icon: Icons.send,
                        label: AppStrings.markAsSent,
                        onTap: () {
                          quotationProvider.updateStatus(
                            current.id,
                            QuotationStatus.sent,
                          );
                          AppSnackbar.success(
                            context,
                            AppStrings.quotationStatusUpdated,
                          );
                        },
                      ),
                    if (current.status == QuotationStatus.draft ||
                        current.status == QuotationStatus.sent)
                      _ActionChip(
                        icon: Icons.check_circle_outline,
                        label: AppStrings.markAsApproved,
                        onTap: () {
                          quotationProvider.updateStatus(
                            current.id,
                            QuotationStatus.approved,
                          );
                          AppSnackbar.success(
                            context,
                            AppStrings.quotationStatusUpdated,
                          );
                        },
                      ),
                    if (current.status != QuotationStatus.converted)
                      _ActionChip(
                        icon: Icons.cancel_outlined,
                        label: AppStrings.markAsRejected,
                        color: AppColors.error,
                        onTap: () {
                          quotationProvider.updateStatus(
                            current.id,
                            QuotationStatus.rejected,
                          );
                          AppSnackbar.success(
                            context,
                            AppStrings.quotationStatusUpdated,
                          );
                        },
                      ),
                    if (current.canConvert)
                      _ActionChip(
                        icon: Icons.receipt_long,
                        label: AppStrings.convertToBill,
                        color: AppColors.success,
                        onTap: () => _handleConvertToBill(context, current),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              // Share actions
              _QuotationShareActions(quotation: current),
              const SizedBox(height: AppSpacing.medium),
              // Delete
              if (current.status != QuotationStatus.converted)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleDelete(context, current),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(AppStrings.deleteQuotation),
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
            ],
          ),
        );
      },
    );
  }

  void _handleConvertToBill(BuildContext context, Quotation current) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.convertToBillConfirm,
      confirmLabel: AppStrings.convertToBill,
    );
    if (!confirmed || !context.mounted) return;

    final quotationProvider = context.read<QuotationProvider>();
    final billProvider = context.read<BillProvider>();
    final config = context.read<BusinessConfigProvider>();

    final bill = quotationProvider.convertToBill(current.id);
    if (bill == null) return;

    // Set up the bill in BillProvider active state so user goes through payment
    billProvider.clearActiveBill();
    for (final item in current.items) {
      billProvider.addItemToBill(
        item.product,
        businessType: config.businessType,
      );
      // Restore original quantity
      final idx = billProvider.activeLineItems.length - 1;
      if (idx >= 0) {
        billProvider.updateQuantity(idx, item.quantity);
      }
    }
    if (current.customer != null) {
      billProvider.setActiveCustomer(current.customer);
    }

    if (context.mounted) {
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.quotationConverted);
      Navigator.pushNamed(context, '/create-bill');
    }
  }

  void _handleDelete(BuildContext context, Quotation current) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deleteQuotationConfirm,
      confirmLabel: AppStrings.deleteQuotation,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    context.read<QuotationProvider>().deleteQuotation(current.id);
    Navigator.pop(context);
    AppSnackbar.success(context, AppStrings.quotationDeleted);
  }
}

class _StatusBadge extends StatelessWidget {
  final QuotationStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Text(
        status.label,
        style: AppTypography.label.copyWith(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
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

class _QuotationShareActions extends StatelessWidget {
  final Quotation quotation;

  const _QuotationShareActions({required this.quotation});

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<BusinessConfigProvider?>(
      context,
      listen: true,
    );
    final config = configProvider?.config;
    if (config == null) return const SizedBox.shrink();

    final text = InvoiceService.buildQuotationText(
      quotation: quotation,
      config: config,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.invoiceActions,
          style: AppTypography.heading.copyWith(fontSize: 15),
        ),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            _ActionChip(
              icon: Icons.copy_all_outlined,
              label: AppStrings.copyInvoice,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  AppSnackbar.success(context, AppStrings.invoiceCopied);
                }
              },
            ),
            _ActionChip(
              icon: Icons.print_outlined,
              label: 'Print',
              onTap: () async {
                try {
                  final bytes = await PdfInvoiceService.generateQuotationPdf(
                    quotation: quotation,
                    config: config,
                  );
                  await Printing.layoutPdf(onLayout: (_) async => bytes);
                } catch (_) {
                  if (context.mounted) {
                    AppSnackbar.error(context, 'Could not generate PDF');
                  }
                }
              },
            ),
            _ActionChip(
              icon: Icons.picture_as_pdf_outlined,
              label: 'PDF',
              onTap: () async {
                try {
                  final bytes = await PdfInvoiceService.generateQuotationPdf(
                    quotation: quotation,
                    config: config,
                  );
                  if (kIsWeb) {
                    await Printing.layoutPdf(onLayout: (_) async => bytes);
                  } else {
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: 'quotation_${quotation.quotationNumber}.pdf',
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    AppSnackbar.error(context, 'Could not generate PDF');
                  }
                }
              },
            ),
          ],
        ),
      ],
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
          Flexible(
            child: Text(
              value,
              style: AppTypography.body.copyWith(fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
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

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: chipColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: chipColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.label.copyWith(color: chipColor),
            ),
          ],
        ),
      ),
    );
  }
}
