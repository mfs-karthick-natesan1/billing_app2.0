import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';

class Gstr1ExportScreen extends StatefulWidget {
  const Gstr1ExportScreen({super.key});

  @override
  State<Gstr1ExportScreen> createState() => _Gstr1ExportScreenState();
}

class _Gstr1ExportScreenState extends State<Gstr1ExportScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  List<Bill> _filteredBills(List<Bill> allBills) {
    final start = DateTime(_selectedMonth.year, _selectedMonth.month);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    return allBills
        .where((b) => !b.timestamp.isBefore(start) && b.timestamp.isBefore(end))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final bills = _filteredBills(billProvider.bills);

    double totalTaxable = 0;
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;

    for (final bill in bills) {
      for (final item in bill.lineItems) {
        totalTaxable += item.taxableAmount;
        if (bill.isInterState) {
          totalIgst += item.igstAmount;
        } else {
          totalCgst += item.cgstAmount;
          totalSgst += item.sgstAmount;
        }
      }
    }

    return Scaffold(
      appBar: const AppTopBar(
        title: AppStrings.gstr1Export,
        showBack: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month picker
            InkWell(
              onTap: _pickMonth,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.muted.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedMonth),
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.calendar_month, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),

            if (bills.isEmpty)
              const Expanded(
                child: EmptyState(
                  icon: Icons.receipt_long,
                  title: AppStrings.noBillsInPeriod,
                  description: '',
                ),
              )
            else ...[
              // Summary cards
              _summaryCard(AppStrings.totalBills, '${bills.length}'),
              const SizedBox(height: AppSpacing.small),
              _summaryCard(
                AppStrings.totalTaxableValue,
                Formatters.currency(totalTaxable),
              ),
              const SizedBox(height: AppSpacing.small),
              _summaryCard(AppStrings.totalCgst, Formatters.currency(totalCgst)),
              const SizedBox(height: AppSpacing.small),
              _summaryCard(AppStrings.totalSgst, Formatters.currency(totalSgst)),
              const SizedBox(height: AppSpacing.small),
              _summaryCard(AppStrings.totalIgst, Formatters.currency(totalIgst)),

              const Spacer(),

              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _exportCsv(bills),
                  icon: const Icon(Icons.download),
                  label: Text(
                    AppStrings.exportCsv,
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
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.label),
          Text(
            value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      setState(() => _selectedMonth = DateTime(picked.year, picked.month));
    }
  }

  /// Prevents CSV injection by prefixing values that start with formula
  /// trigger characters (=, +, -, @, tab, carriage return) with a single quote.
  static String _sanitizeCsv(String value) {
    if (value.isEmpty) return value;
    const triggers = ['=', '+', '-', '@', '\t', '\r'];
    if (triggers.any((c) => value.startsWith(c))) {
      return "'$value";
    }
    return value;
  }

  Future<void> _exportCsv(List<Bill> bills) async {
    try {
      final lines = <String>[
        'Invoice No,Invoice Date,Customer Name,Customer GSTIN,HSN/SAC,Taxable Value,CGST,SGST,IGST,Total',
      ];

      for (final bill in bills) {
        for (final item in bill.lineItems) {
          final date = DateFormat('dd-MM-yyyy').format(bill.timestamp);
          final customerName = _sanitizeCsv(bill.customer?.name ?? '');
          final customerGstin = _sanitizeCsv(bill.customer?.gstin ?? '');
          final hsn = _sanitizeCsv(item.product.hsnCode ?? '');
          final taxable = item.taxableAmount.toStringAsFixed(2);
          final cgst = bill.isInterState ? '0.00' : item.cgstAmount.toStringAsFixed(2);
          final sgst = bill.isInterState ? '0.00' : item.sgstAmount.toStringAsFixed(2);
          final igst = bill.isInterState ? item.igstAmount.toStringAsFixed(2) : '0.00';
          final total = item.totalWithGst.toStringAsFixed(2);

          lines.add(
            '${bill.billNumber},$date,"$customerName","$customerGstin",$hsn,$taxable,$cgst,$sgst,$igst,$total',
          );
        }
      }

      final dir = await getTemporaryDirectory();
      final monthStr = DateFormat('yyyy_MM').format(_selectedMonth);
      final file = File('${dir.path}/GSTR1_$monthStr.csv');
      await file.writeAsString(lines.join('\n'));

      if (!mounted) return;

      await Share.shareXFiles([XFile(file.path)]);
      // Clean up after sharing
      if (await file.exists()) await file.delete();

      if (!mounted) return;
      AppSnackbar.success(context, AppStrings.csvExported);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, AppStrings.csvExportFailed);
    }
  }
}
