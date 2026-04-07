import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/customer.dart';
import '../models/customer_payment_entry.dart';
import '../models/payment_info.dart';
import '../providers/bill_provider.dart';
import '../providers/customer_provider.dart';
import 'app_snackbar.dart';

class RecordPaymentSheet extends StatefulWidget {
  final Customer customer;

  const RecordPaymentSheet({super.key, required this.customer});

  static Future<void> show(BuildContext context, Customer customer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: context.read<CustomerProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<BillProvider>(),
          ),
        ],
        child: RecordPaymentSheet(customer: customer),
      ),
    );
  }

  @override
  State<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  SettlementPaymentMode _paymentMode = SettlementPaymentMode.cash;
  String? _selectedBillId;
  String? _error;

  double get _enteredAmount =>
      double.tryParse(_amountController.text) ?? 0;

  double get _balanceAfter {
    final after = widget.customer.outstandingBalance - _enteredAmount;
    return after < 0 ? 0 : after;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.read<BillProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    // Show only credit bills that still have an outstanding balance,
    // oldest first (FIFO aging). Fully-settled bills are filtered out
    // so cashiers can't accidentally link a payment to a closed bill.
    final outstandingBills = billProvider.bills
        .where((b) =>
            b.customer?.id == widget.customer.id &&
            b.paymentMode == PaymentMode.credit &&
            customerProvider.getOutstandingForBill(b.id, b.creditAmount) >
                0.009)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.medium,
        right: AppSpacing.medium,
        top: AppSpacing.medium,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.medium,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(AppStrings.recordPayment, style: AppTypography.heading),
            const SizedBox(height: AppSpacing.small),
            Text(widget.customer.name, style: AppTypography.body),
            const SizedBox(height: AppSpacing.small),
            // Outstanding balance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.small),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.balanceBefore, style: AppTypography.label),
                  Text(
                    Formatters.currency(widget.customer.outstandingBalance),
                    style: AppTypography.currency.copyWith(
                      color: AppColors.error,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            // Amount
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              autofocus: true,
              decoration: InputDecoration(
                labelText: AppStrings.amountLabel,
                prefixText: '${AppStrings.rsPrefix} ',
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                ),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: AppSpacing.small),
            // Balance after preview
            if (_enteredAmount > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.06),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.balanceAfter, style: AppTypography.label),
                    Text(
                      Formatters.currency(_balanceAfter),
                      style: AppTypography.currency.copyWith(
                        color: _balanceAfter == 0
                            ? AppColors.success
                            : AppColors.error,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.medium),
            // Payment mode
            Text(AppStrings.paymentModeLabel, style: AppTypography.label),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.small,
              children: SettlementPaymentMode.values
                  .where((mode) => mode.applicableForSettlements)
                  .map((mode) {
                final selected = _paymentMode == mode;
                return InkWell(
                  onTap: () => setState(() => _paymentMode = mode),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.buttonRadius),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryLight(0.10)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.muted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      mode.label,
                      style: AppTypography.label.copyWith(
                        color: selected ? AppColors.primary : AppColors.muted,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.medium),
            // Bill reference
            if (outstandingBills.isNotEmpty) ...[
              Text(AppStrings.againstBill, style: AppTypography.label),
              const SizedBox(height: AppSpacing.small),
              DropdownButtonFormField<String?>(
                initialValue: _selectedBillId,
                decoration: InputDecoration(
                  hintText: AppStrings.selectBill,
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(AppStrings.generalPayment),
                  ),
                  ...outstandingBills.map(
                    (bill) {
                      final outstanding = customerProvider
                          .getOutstandingForBill(bill.id, bill.creditAmount);
                      return DropdownMenuItem<String?>(
                        value: bill.id,
                        child: Text(
                          '${bill.billNumber} • ${Formatters.currency(outstanding)} due',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ],
                onChanged: (v) => setState(() => _selectedBillId = v),
              ),
              const SizedBox(height: AppSpacing.medium),
            ],
            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: AppStrings.paymentNotes,
                hintText: AppStrings.paymentNotesHint,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.medium),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _recordPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.buttonRadius),
                  ),
                ),
                child: const Text(AppStrings.recordPayment),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _recordPayment() {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = AppStrings.amountGreaterThanZero);
      return;
    }
    if (amount > widget.customer.outstandingBalance) {
      setState(() => _error = AppStrings.amountCannotExceedOutstanding);
      return;
    }

    final customerProvider = context.read<CustomerProvider>();

    // When a specific bill is selected, #43 stores the bill's primary
    // key (bill.id) as the linkage reference so getPaidAmountForBill /
    // getOutstandingForBill queries resolve correctly. Also reject
    // payments that would overpay the selected bill — callers should
    // either split the payment or pick "General Payment".
    String? billRef;
    if (_selectedBillId != null) {
      final billProvider = context.read<BillProvider>();
      final bill =
          billProvider.bills.where((b) => b.id == _selectedBillId).firstOrNull;
      if (bill != null) {
        final billOutstanding = customerProvider.getOutstandingForBill(
          bill.id,
          bill.creditAmount,
        );
        if (amount > billOutstanding + 0.009) {
          setState(() => _error =
              'Amount exceeds outstanding on bill ${bill.billNumber} (${Formatters.currency(billOutstanding)})');
          return;
        }
        billRef = bill.id;
      }
    }

    final notes = _notesController.text.trim();
    customerProvider.recordPayment(
      widget.customer.id,
      amount,
      paymentMode: _paymentMode,
      notes: notes.isNotEmpty ? notes : null,
      billReference: billRef,
    );
    Navigator.pop(context);
    AppSnackbar.success(
      context,
      'Payment of ${Formatters.currency(amount)} recorded',
    );
  }
}
