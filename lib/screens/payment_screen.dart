import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../models/payment_info.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/serial_number_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/app_text_input.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/customer_list_sheet.dart';
import '../widgets/payment_mode_selector.dart';
import '../widgets/web_constraint.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMode _paymentMode = PaymentMode.cash;
  CreditType _creditType = CreditType.full;
  final _amountReceivedController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final _splitCashController = TextEditingController();
  final _splitUpiController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _visitNotesController = TextEditingController();
  Customer? _selectedCustomer;
  bool _useAdvance = false;
  String? _amountError;
  String? _customerError;
  String? _amountPaidError;
  String? _splitError;

  @override
  void initState() {
    super.initState();
    final billProvider = context.read<BillProvider>();
    final isInterState = context.read<BusinessConfigProvider>().isInterState;
    final grandTotal = billProvider.activeGrandTotal(isInterState: isInterState);
    _amountReceivedController.text = grandTotal.toStringAsFixed(2);

    final existingCustomer = billProvider.activeCustomer;
    if (existingCustomer != null) {
      _selectedCustomer = existingCustomer;
    }

    _splitCashController.text = grandTotal.toStringAsFixed(2);
    _splitUpiController.text = '0.00';
    _diagnosisController.text = billProvider.activeDiagnosis ?? '';
    _visitNotesController.text = billProvider.activeVisitNotes ?? '';
  }

  @override
  void dispose() {
    _amountReceivedController.dispose();
    _amountPaidController.dispose();
    _splitCashController.dispose();
    _splitUpiController.dispose();
    _diagnosisController.dispose();
    _visitNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final businessConfig = context.watch<BusinessConfigProvider>();
    final gstEnabled = businessConfig.gstEnabled;
    final isInterState = businessConfig.isInterState;
    final isClinic = businessConfig.isClinic;
    final grandTotal = billProvider.activeGrandTotal(isInterState: isInterState);

    return Scaffold(
      appBar: const AppTopBar(title: AppStrings.payment, showBack: true),
      body: WebConstraint(
        maxWidth: 700,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill Summary
            _summaryRow(
              'Items',
              '${billProvider.activeLineItems.length} items',
            ),
            _summaryRow(
              'Subtotal',
              Formatters.currency(billProvider.activeSubtotal),
            ),
            if (billProvider.activeDiscount > 0)
              _summaryRow(
                'Discount',
                '-${Formatters.currency(billProvider.activeDiscount)}',
                valueColor: AppColors.error,
              ),
            if (gstEnabled && !isInterState && billProvider.activeCgst(isInterState: isInterState) > 0)
              _summaryRow('CGST', Formatters.currency(billProvider.activeCgst(isInterState: isInterState))),
            if (gstEnabled && !isInterState && billProvider.activeSgst(isInterState: isInterState) > 0)
              _summaryRow('SGST', Formatters.currency(billProvider.activeSgst(isInterState: isInterState))),
            if (gstEnabled && isInterState && billProvider.activeIgst(isInterState: isInterState) > 0)
              _summaryRow('IGST', Formatters.currency(billProvider.activeIgst(isInterState: isInterState))),
            const Divider(),
            _summaryRow(
              'Grand Total',
              Formatters.currency(grandTotal),
              isBold: true,
            ),
            const SizedBox(height: AppSpacing.large),

            // Edit mode banner
            if (billProvider.isEditMode) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.small),
                margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight(0.10),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Editing Bill #${billProvider.editingBillNumber}',
                      style: AppTypography.label.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],

            // Advance payment section
            Builder(builder: (ctx) {
              final customer = billProvider.activeCustomer ?? _selectedCustomer;
              final enableAdvance = context.read<BusinessConfigProvider>().enableAdvancePayment;
              if (!enableAdvance || customer == null || customer.advanceBalance <= 0) {
                return const SizedBox.shrink();
              }
              final advBalance = customer.advanceBalance;
              final advanceApplied = _useAdvance ? advBalance.clamp(0.0, grandTotal) : 0.0;
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Advance Balance', style: AppTypography.label),
                        Text(
                          Formatters.currency(advBalance),
                          style: AppTypography.body.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_useAdvance)
                          Text(
                            'Applied: ${Formatters.currency(advanceApplied)}',
                            style: AppTypography.label.copyWith(color: AppColors.success),
                          ),
                      ],
                    ),
                    Switch(
                      value: _useAdvance,
                      onChanged: (v) => setState(() => _useAdvance = v),
                      activeTrackColor: AppColors.success,
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
              );
            }),

            // Clinic visit notes
            if (isClinic) ...[
              Text(
                AppStrings.visitNotesSection,
                style: AppTypography.heading.copyWith(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                controller: _diagnosisController,
                decoration: InputDecoration(
                  labelText: AppStrings.diagnosisLabel,
                  hintText: AppStrings.diagnosisHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
                onChanged: (v) => billProvider.setVisitNotes(
                  diagnosis: v.isNotEmpty ? v : null,
                  visitNotes: _visitNotesController.text.isNotEmpty
                      ? _visitNotesController.text
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                controller: _visitNotesController,
                decoration: InputDecoration(
                  labelText: AppStrings.visitNotesLabel,
                  hintText: AppStrings.visitNotesHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
                maxLines: 2,
                onChanged: (v) => billProvider.setVisitNotes(
                  diagnosis: _diagnosisController.text.isNotEmpty
                      ? _diagnosisController.text
                      : null,
                  visitNotes: v.isNotEmpty ? v : null,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
            ],

            // Payment Mode
            Text(
              'Payment Method',
              style: AppTypography.heading.copyWith(fontSize: 16),
            ),
            const SizedBox(height: AppSpacing.small),
            PaymentModeSelector(
              selected: _paymentMode,
              onChanged: (mode) => setState(() {
                _paymentMode = mode;
                _amountError = null;
                _customerError = null;
                _amountPaidError = null;
                _splitError = null;
                if (mode == PaymentMode.split) {
                  _splitCashController.text = grandTotal.toStringAsFixed(2);
                  _splitUpiController.text = '0.00';
                }
              }),
            ),
            const SizedBox(height: AppSpacing.large),

            // Cash fields
            if (_paymentMode == PaymentMode.cash) ...[
              AppTextInput(
                label: AppStrings.amountReceived,
                required: true,
                controller: _amountReceivedController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefix: 'Rs. ',
                errorText: _amountError,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (_) {
                  setState(() => _amountError = null);
                },
              ),
              const SizedBox(height: AppSpacing.small),
              Builder(
                builder: (_) {
                  final received =
                      double.tryParse(_amountReceivedController.text) ?? 0;
                  if (received > grandTotal) {
                    return Text(
                      '${AppStrings.change}: ${Formatters.currency(received - grandTotal)}',
                      style: AppTypography.body.copyWith(
                        color: AppColors.success,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],

            if (_paymentMode == PaymentMode.upi) ...[
              _UpiSection(
                upiId: businessConfig.upiId,
                amount: grandTotal,
                businessName: businessConfig.businessName,
              ),
            ],

            // Split payment fields
            if (_paymentMode == PaymentMode.split) ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextInput(
                      label: 'Cash Amount',
                      controller: _splitCashController,
                      prefix: 'Rs. ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      onChanged: (v) {
                        final cash = double.tryParse(v) ?? 0;
                        final upi = grandTotal - cash;
                        _splitUpiController.text = upi >= 0 ? upi.toStringAsFixed(2) : '0.00';
                        setState(() => _splitError = null);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: AppTextInput(
                      label: 'UPI Amount',
                      controller: _splitUpiController,
                      prefix: 'Rs. ',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      onChanged: (v) {
                        final upi = double.tryParse(v) ?? 0;
                        final cash = grandTotal - upi;
                        _splitCashController.text = cash >= 0 ? cash.toStringAsFixed(2) : '0.00';
                        setState(() => _splitError = null);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Builder(builder: (_) {
                final cash = double.tryParse(_splitCashController.text) ?? 0;
                final upi = double.tryParse(_splitUpiController.text) ?? 0;
                final total = cash + upi;
                final diff = (total - grandTotal).abs();
                if (diff > 0.01) {
                  return Text(
                    'Total must equal ${Formatters.currency(grandTotal)} (current: ${Formatters.currency(total)})',
                    style: AppTypography.label.copyWith(color: AppColors.error),
                  );
                }
                return Text(
                  'Cash ${Formatters.currency(cash)} + UPI ${Formatters.currency(upi)}',
                  style: AppTypography.label.copyWith(color: AppColors.success),
                );
              }),
              if (_splitError != null) ...[
                const SizedBox(height: 4),
                Text(_splitError!, style: AppTypography.label.copyWith(color: AppColors.error)),
              ],
            ],

            // Credit fields
            if (_paymentMode == PaymentMode.credit) ...[
              // Customer selection
              Text(
                'Customer *',
                style: AppTypography.label.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () async {
                  final customer = await CustomerListSheet.show(context);
                  if (customer != null) {
                    setState(() {
                      _selectedCustomer = customer;
                      _customerError = null;
                    });
                  }
                },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: _customerError != null
                          ? AppColors.error
                          : AppColors.muted.withValues(alpha: 0.3),
                      width: _customerError != null ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedCustomer?.name ?? AppStrings.selectCustomer,
                    style: AppTypography.body.copyWith(
                      color: _selectedCustomer != null
                          ? AppColors.onSurface
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
              if (_customerError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _customerError!,
                  style: AppTypography.label.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.medium),

              // Payment type
              Text('Payment Type', style: AppTypography.label),
              const SizedBox(height: AppSpacing.small),
              Row(
                children: [
                  Expanded(
                    child: _PaymentTypeChip(
                      label: AppStrings.fullCredit,
                      selected: _creditType == CreditType.full,
                      onTap: () =>
                          setState(() => _creditType = CreditType.full),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: _PaymentTypeChip(
                      label: AppStrings.partialPayment,
                      selected: _creditType == CreditType.partial,
                      onTap: () =>
                          setState(() => _creditType = CreditType.partial),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),

              if (_creditType == CreditType.full)
                Text(
                  '${AppStrings.creditAmount}: ${Formatters.currency(grandTotal)}',
                  style: AppTypography.currency.copyWith(
                    color: AppColors.error,
                  ),
                ),

              if (_creditType == CreditType.partial) ...[
                AppTextInput(
                  label: AppStrings.amountPaidNow,
                  required: true,
                  controller: _amountPaidController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefix: 'Rs. ',
                  errorText: _amountPaidError,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (_) {
                    setState(() => _amountPaidError = null);
                  },
                ),
                const SizedBox(height: AppSpacing.small),
                Builder(
                  builder: (_) {
                    final paid =
                        double.tryParse(_amountPaidController.text) ?? 0;
                    final credit = grandTotal - paid;
                    if (credit > 0) {
                      return Text(
                        '${AppStrings.creditAmount}: ${Formatters.currency(credit)}',
                        style: AppTypography.currency.copyWith(
                          color: AppColors.error,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ],
        ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => _completeBill(context, grandTotal),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: Text(
                AppStrings.completeBill,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? AppTypography.body.copyWith(fontWeight: FontWeight.bold)
                : AppTypography.label,
          ),
          Text(
            value,
            style: isBold
                ? AppTypography.currency
                : AppTypography.label.copyWith(
                    color: valueColor ?? AppColors.onSurface,
                  ),
          ),
        ],
      ),
    );
  }

  void _completeBill(BuildContext context, double grandTotal) {
    switch (_paymentMode) {
      case PaymentMode.cash:
        final received = double.tryParse(_amountReceivedController.text) ?? 0;
        if (received < grandTotal) {
          setState(
            () => _amountError =
                '${AppStrings.amountMinError} ${Formatters.currency(grandTotal)}',
          );
          return;
        }

        _finishBill(
          context,
          PaymentInfo(
            mode: PaymentMode.cash,
            amountReceived: received,
            customer:
                _selectedCustomer ??
                context.read<BillProvider>().activeCustomer,
          ),
        );
        return;

      case PaymentMode.upi:
        _finishBill(
          context,
          PaymentInfo(
            mode: PaymentMode.upi,
            amountReceived: grandTotal,
            customer:
                _selectedCustomer ??
                context.read<BillProvider>().activeCustomer,
          ),
        );
        return;

      case PaymentMode.split:
        final cash = double.tryParse(_splitCashController.text) ?? 0;
        final upi = double.tryParse(_splitUpiController.text) ?? 0;
        if ((cash + upi - grandTotal).abs() > 0.01) {
          setState(() => _splitError =
              'Cash + UPI must equal ${Formatters.currency(grandTotal)}');
          return;
        }
        if (cash < 0 || upi < 0) {
          setState(() => _splitError = 'Amounts cannot be negative');
          return;
        }
        _finishBill(
          context,
          PaymentInfo(
            mode: PaymentMode.split,
            amountReceived: grandTotal,
            splitCashAmount: cash,
            splitUpiAmount: upi,
            customer:
                _selectedCustomer ??
                context.read<BillProvider>().activeCustomer,
          ),
        );
        return;

      case PaymentMode.bankTransfer:
        _finishBill(
          context,
          PaymentInfo(
            mode: PaymentMode.bankTransfer,
            amountReceived: grandTotal,
            customer:
                _selectedCustomer ??
                context.read<BillProvider>().activeCustomer,
          ),
        );
        return;

      case PaymentMode.credit:
        if (_selectedCustomer == null) {
          setState(() => _customerError = AppStrings.customerRequired);
          return;
        }

        if (_creditType == CreditType.partial) {
          final paid = double.tryParse(_amountPaidController.text) ?? 0;
          if (paid <= 0) {
            setState(() => _amountPaidError = AppStrings.amountGreaterThanZero);
            return;
          }
          if (paid >= grandTotal) {
            setState(
              () => _amountPaidError = AppStrings.amountCannotExceedTotal,
            );
            return;
          }

          _finishBill(
            context,
            PaymentInfo(
              mode: PaymentMode.credit,
              creditType: CreditType.partial,
              amountReceived: paid,
              creditAmount: grandTotal - paid,
              customer: _selectedCustomer,
            ),
          );
          return;
        }

        _finishBill(
          context,
          PaymentInfo(
            mode: PaymentMode.credit,
            creditType: CreditType.full,
            amountReceived: 0,
            creditAmount: grandTotal,
            customer: _selectedCustomer,
          ),
        );
        return;
    }
  }

  Future<void> _finishBill(BuildContext context, PaymentInfo paymentInfo) async {
    final billProvider = context.read<BillProvider>();
    final productProvider = context.read<ProductProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final businessConfig = context.read<BusinessConfigProvider>();
    final gstEnabled = businessConfig.gstEnabled;
    final isInterState = businessConfig.isInterState;

    // Client-side pre-check (fast path); server enforces authoritatively in RPC
    if (!billProvider.isEditMode) {
      final subscriptionProvider = context.read<SubscriptionProvider>();
      if (!subscriptionProvider.canAddBill) {
        final max = subscriptionProvider.maxBillsPerMonth;
        if (context.mounted) {
          showDialog<void>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Bill Limit Reached'),
              content: Text(
                'You have used all $max bills allowed this month on your current plan. '
                'Upgrade to continue creating bills.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/subscription');
                  },
                  child: const Text('Upgrade'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    final customer = billProvider.activeCustomer ?? paymentInfo.customer ?? _selectedCustomer;
    final advBalance = customer?.advanceBalance ?? 0.0;
    final grandTotal = billProvider.activeGrandTotal(isInterState: isInterState);
    final advanceUsed = _useAdvance ? advBalance.clamp(0.0, grandTotal) : 0.0;

    if (_useAdvance && advanceUsed > 0 && paymentInfo.customer != null) {
      customerProvider.deductAdvance(paymentInfo.customer!.id, advanceUsed);
    }

    final isEdit = billProvider.isEditMode;

    Bill bill;
    try {
      bill = await billProvider.completeBillAsync(
        paymentInfo: paymentInfo,
        gstEnabled: gstEnabled,
        productProvider: productProvider,
        customerProvider: customerProvider,
        billPrefix: businessConfig.billPrefix,
        isInterState: isInterState,
        advanceUsed: advanceUsed,
      );
    } catch (e) {
      if (context.mounted) {
        final msg = e.toString().contains('SUBSCRIPTION_LIMIT_EXCEEDED')
            ? 'Monthly bill limit reached. Please upgrade your plan.'
            : 'Failed to save bill. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      return;
    }

    // Refresh subscription counter from server
    if (!isEdit && context.mounted) {
      context.read<SubscriptionProvider>().incrementBillCount();
    }

    // Mark serial numbers as sold
    final allSerialIds = bill.lineItems
        .expand((item) => item.serialNumberIds)
        .toList();
    if (allSerialIds.isNotEmpty && context.mounted) {
      context.read<SerialNumberProvider>().assignToBill(allSerialIds, bill.id);
    }

    if (!context.mounted) return;

    if (isEdit) {
      Navigator.popUntil(context, (route) => route.settings.name == '/home' || route.isFirst);
    } else {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/bill-done',
        (route) => route.settings.name == '/home',
        arguments: bill,
      );
    }
  }
}

// ─── UPI QR Section ───────────────────────────────────────────────────────────

class _UpiSection extends StatelessWidget {
  final String? upiId;
  final double amount;
  final String businessName;

  const _UpiSection({
    required this.upiId,
    required this.amount,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    if (upiId == null || upiId!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: AppColors.primaryLight(0.08),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Add your UPI ID in Settings to generate a payment QR code.',
                style: AppTypography.label.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    final name = Uri.encodeComponent(businessName.isNotEmpty ? businessName : 'Merchant');
    final amt = amount.toStringAsFixed(2);
    final upiUrl =
        'upi://pay?pa=$upiId&pn=$name&am=$amt&cu=INR&tn=Bill+Payment';

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: AppColors.muted.withValues(alpha: 0.2),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            children: [
              Text(
                'Scan to Pay',
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              QrImageView(
                data: upiUrl,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                upiId!,
                style: AppTypography.label.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                Formatters.currency(amount),
                style: AppTypography.currency,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Payment will be marked as fully paid after confirmation.',
          style: AppTypography.label.copyWith(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _PaymentTypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight(0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
