import '../constants/formatters.dart';
import '../constants/uom_constants.dart';
import '../models/bill.dart';
import '../models/business_config.dart';
import '../models/line_item.dart';
import '../models/payment_info.dart';
import '../models/quotation.dart';

class InvoiceService {
  InvoiceService._();

  static String buildWhatsappInvoiceText({
    required Bill bill,
    required BusinessConfig config,
  }) {
    final isComposition = config.isCompositionScheme;
    final invoiceTitle = isComposition ? 'Bill of Supply' : 'Tax Invoice';

    final lines = <String>[
      '*${config.businessName.isEmpty ? 'BillReady' : config.businessName}*',
      if (config.phone.isNotEmpty) '📞 ${config.phone}',
      if (config.showGstinOnInvoice &&
          config.gstEnabled &&
          (config.gstin?.isNotEmpty ?? false))
        'GSTIN: ${config.gstin}',
      if (config.businessType == BusinessType.pharmacy &&
          config.drugLicenseNumber != null &&
          config.drugLicenseNumber!.isNotEmpty)
        'Drug Lic: ${config.drugLicenseNumber}',
      '━━━━━━━━━━━━━━━━━━',
      '*$invoiceTitle #${bill.billNumber}*',
      '📅 ${Formatters.date(bill.timestamp)} | ⏰ ${Formatters.time(bill.timestamp)}',
      if (bill.customer != null)
        _customerLine(
          bill.customer!.name,
          config.showCustomerPhoneOnInvoice ? bill.customer!.phone : null,
          bill.customer!.gstin,
        ),
      '━━━━━━━━━━━━━━━━━━',
      ...bill.lineItems.map((item) => _lineItemLine(item, config.businessType)),
      '━━━━━━━━━━━━━━━━━━',
      'Subtotal: ${Formatters.currency(bill.subtotal)}',
      if (bill.discount > 0) 'Discount: -${Formatters.currency(bill.discount)}',
      if (!isComposition && !bill.isInterState && (bill.cgst > 0 || bill.sgst > 0)) ...[
        'CGST: ${Formatters.currency(bill.cgst)}',
        'SGST: ${Formatters.currency(bill.sgst)}',
      ],
      if (!isComposition && bill.isInterState && bill.igst > 0)
        'IGST: ${Formatters.currency(bill.igst)}',
      '*Total: ${Formatters.currency(bill.grandTotal)}*',
      if (bill.advanceUsed > 0) ...[
        'Advance: -${Formatters.currency(bill.advanceUsed)}',
        '*Amount Payable: ${Formatters.currency(bill.grandTotal - bill.advanceUsed)}*',
      ],
      '━━━━━━━━━━━━━━━━━━',
      'Paid: ${_paymentModeLabel(bill.paymentMode)}'
          '${bill.amountReceived > 0 ? ' - ${Formatters.currency(bill.amountReceived)}' : ''}',
      if (bill.paymentMode == PaymentMode.credit && bill.creditAmount > 0)
        '*BALANCE DUE: ${Formatters.currency(bill.creditAmount)}*',
      if (config.invoiceTermsText.trim().isNotEmpty)
        config.invoiceTermsText.trim(),
      if (config.invoiceFooterText.trim().isNotEmpty)
        config.invoiceFooterText.trim(),
    ];

    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  static String _customerLine(String name, String? phone, String? gstin) {
    final parts = <String>['Customer: $name'];
    if (phone != null && phone.trim().isNotEmpty) {
      parts[0] = 'Customer: $name (${phone.trim()})';
    }
    if (gstin != null && gstin.trim().isNotEmpty) {
      parts.add('GSTIN: ${gstin.trim()}');
    }
    return parts.join('\n');
  }

  static String _lineItemLine(LineItem lineItem, BusinessType businessType) {
    final qtyDisplay = UomConstants.display(
      lineItem.product.displayUom,
      lineItem.quantity,
    );
    final base =
        '${lineItem.product.name} × $qtyDisplay - ${Formatters.currency(lineItem.subtotal)}';

    if (businessType == BusinessType.pharmacy && lineItem.batch != null) {
      final expiry = Formatters.date(lineItem.batch!.expiryDate);
      return '$base (Batch: ${lineItem.batch!.batchNumber}, Exp: $expiry)';
    }

    if ((businessType == BusinessType.salon ||
            businessType == BusinessType.clinic) &&
        lineItem.product.isService &&
        lineItem.product.durationMinutes != null) {
      return '$base (${lineItem.product.durationMinutes} min)';
    }

    return base;
  }

  static String buildQuotationText({
    required Quotation quotation,
    required BusinessConfig config,
  }) {
    final lines = <String>[
      '*${config.businessName.isEmpty ? 'BillReady' : config.businessName}*',
      if (config.phone.isNotEmpty) config.phone,
      if (config.showGstinOnInvoice &&
          config.gstEnabled &&
          (config.gstin?.isNotEmpty ?? false))
        'GSTIN: ${config.gstin}',
      '━━━━━━━━━━━━━━━━━━',
      '*ESTIMATE #${quotation.quotationNumber}*',
      'Date: ${Formatters.date(quotation.date)}',
      'Valid Until: ${Formatters.date(quotation.validUntil)}',
      if (quotation.customerName != null ||
          quotation.customer?.name != null)
        'Customer: ${quotation.customerName ?? quotation.customer?.name}',
      '━━━━━━━━━━━━━━━━━━',
      ...quotation.items.map((item) => _lineItemLine(item, config.businessType)),
      '━━━━━━━━━━━━━━━━━━',
      'Subtotal: ${Formatters.currency(quotation.subtotal)}',
      if (quotation.discount > 0)
        'Discount: -${Formatters.currency(quotation.discount)}',
      if (!quotation.isInterState && quotation.cgst > 0) ...[
        'CGST: ${Formatters.currency(quotation.cgst)}',
        'SGST: ${Formatters.currency(quotation.sgst)}',
      ],
      if (quotation.isInterState && quotation.igst > 0)
        'IGST: ${Formatters.currency(quotation.igst)}',
      '*Total: ${Formatters.currency(quotation.grandTotal)}*',
      '━━━━━━━━━━━━━━━━━━',
      if (quotation.notes != null && quotation.notes!.isNotEmpty)
        quotation.notes!,
    ];

    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  static String _paymentModeLabel(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.credit:
        return 'Credit (Udhar)';
      case PaymentMode.split:
        return 'Split (Cash + UPI)';
      case PaymentMode.bankTransfer:
        return 'Bank Transfer';
      case PaymentMode.cheque:
        return 'Cheque';
    }
  }
}
