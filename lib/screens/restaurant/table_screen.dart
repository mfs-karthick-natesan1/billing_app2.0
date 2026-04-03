import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';
import '../../constants/formatters.dart';
import '../../providers/business_config_provider.dart';
import '../../providers/table_order_provider.dart';
import '../../models/table_order.dart';
import '../../widgets/app_fab.dart';
import '../../widgets/app_top_bar.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>();
    final tableOrderProvider = context.watch<TableOrderProvider>();

    final count = config.tableCount;
    final labels = config.tableLabels;
    final tableLabels = List.generate(
      count,
      (i) => (labels != null && i < labels.length)
          ? labels[i]
          : 'T${i + 1}',
    );

    return Scaffold(
      appBar: const AppTopBar(title: AppStrings.tablesTitle),
      floatingActionButton: AppFab(
        heroTag: 'fab-table',
        onPressed: () {
          // Navigate to first available table
          final available = tableLabels.firstWhere(
            (label) => tableOrderProvider.getActiveOrder(label) == null,
            orElse: () => tableLabels.first,
          );
          _openTable(context, available, tableOrderProvider);
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 900
              ? 5
              : constraints.maxWidth > 600
                  ? 4
                  : 3;
          return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.medium),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.4,
          crossAxisSpacing: AppSpacing.small,
          mainAxisSpacing: AppSpacing.small,
        ),
        itemCount: tableLabels.length,
        itemBuilder: (context, index) {
          final label = tableLabels[index];
          final order = tableOrderProvider.getActiveOrder(label);
          return _TableCard(
            label: label,
            order: order,
            onTap: () => _openTable(context, label, tableOrderProvider),
          );
        },
          );
        },
      ),
    );
  }

  void _openTable(
    BuildContext context,
    String tableLabel,
    TableOrderProvider provider,
  ) {
    final existing =
        provider.getActiveOrder(tableLabel) ?? provider.createOrder(tableLabel);
    Navigator.pushNamed(
      context,
      '/take-order',
      arguments: {'tableLabel': tableLabel, 'orderId': existing.id},
    );
  }
}

class _TableCard extends StatelessWidget {
  final String label;
  final TableOrder? order;
  final VoidCallback onTap;

  const _TableCard({required this.label, this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final occupied = order != null;
    final bgColor = occupied
        ? AppColors.error.withValues(alpha: 0.08)
        : AppColors.success.withValues(alpha: 0.06);
    final borderColor = occupied
        ? AppColors.error.withValues(alpha: 0.3)
        : AppColors.success.withValues(alpha: 0.2);
    final statusColor = occupied ? AppColors.error : AppColors.success;
    final statusLabel = occupied
        ? AppStrings.tableOccupied
        : AppStrings.tableAvailable;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant,
              color: statusColor,
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              statusLabel,
              style: AppTypography.label.copyWith(
                color: statusColor,
                fontSize: 10,
              ),
            ),
            if (occupied && order!.total > 0) ...[
              const SizedBox(height: 4),
              Text(
                Formatters.currency(order!.total),
                style: AppTypography.label.copyWith(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
