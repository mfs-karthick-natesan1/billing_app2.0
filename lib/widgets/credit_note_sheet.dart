import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/sales_return.dart';

class CreditNoteSheet extends StatelessWidget {
  final SalesReturn salesReturn;

  const CreditNoteSheet({super.key, required this.salesReturn});

  static void show(BuildContext context, SalesReturn salesReturn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => CreditNoteSheet(salesReturn: salesReturn),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
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
                  Icon(Icons.receipt, color: AppColors.error, size: 24),
                  const SizedBox(width: AppSpacing.small),
                  Text(AppStrings.creditNoteTitle, style: AppTypography.heading),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              // Return info
              _InfoRow(
                label: AppStrings.returnNumber,
                value: salesReturn.returnNumber,
              ),
              _InfoRow(
                label: 'Date',
                value:
                    '${Formatters.date(salesReturn.date)}  ${Formatters.time(salesReturn.date)}',
              ),
              _InfoRow(
                label: AppStrings.originalBill,
                value: salesReturn.originalBillId.length > 8
                    ? salesReturn.originalBillId.substring(0, 8)
                    : salesReturn.originalBillId,
              ),
              if (salesReturn.customerName != null)
                _InfoRow(
                  label: AppStrings.customer,
                  value: salesReturn.customerName!,
                ),
              _InfoRow(
                label: AppStrings.refundMode,
                value: _refundModeLabel(salesReturn.refundMode),
              ),
              if (salesReturn.notes != null && salesReturn.notes!.isNotEmpty)
                _InfoRow(
                  label: AppStrings.returnReason,
                  value: salesReturn.notes!,
                ),
              const Divider(height: AppSpacing.large),
              // Items header
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
              // Items
              ...salesReturn.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.productName,
                          style: AppTypography.body.copyWith(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          Formatters.qty(item.quantityReturned),
                          style: AppTypography.body.copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          Formatters.currency(item.pricePerUnit),
                          style: AppTypography.body.copyWith(fontSize: 13),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          Formatters.currency(item.refundAmount),
                          style: AppTypography.body.copyWith(fontSize: 13),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: AppSpacing.large),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.totalRefund,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    Formatters.currency(salesReturn.totalRefundAmount),
                    style: AppTypography.currency.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _refundModeLabel(RefundMode mode) {
    switch (mode) {
      case RefundMode.cash:
        return AppStrings.refundCash;
      case RefundMode.creditToAccount:
        return AppStrings.refundCredit;
      case RefundMode.exchange:
        return AppStrings.refundExchange;
    }
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
