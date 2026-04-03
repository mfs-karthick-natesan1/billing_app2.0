import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../constants/uom_constants.dart';
import '../models/product.dart';
import '../models/stock_adjustment.dart';
import '../providers/product_provider.dart';
import 'app_snackbar.dart';

class StockAdjustmentSheet extends StatefulWidget {
  final Product product;

  const StockAdjustmentSheet({super.key, required this.product});

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ProductProvider>(),
        child: StockAdjustmentSheet(product: product),
      ),
    );
  }

  @override
  State<StockAdjustmentSheet> createState() => _StockAdjustmentSheetState();
}

class _StockAdjustmentSheetState extends State<StockAdjustmentSheet> {
  final _newStockController = TextEditingController();
  final _notesController = TextEditingController();
  StockAdjustmentReason _reason = StockAdjustmentReason.countCorrection;
  String? _stockError;

  int get _currentStock => widget.product.stockQuantity;

  double get _newStock =>
      double.tryParse(_newStockController.text) ?? _currentStock.toDouble();

  double get _delta => _newStock - _currentStock;

  @override
  void initState() {
    super.initState();
    _newStockController.text = '$_currentStock';
  }

  @override
  void dispose() {
    _newStockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final adjustments = productProvider.getAdjustments(widget.product.id);
    final uom = widget.product.displayUom;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Drag handle
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.adjustStock,
                        style: AppTypography.heading,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  children: [
                    // Product name + current stock
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.small),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight(0.06),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.product.name,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${AppStrings.currentStock}: ${UomConstants.display(uom, _currentStock.toDouble())}',
                                  style: AppTypography.label,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // New stock field
                    Text(
                      AppStrings.newStockLabel,
                      style: AppTypography.label.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _newStockController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      style: AppTypography.currency.copyWith(fontSize: 24),
                      decoration: InputDecoration(
                        suffixText: uom,
                        errorText: _stockError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (_) => setState(() => _stockError = null),
                    ),
                    const SizedBox(height: AppSpacing.small),

                    // Delta display
                    _buildDeltaDisplay(),
                    const SizedBox(height: AppSpacing.medium),

                    // Reason chips
                    Text(
                      AppStrings.adjustmentReasonLabel,
                      style: AppTypography.label.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: StockAdjustmentReason.values.map((r) {
                        final selected = _reason == r;
                        return InkWell(
                          onTap: () => setState(() => _reason = r),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primaryLight(0.10)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.buttonRadius,
                              ),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.muted.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              r.label,
                              style: AppTypography.label.copyWith(
                                fontSize: 12,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Notes
                    Text(
                      AppStrings.supplierNotesLabel,
                      style: AppTypography.label.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: AppStrings.optionalNotesHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.large),

                    // Adjustment history
                    if (adjustments.isNotEmpty) ...[
                      Text(
                        AppStrings.adjustmentHistory,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      ...adjustments.take(5).map(_buildHistoryCard),
                    ],
                    const SizedBox(height: AppSpacing.medium),
                  ],
                ),
              ),

              // Save button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                        ),
                      ),
                      child: Text(
                        AppStrings.saveAdjustment,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _buildDeltaDisplay() {
    final delta = _delta;
    if (delta == 0) {
      return Text(
        AppStrings.noChange,
        style: AppTypography.label.copyWith(color: AppColors.muted),
      );
    }
    final isPositive = delta > 0;
    final uom = widget.product.displayUom;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isPositive ? AppColors.success : AppColors.error)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      ),
      child: Text(
        '${isPositive ? '+' : ''}${Formatters.qty(delta)} $uom ${isPositive ? AppStrings.willBeAdded : AppStrings.willBeRemoved}',
        style: AppTypography.label.copyWith(
          color: isPositive ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHistoryCard(StockAdjustment adj) {
    final delta = adj.adjustmentQty;
    final isPositive = delta >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.small),
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
                  adj.reason.label,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(adj.date),
                  style: AppTypography.label.copyWith(fontSize: 11),
                ),
                if (adj.notes != null && adj.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    adj.notes!,
                    style: AppTypography.label.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${Formatters.qty(delta)}',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              Text(
                '${Formatters.qty(adj.previousStock)} → ${Formatters.qty(adj.newStock)}',
                style: AppTypography.label.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _save() {
    final newStock = double.tryParse(_newStockController.text);
    if (newStock == null || newStock < 0) {
      setState(() => _stockError = AppStrings.stockNegative);
      return;
    }

    if (newStock == _currentStock.toDouble()) {
      Navigator.pop(context);
      return;
    }

    final notes = _notesController.text.trim();

    final adjustment = StockAdjustment(
      productId: widget.product.id,
      productName: widget.product.name,
      previousStock: _currentStock.toDouble(),
      newStock: newStock,
      reason: _reason,
      notes: notes.isNotEmpty ? notes : null,
    );

    context.read<ProductProvider>().adjustStock(adjustment);

    Navigator.pop(context);
    AppSnackbar.success(context, AppStrings.stockAdjusted);
  }
}
