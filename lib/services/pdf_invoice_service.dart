import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../constants/formatters.dart';
import '../constants/uom_constants.dart';
import '../models/bill.dart';
import '../models/business_config.dart';
import '../models/line_item.dart';
import '../models/payment_info.dart';
import '../models/quotation.dart';

class PdfInvoiceService {
  PdfInvoiceService._();

  static Future<Uint8List> generateInvoicePdf({
    required Bill bill,
    required BusinessConfig config,
    InvoicePageSize? pageSize,
    Map<String, String> serialNumberLookup = const {},
  }) async {
    final doc = pw.Document();
    final format = _pageFormat(pageSize ?? config.defaultInvoicePageSize);
    final isComposition = config.isCompositionScheme;
    final showHsn = config.gstEnabled && !isComposition;

    // Determine title
    final String invoiceTitle;
    if (bill.paymentMode == PaymentMode.cash && !config.gstEnabled) {
      invoiceTitle = 'Cash Bill';
    } else if (isComposition) {
      invoiceTitle = 'Bill of Supply';
    } else {
      invoiceTitle = 'Tax Invoice';
    }

    // Decode logo bytes if present
    pw.MemoryImage? logoImage;
    if (config.logoBase64 != null && config.logoBase64!.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(base64Decode(config.logoBase64!));
      } catch (_) {
        logoImage = null;
      }
    }

