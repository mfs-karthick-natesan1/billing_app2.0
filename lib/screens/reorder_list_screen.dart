import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/uom_constants.dart';
import '../models/product.dart';
import '../providers/business_config_provider.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';

class ReorderListScreen extends StatefulWidget {
  const ReorderListScreen({super.key});

  @override
  State<ReorderListScreen> createState() => _ReorderListScreenState();
}

class _ReorderListScreenState extends State<ReorderListScreen> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final supplierProvider = context.watch<SupplierProvider>();
    final items = productProvider.productsNeedingReorder;

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.reorderRequired,
        showBack: true,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: Icon(
                _selectedIds.length == items.length
                    ? Icons.deselect
                    : Icons.select_all,
                color: AppColors.onSurface,
              ),
              onPressed: () {
                setState(() {
                  if (_selectedIds.length == items.length) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds
                      ..clear()
                      ..addAll(items.map((p) => p.id));
                  }
                });
              },
            ),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: AppStrings.noReorderItems,
              description: AppStrings.noReorderItemsDesc,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.small),
                    itemBuilder: (context, index) {
                      final product = items[index];
                      final isSelected = _selectedIds.contains(product.id);
                      return _buildReorderCard(
                        product,
                        supplierProvider,
                        isSelected,
                      );
                    },
                  ),
                ),
                if (_selectedIds.isNotEmpty) _buildBottomActions(items, supplierProvider),
              ],
            ),
    );
  }

  Widget _buildReorderCard(
    Product product,
    SupplierProvider supplierProvider,
    bool isSelected,
  ) {
    final stockDisplay = UomConstants.display(
      product.displayUom,
      product.stockQuantity.toDouble(),
    );
    final reorderLevelDisplay = product.reorderLevel != null
        ? UomConstants.display(
            product.displayUom,
            product.reorderLevel!,
          )
        : '-';
    final reorderQtyDisplay = product.reorderQuantity != null
        ? UomConstants.display(
            product.displayUom,
            product.reorderQuantity!,
          )
        : '-';
    final supplierName = product.preferredSupplierId != null
        ? supplierProvider
                  .getSupplierById(product.preferredSupplierId!)
                  ?.name ??
              '-'
        : '-';

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedIds.remove(product.id);
          } else {
            _selectedIds.add(product.id);
          }
        });
      },
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.muted.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(product.id);
                  } else {
                    _selectedIds.add(product.id);
                  }
                });
              },
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppSpacing.small),
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
                      _buildInfoChip(
                        'Stock: $stockDisplay',
                        product.isOutOfStock
                            ? AppColors.error
                            : AppColors.error.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      _buildInfoChip(
                        'Level: $reorderLevelDisplay',
                        AppColors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Order: $reorderQtyDisplay',
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (supplierName != '-') ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '• $supplierName',
                            style: AppTypography.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTypography.label.copyWith(fontSize: 11, color: color),
      ),
    );
  }

  Widget _buildBottomActions(
    List<Product> allItems,
    SupplierProvider supplierProvider,
  ) {
    final selectedProducts =
        allItems.where((p) => _selectedIds.contains(p.id)).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.muted.withValues(alpha: 0.15)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Text(
              '${_selectedIds.length} selected',
              style: AppTypography.label,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () =>
                  _generateMessage(selectedProducts, supplierProvider),
              icon: const Icon(Icons.message, size: 18),
              label: const Text('Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            ElevatedButton.icon(
              onPressed: () =>
                  _createPurchase(selectedProducts),
              icon: const Icon(Icons.shopping_cart, size: 18),
              label: const Text('Purchase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateMessage(
    List<Product> products,
    SupplierProvider supplierProvider,
  ) {
    final businessName =
        context.read<BusinessConfigProvider>().businessName;
    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

    final buffer = StringBuffer();
    buffer.writeln('*${AppStrings.stockReorderRequest}*');
    buffer.writeln('$businessName — $dateStr');
    buffer.writeln('─────────────────');
    for (final p in products) {
      final qty = p.reorderQuantity ?? 0;
      final uom = p.displayUom;
      final display = UomConstants.display(uom, qty);
      buffer.writeln('• ${p.name}: $display');
    }
    buffer.writeln('─────────────────');
    buffer.writeln(AppStrings.pleaseConfirmAvailability);

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    AppSnackbar.success(context, AppStrings.messageCopied);
  }

  void _createPurchase(List<Product> products) {
    Navigator.pushNamed(
      context,
      '/purchases',
      arguments: products,
    );
  }
}
