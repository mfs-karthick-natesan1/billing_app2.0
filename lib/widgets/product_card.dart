import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../constants/uom_constants.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showBatchInfo;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onLongPress,
    this.showBatchInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final stockDesc = product.isService
        ? 'service'
        : product.isOutOfStock
            ? 'out of stock'
            : product.isLowStock
                ? 'low stock: ${product.stockQuantity}'
                : 'stock: ${product.stockQuantity}';
    return Semantics(
      label: '${product.name}, ${Formatters.currency(product.sellingPrice)}, $stockDesc',
      button: true,
      child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.muted.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                          ),
                          child: Text(
                            product.category!,
                            style: AppTypography.label.copyWith(fontSize: 12),
                          ),
                        ),
                      if (product.category != null)
                        const SizedBox(width: AppSpacing.small),
                      if (product.isService)
                        _buildServiceIndicator()
                      else
                        _buildStockIndicator(),
                    ],
                  ),
                  if (product.costPrice > 0) ...[
                    const SizedBox(height: 4),
                    _buildProfitRow(),
                  ],
                  if (showBatchInfo && product.batches.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildBatchInfo(),
                  ],
                ],
              ),
            ),
            Text(
              Formatters.currency(product.sellingPrice),
              style: AppTypography.currency,
            ),
            const SizedBox(width: AppSpacing.small),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildServiceIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.content_cut, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          product.durationMinutes != null
              ? '${product.durationMinutes} min'
              : 'Service',
          style: AppTypography.label.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildStockIndicator() {
    final stockDisplay = UomConstants.display(
      product.displayUom,
      product.stockQuantity.toDouble(),
    );
    if (product.isOutOfStock) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block, size: 13, color: AppColors.error),
          const SizedBox(width: 3),
          Text(
            'Out of Stock',
            style: AppTypography.label.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }
    if (product.isLowStock) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.warning),
          const SizedBox(width: 3),
          Text(
            'Low: $stockDisplay',
            style: AppTypography.label.copyWith(color: AppColors.warning),
          ),
        ],
      );
    }
    return Text('Stock: $stockDisplay', style: AppTypography.label);
  }

  Widget _buildProfitRow() {
    final profit = product.profitAmount;
    final margin = product.profitMarginPercent;
    final color = profit >= 0 ? AppColors.success : AppColors.error;
    return Row(
      children: [
        Icon(
          profit >= 0 ? Icons.trending_up : Icons.trending_down,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          'Profit: ${Formatters.currency(profit)}  (${margin.toStringAsFixed(1)}%)',
          style: AppTypography.label.copyWith(color: color, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBatchInfo() {
    final batchCount = product.batches.length;
    final nearest = product.nearestExpiryBatch;

    final parts = <InlineSpan>[
      TextSpan(
        text: '$batchCount batch${batchCount > 1 ? 'es' : ''}',
        style: AppTypography.label.copyWith(fontSize: 11),
      ),
    ];

    if (nearest != null) {
      final expiryStr = DateFormat('MMM yyyy').format(nearest.expiryDate);
      final isExpiringSoon = nearest.isExpiringSoon;
      parts.add(
        TextSpan(
          text: ' | Nearest exp: $expiryStr',
          style: AppTypography.label.copyWith(
            fontSize: 11,
            color: isExpiringSoon ? AppColors.error : AppColors.muted,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: parts));
  }
}
