import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/table_order.dart';

class KotWidget extends StatelessWidget {
  final TableOrder order;

  const KotWidget({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // KOT header
              Container(
                width: double.infinity,
                color: AppColors.onSurface,
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  children: [
                    Text(
                      AppStrings.kitchenOrderTicket,
                      style: AppTypography.heading.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.tableLabel}: ${order.tableLabel}',
                      style: AppTypography.body.copyWith(color: Colors.white70),
                    ),
                    Text(
                      DateFormat('dd MMM yyyy HH:mm').format(order.createdAt),
                      style: AppTypography.label.copyWith(color: Colors.white54),
                    ),
                  ],
                ),
              ),
              // Items
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  itemCount: order.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    final qty = item.quantity % 1 == 0
                        ? item.quantity.toInt().toString()
                        : item.quantity.toStringAsFixed(1);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              qty,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.small),
                          Expanded(
                            child: Text(
                              item.product.name,
                              style: AppTypography.body
                                  .copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Close button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