    final businessName =
        config.businessName.isEmpty ? 'BillReady' : config.businessName;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
          buildBackground: config.showWatermarkOnInvoice
              ? (context) => pw.FullPage(
                    ignoreMargins: true,
                    child: pw.Center(
                      child: pw.Transform.rotate(
                        angle: -pi / 5,
                        child: pw.Text(
                          businessName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 48,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey200,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ),
                  )
              : null,
        ),
        build: (context) => [
          // ── HEADER (grey background) ────────────────────────────
          pw.Container(
            color: const PdfColor.fromInt(0xFFF0F0F0),
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Logo or placeholder
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      businessName.substring(0, min(2, businessName.length)).toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                pw.SizedBox(width: 16),
                // Business details (right-aligned)
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        businessName,
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                      if (config.address.isNotEmpty)
                        pw.Text(
                          config.address,
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      if (config.phone.isNotEmpty)
                        pw.Text(
                          'Ph: ${config.phone}',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      if (config.email.isNotEmpty)
                        pw.Text(
                          config.email,
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      if (config.upiId != null && config.upiId!.isNotEmpty)
                        pw.Text(
                          'UPI: ${config.upiId}',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      if (config.showGstinOnInvoice &&
                          config.gstEnabled &&
                          (config.gstin?.isNotEmpty ?? false))
                        pw.Text(
                          'GSTIN: ${config.gstin}',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                      if (config.businessType == BusinessType.pharmacy &&
                          config.drugLicenseNumber != null &&
                          config.drugLicenseNumber!.isNotEmpty)
                        pw.Text(
                          'Drug Lic: ${config.drugLicenseNumber}',
                          style: const pw.TextStyle(fontSize: 9),
                          textAlign: pw.TextAlign.right,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── INVOICE TITLE ─────────────────────────────────────
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Column(
              children: [
                pw.Text(
                  invoiceTitle.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),

          // ── BILL TO + INVOICE DETAILS (two columns) ───────────
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: BILL TO
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (bill.customer != null) ...[
                          pw.Text(
                            bill.customer!.name,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          if (config.showCustomerPhoneOnInvoice &&
                              (bill.customer!.phone?.isNotEmpty ?? false))
                            pw.Text(
                              bill.customer!.phone!,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          if (bill.customer!.gstin != null &&
                              bill.customer!.gstin!.isNotEmpty)
                            pw.Text(
                              'GSTIN: ${bill.customer!.gstin}',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                        ] else
                          pw.Text(
                            'Walk-in Customer',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        // Vehicle / device info
                        if (bill.vehicleReg != null ||
                            bill.vehicleMake != null) ...[
                          pw.SizedBox(height: 4),
                          if (config.businessType == BusinessType.mobileShop) ...[
                            if (bill.vehicleModel != null)
                              pw.Text(
                                'Model: ${bill.vehicleModel}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            if (bill.vehicleMake != null)
                              pw.Text(
                                'Brand: ${bill.vehicleMake}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            if (bill.vehicleReg != null)
                              pw.Text(
                                'IMEI No: ${bill.vehicleReg}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            if (bill.kmReading != null)
                              pw.Text(
                                'Color/Storage: ${bill.kmReading}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                          ] else ...[
                            if (bill.vehicleReg != null)
                              pw.Text(
                                'Reg: ${bill.vehicleReg}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            if (bill.vehicleMake != null ||
                                bill.vehicleModel != null)
                              pw.Text(
                                '${bill.vehicleMake ?? ''} ${bill.vehicleModel ?? ''}'
                                    .trim(),
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            if (bill.kmReading != null)
                              pw.Text(
                                'KM: ${bill.kmReading}',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                          ],
                        ],
                        // Clinic/Salon diagnosis
                        if (bill.diagnosis?.isNotEmpty ?? false) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Diagnosis: ${bill.diagnosis}',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Right: INVOICE DETAILS
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE DETAILS',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        _infoRow('Invoice No', bill.billNumber),
                        _infoRow(
                          'Date',
                          Formatters.date(bill.timestamp),
                        ),
                        _infoRow(
                          'Time',
                          Formatters.time(bill.timestamp),
                        ),
                        _infoRow(
                          'Payment',
                          _paymentModeLabel(bill.paymentMode),
                        ),
                        if (bill.creditAmount > 0)
                          _infoRow(
                            'Status',
                            'CREDIT DUE',
                            valueColor: PdfColors.red700,
                          )
                        else
                          _infoRow(
                            'Status',
                            'PAID',
                            valueColor: PdfColors.green700,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 12),

          // ── ITEMS TABLE ───────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: [
                'No',
                'Item Description',
                if (showHsn) 'HSN',
                'Qty',
                'Rate',
                'Gross',
                'Discount',
                'Net Amount',
              ],
              data: bill.lineItems.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final item = entry.value;
                final gross = item.product.sellingPrice * item.quantity;
                final discountAmt = item.lineDiscountAmount;
                return [
                  '$idx',
                  _lineItemTitle(item, config.businessType, serialNumberLookup),
                  if (showHsn) item.product.hsnCode ?? '',
                  UomConstants.display(item.product.displayUom, item.quantity),
                  Formatters.currency(item.product.sellingPrice),
                  Formatters.currency(gross),
                  discountAmt > 0
                      ? '-${Formatters.currency(discountAmt)}'
                      : '-',
                  Formatters.currency(item.discountedSubtotal),
                ];
              }).toList(),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 4,
              ),
              columnWidths: showHsn
                  ? {
                      0: const pw.FixedColumnWidth(25),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FixedColumnWidth(40),
                      3: const pw.FixedColumnWidth(35),
                      4: const pw.FixedColumnWidth(48),
                      5: const pw.FixedColumnWidth(48),
                      6: const pw.FixedColumnWidth(58),
                      7: const pw.FixedColumnWidth(68),
                    }
                  : {
                      0: const pw.FixedColumnWidth(25),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FixedColumnWidth(38),
                      3: const pw.FixedColumnWidth(52),
                      4: const pw.FixedColumnWidth(52),
                      5: const pw.FixedColumnWidth(58),
                      6: const pw.FixedColumnWidth(68),
                    },
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF0F0F0),
              ),
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(width: 0.4),
                top: pw.BorderSide(width: 0.4),
                bottom: pw.BorderSide(width: 0.4),
                left: pw.BorderSide(width: 0.4),
                right: pw.BorderSide(width: 0.4),
              ),
            ),
          ),

          pw.SizedBox(height: 12),

          // ── TOTALS (right-aligned) ────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.SizedBox()),
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _totalRow('Subtotal', Formatters.currency(bill.subtotal)),
                      if (bill.totalLineDiscount > 0)
                        _totalRow(
                          'Item Discounts',
                          '-${Formatters.currency(bill.totalLineDiscount)}',
                        ),
                      if (bill.discount > 0)
                        _totalRow(
                          'Bill Discount',
                          '-${Formatters.currency(bill.discount)}',
                        ),
                      if (!isComposition && !bill.isInterState && bill.cgst > 0)
                        _totalRow('CGST', Formatters.currency(bill.cgst)),
                      if (!isComposition && !bill.isInterState && bill.sgst > 0)
                        _totalRow('SGST', Formatters.currency(bill.sgst)),
                      if (!isComposition && bill.isInterState && bill.igst > 0)
                        _totalRow('IGST', Formatters.currency(bill.igst)),
                      pw.Divider(height: 8),
                      _totalRow(
                        'Grand Total',
                        Formatters.currency(bill.grandTotal),
                        bold: true,
                      ),
                      if (bill.advanceUsed > 0) ...[
                        _totalRow(
                          'Advance',
                          '-${Formatters.currency(bill.advanceUsed)}',
                          valueColor: PdfColors.green700,
                        ),
                        _totalRow(
                          'Amount Payable',
                          Formatters.currency(bill.grandTotal - bill.advanceUsed),
                          bold: true,
                        ),
                      ],
                      pw.SizedBox(height: 4),
                      _totalRow(
                        'Payment Mode',
                        _paymentModeLabel(bill.paymentMode),
                      ),
                      if (bill.amountReceived > 0)
                        _totalRow(
                          'Amount Received',
                          Formatters.currency(bill.amountReceived),
                        ),
                      if (bill.creditAmount > 0)
                        _totalRow(
                          'Balance Due',
                          Formatters.currency(bill.creditAmount),
                          valueColor: PdfColors.red700,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── VISIT NOTES (clinic/salon) ──────────────────────
          if (bill.visitNotes?.isNotEmpty ?? false)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: pw.Text(
                'Notes: ${bill.visitNotes}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),

          // ── FOOTER TEXTS ──────────────────────────────────────
          if (config.invoiceTermsText.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: pw.Text(
                config.invoiceTermsText.trim(),
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          if (config.invoiceFooterText.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: pw.Center(
                child: pw.Text(
                  config.invoiceFooterText.trim(),
                  style: const pw.TextStyle(fontSize: 10),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateQuotationPdf({
    required Quotation quotation,
    required BusinessConfig config,
  }) async {
    final doc = pw.Document();
    final format = _pageFormat(config.defaultInvoicePageSize);
    final businessName =
        config.businessName.isEmpty ? 'BillReady' : config.businessName;

    pw.MemoryImage? logoImage;
    if (config.logoBase64 != null && config.logoBase64!.isNotEmpty) {
      try {
        logoImage = pw.MemoryImage(base64Decode(config.logoBase64!));
      } catch (_) {
        logoImage = null;
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: format,
          margin: pw.EdgeInsets.zero,
        ),
        build: (context) => [
          // Header
          pw.Container(
            color: const PdfColor.fromInt(0xFFF0F0F0),
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      businessName.substring(0, min(2, businessName.length)).toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        businessName,
                        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right,
                      ),
                      if (config.address.isNotEmpty)
                        pw.Text(config.address, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
                      if (config.phone.isNotEmpty)
                        pw.Text('Ph: ${config.phone}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Title
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text(
              'QUOTATION',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
              textAlign: pw.TextAlign.center,
            ),
          ),
          // Two-column info
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        if ((quotation.customerName ?? quotation.customer?.name) != null)
                          pw.Text(
                            quotation.customerName ?? quotation.customer!.name,
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        if ((quotation.customerPhone ?? quotation.customer?.phone) != null)
                          pw.Text(
                            quotation.customerPhone ?? quotation.customer!.phone!,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        if (quotation.vehicleReg != null) ...[
                          pw.SizedBox(height: 4),
                          pw.Text('Reg: ${quotation.vehicleReg}', style: const pw.TextStyle(fontSize: 9)),
                          if (quotation.vehicleMake != null || quotation.vehicleModel != null)
                            pw.Text('${quotation.vehicleMake ?? ''} ${quotation.vehicleModel ?? ''}'.trim(), style: const pw.TextStyle(fontSize: 9)),
                          if (quotation.kmReading != null)
                            pw.Text('KM: ${quotation.kmReading}', style: const pw.TextStyle(fontSize: 9)),
                        ],
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DETAILS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                        pw.SizedBox(height: 4),
                        _infoRow('Quotation #', quotation.quotationNumber),
                        _infoRow('Date', Formatters.date(quotation.date)),
                        _infoRow('Valid Until', Formatters.date(quotation.validUntil)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headers: ['No', 'Item', 'Qty', 'Rate', 'Amount'],
              data: quotation.items.asMap().entries.map((e) => [
                '${e.key + 1}',
                e.value.product.name,
                UomConstants.display(e.value.product.displayUom, e.value.quantity),
                Formatters.currency(e.value.product.sellingPrice),
                Formatters.currency(e.value.subtotal),
              ]).toList(),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF0F0F0)),
              border: const pw.TableBorder(
                horizontalInside: pw.BorderSide(width: 0.4),
                top: pw.BorderSide(width: 0.4),
                bottom: pw.BorderSide(width: 0.4),
                left: pw.BorderSide(width: 0.4),
                right: pw.BorderSide(width: 0.4),
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: pw.Row(
              children: [
                pw.Expanded(child: pw.SizedBox()),
                pw.SizedBox(
                  width: 200,
                  child: pw.Column(
                    children: [
                      _totalRow('Subtotal', Formatters.currency(quotation.subtotal)),
                      if (quotation.discount > 0)
                        _totalRow('Discount', '-${Formatters.currency(quotation.discount)}'),
                      if (!quotation.isInterState && quotation.cgst > 0)
                        _totalRow('CGST', Formatters.currency(quotation.cgst)),
                      if (!quotation.isInterState && quotation.sgst > 0)
                        _totalRow('SGST', Formatters.currency(quotation.sgst)),
                      if (quotation.isInterState && quotation.igst > 0)
                        _totalRow('IGST', Formatters.currency(quotation.igst)),
                      pw.Divider(height: 8),
                      _totalRow('Grand Total', Formatters.currency(quotation.grandTotal), bold: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (quotation.notes?.isNotEmpty ?? false)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: pw.Text('Notes: ${quotation.notes}', style: const pw.TextStyle(fontSize: 9)),
            ),
          if (config.invoiceTermsText.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: pw.Text(config.invoiceTermsText.trim(), style: const pw.TextStyle(fontSize: 9)),
            ),
          if (config.invoiceFooterText.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: pw.Center(child: pw.Text(config.invoiceFooterText.trim(), style: const pw.TextStyle(fontSize: 10))),
            ),
        ],
      ),
    );

    return doc.save();
  }

  // ── helpers ──────────────────────────────────────────────────

  static PdfPageFormat _pageFormat(InvoicePageSize pageSize) {
    switch (pageSize) {
      case InvoicePageSize.a4:
        return PdfPageFormat.a4;
      case InvoicePageSize.a5:
        return PdfPageFormat.a5;
    }
  }

  static pw.Widget _infoRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(
    String label,
    String value, {
    bool bold = false,
    PdfColor? valueColor,
  }) {
    final style = pw.TextStyle(
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: bold ? 11 : 10,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(width: 8),
          pw.Text(value, style: style.copyWith(color: valueColor)),
        ],
      ),
    );
  }

  static String _lineItemTitle(
    LineItem item,
    BusinessType businessType,
    Map<String, String> serialNumberLookup,
  ) {
    var title = item.product.name;
    if (businessType == BusinessType.pharmacy && item.batch != null) {
      title =
          '$title\nBatch ${item.batch!.batchNumber} | Exp ${Formatters.date(item.batch!.expiryDate)}';
    } else if ((businessType == BusinessType.salon ||
            businessType == BusinessType.clinic) &&
        item.product.isService &&
        item.product.durationMinutes != null) {
      title = '$title (${item.product.durationMinutes} min)';
    }
    if (item.serialNumberIds.isNotEmpty && serialNumberLookup.isNotEmpty) {
      final numbers = item.serialNumberIds
          .map((id) => serialNumberLookup[id])
          .whereType<String>()
          .toList();
      if (numbers.isNotEmpty) {
        title = '$title\nS/N: ${numbers.join(', ')}';
      }
    }
    return title;
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
    }
  }
}
