import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../providers/purchase_provider.dart';

class ProductPurchaseHistorySheet extends StatelessWidget {
  final String productId;
  final String productName;

  const ProductPurchaseHistorySheet({
    super.key,
    required this.productId,
    required this.productName,
  });

  static Future<void> show(
    BuildContext context, {
    required String productId,
    required String productName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<PurchaseProvider>(),
        child: ProductPurchaseHistorySheet(
          productId: productId,
          productName: productName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseProvider = context.watch<PurchaseProvider>();
    final history = purchaseProvider.getProductPurchaseHistory(productId);
    final avgCost = purchaseProvider.getAverageCostPrice(productId);
    final lastPrice = purchaseProvider.getLastPurchasePrice(productId);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppStrings.purchaseHistory} — $productName',
                    style: AppTypography.heading.copyWith(fontSize: 16),
                  ),
                  if (history.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.small),
                    Row(
                      children: [
                        _statChip(
                          AppStrings.avgCostPrice,
                          Formatters.currency(avgCost),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        if (lastPrice != null)
                          _statChip(
                            AppStrings.lastPurchasePrice,
                            Formatters.currency(lastPrice),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Text(
                        AppStrings.noPurchaseHistory,
                        style: AppTypography.label,
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.medium,
                      ),
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final item = history[index];
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
                              color: AppColors.muted.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${AppStrings.qty}: ${item.quantity}${item.unitOfMeasure != null ? ' ${item.unitOfMeasure}' : ''}',
                                      style: AppTypography.body,
                                    ),
                                    Text(
                                      '@ ${Formatters.currency(item.purchasePricePerUnit)} each',
                                      style: AppTypography.label
                                          .copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.currency(item.totalCost),
                                style: AppTypography.currency
                                    .copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _statChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLight(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Text(
        '$label: $value',
        style: AppTypography.label.copyWith(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
