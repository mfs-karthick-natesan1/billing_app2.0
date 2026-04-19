import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';

class BillTotalFooter extends StatefulWidget {
  final double subtotal;
  final double lineDiscount;
  final double discount;
  final double cgst;
  final double sgst;
  final double igst;
  final double grandTotal;
  final bool gstEnabled;
  final bool isInterState;
  final bool hasItems;
  final bool discountIsPercent;
  final double discountValue;
  final VoidCallback onProceedToPayment;
  final void Function({required bool isPercent, required double value})
  onDiscountChanged;
  final VoidCallback onClearDiscount;
  final String? buttonLabel;

  const BillTotalFooter({
    super.key,
    required this.subtotal,
    this.lineDiscount = 0,
    required this.discount,
    required this.cgst,
    required this.sgst,
    this.igst = 0,
    required this.grandTotal,
    required this.gstEnabled,
    this.isInterState = false,
    required this.hasItems,
    required this.discountIsPercent,
    required this.discountValue,
    required this.onProceedToPayment,
    required this.onDiscountChanged,
    required this.onClearDiscount,
    this.buttonLabel,
  });

  @override
  State<BillTotalFooter> createState() => _BillTotalFooterState();
}

class _BillTotalFooterState extends State<BillTotalFooter> {
  bool _showDiscountField = false;
  late bool _isPercent;
  final _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isPercent = widget.discountIsPercent;
    if (widget.discountValue > 0) {
      _showDiscountField = true;
      _discountController.text = widget.discountValue.toStringAsFixed(
        widget.discountValue == widget.discountValue.roundToDouble() ? 0 : 2,
      );
    }
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.cardRadius),
          topRight: Radius.circular(AppSpacing.cardRadius),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRow('Subtotal', Formatters.currency(widget.subtotal)),
            if (widget.lineDiscount > 0)
              _buildRow(
                'Line Discounts',
                '-${Formatters.currency(widget.lineDiscount)}',
                valueColor: AppColors.error,
              ),
            if (!_showDiscountField && widget.discount == 0)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _showDiscountField = true),
                  child: Text(
                    'Add Discount',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            if (_showDiscountField) ...[
              const SizedBox(height: AppSpacing.small),
              _buildDiscountField(),
            ],
            if (widget.discount > 0)
              _buildRow(
                'Discount',
                '-${Formatters.currency(widget.discount)}',
                valueColor: AppColors.error,
              ),
            if (widget.gstEnabled && !widget.isInterState && widget.cgst > 0)
              _buildRow('CGST', Formatters.currency(widget.cgst)),
            if (widget.gstEnabled && !widget.isInterState && widget.sgst > 0)
              _buildRow('SGST', Formatters.currency(widget.sgst)),
            if (widget.gstEnabled && widget.isInterState && widget.igst > 0)
              _buildRow('IGST', Formatters.currency(widget.igst)),
            const Divider(height: AppSpacing.medium),
            _buildRow(
              'Grand Total',
              Formatters.currency(widget.grandTotal),
              isBold: true,
            ),
            const SizedBox(height: AppSpacing.medium),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.hasItems ? widget.onProceedToPayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.hasItems
                      ? AppColors.primary
                      : AppColors.muted.withValues(alpha: 0.3),
                  foregroundColor: widget.hasItems
                      ? Colors.white
                      : AppColors.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.buttonRadius,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.buttonLabel ?? 'Proceed to Payment',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.hasItems ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small / 2),
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

  Widget _buildDiscountField() {
    return Row(
      children: [
        // Toggle % / Rs.
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ToggleChip(
                label: '%',
                selected: _isPercent,
                onTap: () {
                  setState(() => _isPercent = true);
                  _applyDiscount();
                },
              ),
              _ToggleChip(
                label: 'Rs.',
                selected: !_isPercent,
                onTap: () {
                  setState(() => _isPercent = false);
                  _applyDiscount();
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: SizedBox(
            height: 40,
            child: TextField(
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) => _applyDiscount(),
              textAlign: TextAlign.right,
              style: AppTypography.body,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(
                    color: AppColors.muted.withValues(alpha: 0.3),
                  ),
                ),
                hintText: '0',
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, size: 20, color: AppColors.muted),
          onPressed: () {
            _discountController.clear();
            setState(() => _showDiscountField = false);
            widget.onClearDiscount();
          },
        ),
      ],
    );
  }

  void _applyDiscount() {
    final value = double.tryParse(_discountController.text) ?? 0;
    widget.onDiscountChanged(isPercent: _isPercent, value: value);
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: selected ? AppColors.primary : AppColors.muted,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
