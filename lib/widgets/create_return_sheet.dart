import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/bill.dart';
import '../models/return_line_item.dart';
import '../models/sales_return.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../providers/return_provider.dart';
import 'app_snackbar.dart';

class CreateReturnSheet extends StatefulWidget {
  final Bill bill;

  const CreateReturnSheet({super.key, required this.bill});

  static Future<SalesReturn?> show(BuildContext context, Bill bill) {
    return showModalBottomSheet<SalesReturn>(
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
            value: context.read<ReturnProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<ProductProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<CustomerProvider>(),
          ),
        ],
        child: CreateReturnSheet(bill: bill),
      ),
    );
  }

  @override
  State<CreateReturnSheet> createState() => _CreateReturnSheetState();
}

class _CreateReturnSheetState extends State<CreateReturnSheet> {
  final Map<int, bool> _selected = {};
  final Map<int, TextEditingController> _qtyControllers = {};
  final _notesController = TextEditingController();
  RefundMode _refundMode = RefundMode.cash;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.bill.lineItems.length; i++) {
      _selected[i] = false;
      _qtyControllers[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  double get _totalRefund {
    var total = 0.0;
    for (var i = 0; i < widget.bill.lineItems.length; i++) {
      if (_selected[i] != true) continue;
      final item = widget.bill.lineItems[i];
      final qty = double.tryParse(_qtyControllers[i]?.text ?? '') ?? 0;
      total += qty * item.product.sellingPrice;
    }
    return total;
  }

  bool get _hasSelection => _selected.values.any((v) => v);

  @override
  Widget build(BuildContext context) {
    final returnProvider = context.read<ReturnProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Row(
                  children: [
                    Text(AppStrings.returnItems, style: AppTypography.heading),
                    const Spacer(),
                    Text(
                      widget.bill.billNumber,
                      style: AppTypography.label,
                    ),
                  ],
                ),
              ),
              // Items list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  children: [
                    ...List.generate(widget.bill.lineItems.length, (i) {
                      final item = widget.bill.lineItems[i];
                      final maxReturnable = item.quantity -
                          returnProvider.getReturnedQuantity(
                            widget.bill.id,
                            item.product.id,
                          );
                      if (maxReturnable <= 0) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          border: Border.all(
                            color: _selected[i] == true
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : AppColors.muted.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _selected[i] ?? false,
                              onChanged: (v) {
                                setState(() {
                                  _selected[i] = v ?? false;
                                  if (v == true &&
                                      (_qtyControllers[i]?.text.isEmpty ??
                                          true)) {
                                    _qtyControllers[i]?.text =
                                        Formatters.qty(maxReturnable);
                                  }
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    style: AppTypography.body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${Formatters.currency(item.product.sellingPrice)} × ${Formatters.qty(item.quantity)} | ${AppStrings.maxQty}: ${Formatters.qty(maxReturnable)}',
                                    style: AppTypography.label
                                        .copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (_selected[i] == true)
                              SizedBox(
                                width: 64,
                                height: 36,
                                child: TextField(
                                  controller: _qtyControllers[i],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body
                                      .copyWith(fontSize: 14),
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.medium),
                    // Refund mode
                    Text(AppStrings.refundMode, style: AppTypography.label),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.small,
                      children: [
                        _RefundModeChip(
                          label: AppStrings.refundCash,
                          icon: Icons.money,
                          selected: _refundMode == RefundMode.cash,
                          onTap: () => setState(
                            () => _refundMode = RefundMode.cash,
                          ),
                        ),
                        _RefundModeChip(
                          label: AppStrings.refundCredit,
                          icon: Icons.account_balance_wallet,
                          selected:
                              _refundMode == RefundMode.creditToAccount,
                          onTap: () => setState(
                            () => _refundMode = RefundMode.creditToAccount,
                          ),
                        ),
                        _RefundModeChip(
                          label: AppStrings.refundExchange,
                          icon: Icons.swap_horiz,
                          selected: _refundMode == RefundMode.exchange,
                          onTap: () => setState(
                            () => _refundMode = RefundMode.exchange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: AppStrings.returnReason,
                        hintText: AppStrings.returnReasonHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                  ],
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.totalRefund,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Formatters.currency(_totalRefund),
                            style: AppTypography.currency.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.small),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              _hasSelection ? () => _processReturn() : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasSelection
                                ? AppColors.error
                                : AppColors.muted.withValues(alpha: 0.3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                            ),
                          ),
                          child: const Text(AppStrings.processReturn),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _processReturn() {
    final returnProvider = context.read<ReturnProvider>();
    final productProvider = context.read<ProductProvider>();
    final customerProvider = context.read<CustomerProvider>();

    // Build return line items
    final returnItems = <ReturnLineItem>[];
    for (var i = 0; i < widget.bill.lineItems.length; i++) {
      if (_selected[i] != true) continue;
      final item = widget.bill.lineItems[i];
      final qty = double.tryParse(_qtyControllers[i]?.text ?? '') ?? 0;
      if (qty <= 0) continue;

      final maxReturnable = item.quantity -
          returnProvider.getReturnedQuantity(
            widget.bill.id,
            item.product.id,
          );
      if (qty > maxReturnable) {
        AppSnackbar.error(context, AppStrings.qtyExceedsMax);
        return;
      }

      returnItems.add(ReturnLineItem(
        productId: item.product.id,
        productName: item.product.name,
        quantityReturned: qty,
        pricePerUnit: item.product.sellingPrice,
        batchId: item.batch?.id,
        batchNumber: item.batch?.batchNumber,
      ));
    }

    if (returnItems.isEmpty) {
      AppSnackbar.error(context, AppStrings.noItemsSelected);
      return;
    }

    final returnNumber = returnProvider.generateReturnNumber();
    final notes = _notesController.text.trim();

    final salesReturn = SalesReturn(
      originalBillId: widget.bill.id,
      returnNumber: returnNumber,
      customerId: widget.bill.customer?.id,
      customerName: widget.bill.customer?.name,
      items: returnItems,
      refundMode: _refundMode,
      notes: notes.isNotEmpty ? notes : null,
    );

    // Save the return
    returnProvider.addReturn(salesReturn);

    // Increment stock for returned items
    for (final item in returnItems) {
      if (item.productId.isNotEmpty) {
        productProvider.incrementStock(
          item.productId,
          item.quantityReturned,
        );
      }
    }

    // Handle refund mode
    if (_refundMode == RefundMode.creditToAccount &&
        widget.bill.customer != null) {
      // Reduce outstanding balance (negative credit = refund to account)
      customerProvider.recordPayment(
        widget.bill.customer!.id,
        salesReturn.totalRefundAmount,
      );
    }

    Navigator.pop(context, salesReturn);
    AppSnackbar.success(context, AppStrings.returnCreated);
  }
}

class _RefundModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RefundModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryLight(0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primary : AppColors.muted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: selected ? AppColors.primary : AppColors.muted,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
