import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/line_item.dart';
import '../models/serial_number.dart';
import 'number_stepper.dart';

class LineItemRow extends StatelessWidget {
  final LineItem item;
  final ValueChanged<double> onQuantityChanged;
  final VoidCallback onDelete;
  final ValueChanged<double>? onDiscountChanged;
  final List<SerialNumber>? availableSerialNumbers;
  final ValueChanged<List<String>>? onSerialNumberChanged;

  const LineItemRow({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onDelete,
    this.onDiscountChanged,
    this.availableSerialNumbers,
    this.onSerialNumberChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uom = item.product.displayUom;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Row 1: Name + Delete
          Row(
            children: [
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
                    if (item.product.isService &&
                        item.product.durationMinutes != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${item.product.durationMinutes} min',
                        style: AppTypography.label.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    if (item.batch != null) ...[
                      const SizedBox(height: 2),
                      _buildBatchInfo(),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          // Row 2: Price + Stepper + Subtotal
          Row(
            children: [
              Expanded(
                child: Text(
                  '${Formatters.currency(item.product.sellingPrice)}/$uom',
                  style: AppTypography.label,
                ),
              ),
              NumberStepper(
                value: item.quantity,
                minValue: item.product.minQuantity,
                step: item.product.quantityStep,
                onChanged: onQuantityChanged,
              ),
              Expanded(
                child: Text(
                  Formatters.currency(item.discountedSubtotal),
                  style: AppTypography.currency,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          // Row 3: Serial number dropdowns (if tracked)
          if (item.product.trackSerialNumbers &&
              availableSerialNumbers != null) ...[
            const SizedBox(height: 4),
            ...List.generate(item.quantity.toInt(), (slotIndex) {
              final selected = slotIndex < item.serialNumberIds.length
                  ? item.serialNumberIds[slotIndex]
                  : null;
              // Exclude serial numbers chosen in other slots
              final otherSelected = <String>{
                for (int i = 0; i < item.serialNumberIds.length; i++)
                  if (i != slotIndex) item.serialNumberIds[i],
              };
              final options = availableSerialNumbers!
                  .where((sn) => !otherSelected.contains(sn.id))
                  .toList();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      selected != null
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 14,
                      color: selected != null
                          ? AppColors.primary
                          : AppColors.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selected,
                        hint: Text(
                          'Select S/N${item.quantity > 1 ? ' #${slotIndex + 1}' : ''}',
                          style: AppTypography.label.copyWith(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                        ),
                        isExpanded: true,
                        isDense: true,
                        underline: Container(
                          height: 1,
                          color: AppColors.muted.withValues(alpha: 0.3),
                        ),
                        items: options.isEmpty && selected == null
                            ? [
                                DropdownMenuItem<String>(
                                  enabled: false,
                                  value: '__none__',
                                  child: Text(
                                    'No S/N in stock — add via Purchases',
                                    style: AppTypography.label.copyWith(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ]
                            : [
                                if (selected != null)
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text(
                                      'Clear',
                                      style: AppTypography.label.copyWith(
                                        fontSize: 11,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ...options.map(
                                  (sn) => DropdownMenuItem<String>(
                                    value: sn.id,
                                    child: Text(
                                      sn.number,
                                      style: AppTypography.label
                                          .copyWith(fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                        onChanged: (newId) {
                          final updatedIds = List<String>.from(
                            item.serialNumberIds,
                          );
                          // Grow list to fit this slot
                          while (updatedIds.length <= slotIndex) {
                            updatedIds.add('');
                          }
                          if (newId == null) {
                            updatedIds.removeAt(slotIndex);
                          } else {
                            updatedIds[slotIndex] = newId;
                          }
                          // Remove empty placeholders
                          updatedIds.removeWhere((id) => id.isEmpty);
                          onSerialNumberChanged?.call(updatedIds);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // Row 4: Line discount (if any)
          if (item.discountPercent > 0 || onDiscountChanged != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  if (item.discountPercent > 0)
                    Text(
                      '-${item.discountPercent.toStringAsFixed(item.discountPercent == item.discountPercent.roundToDouble() ? 0 : 1)}% (${Formatters.currency(item.lineDiscountAmount)})',
                      style: AppTypography.label.copyWith(
                        color: AppColors.error,
                        fontSize: 11,
                      ),
                    ),
                  const Spacer(),
                  if (onDiscountChanged != null)
                    InkWell(
                      onTap: () => _showDiscountEditor(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          item.discountPercent > 0
                              ? 'Edit Discount'
                              : 'Add Discount',
                          style: AppTypography.label.copyWith(
                            color: AppColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDiscountEditor(BuildContext context) {
    final controller = TextEditingController(
      text: item.discountPercent > 0
          ? item.discountPercent.toStringAsFixed(
              item.discountPercent == item.discountPercent.roundToDouble()
                  ? 0
                  : 1,
            )
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Line Discount %'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            hintText: '0',
            suffixText: '%',
          ),
          onSubmitted: (_) {
            final value = double.tryParse(controller.text) ?? 0;
            onDiscountChanged!(value.clamp(0, 100));
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              onDiscountChanged!(0);
              Navigator.pop(ctx);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text) ?? 0;
              onDiscountChanged!(value.clamp(0, 100));
              Navigator.pop(ctx);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchInfo() {
    final batch = item.batch!;
    final expiryStr = DateFormat('MMM yyyy').format(batch.expiryDate);
    final isExpiringSoon = batch.isExpiringSoon;
    final color = isExpiringSoon ? AppColors.error : AppColors.muted;

    return Text(
      'Batch: ${batch.batchNumber} | Exp: $expiryStr',
      style: AppTypography.label.copyWith(fontSize: 11, color: color),
    );
  }
}
