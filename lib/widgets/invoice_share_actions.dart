import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/bill.dart';
import '../models/business_config.dart';
import '../providers/business_config_provider.dart';
import '../providers/serial_number_provider.dart';
import '../services/image_invoice_service.dart';
import '../services/invoice_service.dart';
import '../services/invoice_share_service.dart';
import '../services/pdf_invoice_service.dart';
import 'app_snackbar.dart';

class InvoiceShareActions extends StatelessWidget {
  final Bill bill;
  final bool compact;

  const InvoiceShareActions({
    super.key,
    required this.bill,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final configProvider = Provider.of<BusinessConfigProvider?>(
      context,
      listen: true,
    );
    final config = configProvider?.config ?? const BusinessConfig();
    final snProvider = Provider.of<SerialNumberProvider?>(context, listen: false);
    final serialNumberLookup = <String, String>{
      for (final sn in snProvider?.all ?? []) sn.id: sn.number,
    };
    final text = InvoiceService.buildWhatsappInvoiceText(
      bill: bill,
      config: config,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.invoiceActions,
          style: AppTypography.heading.copyWith(fontSize: compact ? 15 : 16),
        ),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            _ActionChip(
              icon: Icons.chat_outlined,
              label: AppStrings.shareWhatsApp,
              onTap: () => _shareWhatsapp(
                context,
                text,
                config.defaultWhatsappFormat,
                config,
                serialNumberLookup,
              ),
            ),
            _ActionChip(
              icon: Icons.ios_share_outlined,
              label: AppStrings.shareSystem,
              onTap: () => InvoiceShareService.shareText(
                text: text,
                subject: bill.billNumber,
              ),
            ),
            _ActionChip(
              icon: Icons.copy_all_outlined,
              label: AppStrings.copyInvoice,
              onTap: () => _copyInvoiceText(context, text),
            ),
            _ActionChip(
              icon: Icons.print_outlined,
              label: AppStrings.print,
              onTap: () => _printInvoice(context, config, serialNumberLookup),
            ),
            _ActionChip(
              icon: Icons.picture_as_pdf_outlined,
              label: AppStrings.pdf,
              onTap: () => _sharePdf(context, config, serialNumberLookup),
            ),
            _ActionChip(
              icon: Icons.image_outlined,
              label: AppStrings.image,
              onTap: () => _shareImage(context, config, serialNumberLookup),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _shareWhatsapp(
    BuildContext context,
    String text,
    InvoiceShareFormat format,
    BusinessConfig config,
    Map<String, String> serialNumberLookup,
  ) async {
    if (format != InvoiceShareFormat.text) {
      if (format == InvoiceShareFormat.pdf) {
        await _sharePdf(context, config, serialNumberLookup);
      } else {
        await _shareImage(context, config, serialNumberLookup);
      }
      return;
    }

    final shared = await InvoiceShareService.shareOnWhatsApp(
      text: text,
      customerPhone: bill.customer?.phone,
    );
    if (!shared && context.mounted) {
      AppSnackbar.error(context, AppStrings.whatsappNotAvailable);
    }
  }

  Future<void> _copyInvoiceText(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      AppSnackbar.success(context, AppStrings.invoiceCopied);
    }
  }

  Future<void> _printInvoice(
    BuildContext context,
    BusinessConfig config,
    Map<String, String> serialNumberLookup,
  ) async {
    Uint8List? bytes;
    try {
      bytes = await PdfInvoiceService.generateInvoicePdf(
        bill: bill,
        config: config,
        serialNumberLookup: serialNumberLookup,
      );
      await Printing.layoutPdf(onLayout: (_) async => bytes!);
    } catch (error, stackTrace) {
      _logActionError('print', error, stackTrace);
      if (bytes == null) {
        if (context.mounted) {
          AppSnackbar.error(context, AppStrings.invoiceActionFailed);
        }
        return;
      }
      try {
        await InvoiceShareService.shareBytes(
          bytes: bytes,
          fileName: 'invoice_${_safeBillNumber()}',
          extension: 'pdf',
          mimeType: 'application/pdf',
          text: 'Invoice ${bill.billNumber}',
          subject: bill.billNumber,
        );
        if (context.mounted) {
          AppSnackbar.success(context, AppStrings.printUnavailableSharedPdf);
        }
      } catch (shareError, shareStackTrace) {
        _logActionError('print_fallback_share', shareError, shareStackTrace);
        if (context.mounted) {
          AppSnackbar.error(context, AppStrings.invoiceActionFailed);
        }
      }
    }
  }

  Future<void> _sharePdf(
    BuildContext context,
    BusinessConfig config,
    Map<String, String> serialNumberLookup,
  ) async {
    try {
      final bytes = await PdfInvoiceService.generateInvoicePdf(
        bill: bill,
        config: config,
        serialNumberLookup: serialNumberLookup,
      );
      await InvoiceShareService.shareBytes(
        bytes: bytes,
        fileName: 'invoice_${_safeBillNumber()}',
        extension: 'pdf',
        mimeType: 'application/pdf',
        text: 'Invoice ${bill.billNumber}',
        subject: bill.billNumber,
      );
    } catch (error, stackTrace) {
      _logActionError('share_pdf', error, stackTrace);
      if (context.mounted) {
        AppSnackbar.error(context, AppStrings.invoiceActionFailed);
      }
    }
  }

  Future<void> _shareImage(
    BuildContext context,
    BusinessConfig config,
    Map<String, String> serialNumberLookup,
  ) async {
    try {
      final bytes = await ImageInvoiceService.generateInvoiceImage(
        bill: bill,
        config: config,
        serialNumberLookup: serialNumberLookup,
      );
      await InvoiceShareService.shareBytes(
        bytes: bytes,
        fileName: 'invoice_${_safeBillNumber()}',
        extension: 'png',
        mimeType: 'image/png',
        text: 'Invoice ${bill.billNumber}',
        subject: bill.billNumber,
      );
    } catch (error, stackTrace) {
      _logActionError('share_image', error, stackTrace);
      if (context.mounted) {
        AppSnackbar.error(context, AppStrings.invoiceActionFailed);
      }
    }
  }

  String _safeBillNumber() {
    return bill.billNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  void _logActionError(String action, Object error, StackTrace stackTrace) {
    debugPrint('Invoice action "$action" failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.label.copyWith(color: AppColors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
