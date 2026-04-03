import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/product_batch.dart';
import '../providers/product_provider.dart';
import 'app_snackbar.dart';

class AddBatchSheet extends StatefulWidget {
  final String productId;
  final ProductBatch? existingBatch;
  final void Function(ProductBatch batch)? onSaved;

  const AddBatchSheet({
    super.key,
    required this.productId,
    this.existingBatch,
    this.onSaved,
  });

  /// Provider-based mode: saves directly to ProductProvider (for existing products)
  static Future<void> show(
    BuildContext context, {
    required String productId,
    ProductBatch? existingBatch,
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
        value: context.read<ProductProvider>(),
        child: AddBatchSheet(
          productId: productId,
          existingBatch: existingBatch,
        ),
      ),
    );
  }

  /// Callback-based mode: returns batch via callback (for new products)
  static Future<void> showWithCallback(
    BuildContext context, {
    required String productId,
    ProductBatch? existingBatch,
    required void Function(ProductBatch batch) onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => AddBatchSheet(
        productId: productId,
        existingBatch: existingBatch,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<AddBatchSheet> createState() => _AddBatchSheetState();
}

class _AddBatchSheetState extends State<AddBatchSheet> {
  final _batchNumberController = TextEditingController();
  final _stockController = TextEditingController();
  DateTime? _expiryDate;

  String? _batchNumberError;
  String? _expiryError;
  String? _stockError;

  bool get _isEditing => widget.existingBatch != null;
  bool get _isCallbackMode => widget.onSaved != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final batch = widget.existingBatch!;
      _batchNumberController.text = batch.batchNumber;
      _stockController.text = '${batch.stockQuantity}';
      _expiryDate = batch.expiryDate;
    }
  }

  @override
  void dispose() {
    _batchNumberController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.medium,
        right: AppSpacing.medium,
        top: AppSpacing.medium,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            _isEditing ? AppStrings.editBatch : AppStrings.addBatch,
            style: AppTypography.heading,
          ),
          const SizedBox(height: AppSpacing.medium),

          // Batch Number
          TextField(
            controller: _batchNumberController,
            decoration: InputDecoration(
              labelText: AppStrings.batchNumber,
              hintText: AppStrings.batchNumberHint,
              errorText: _batchNumberError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            onChanged: (_) => setState(() => _batchNumberError = null),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Expiry Date
          InkWell(
            onTap: _pickExpiryDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: AppStrings.expiryDate,
                errorText: _expiryError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                suffixIcon: const Icon(Icons.calendar_today, size: 20),
              ),
              child: Text(
                _expiryDate != null
                    ? DateFormat('dd MMM yyyy').format(_expiryDate!)
                    : 'Select date',
                style: AppTypography.body.copyWith(
                  color: _expiryDate != null
                      ? AppColors.onSurface
                      : AppColors.muted,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Stock Quantity
          TextField(
            controller: _stockController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: AppStrings.stockQuantityLabel,
              errorText: _stockError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            onChanged: (_) => setState(() => _stockError = null),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: Text(
                _isEditing ? AppStrings.saveChanges : AppStrings.addBatch,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _expiryError = null;
      });
    }
  }

  void _save() {
    final batchNumber = _batchNumberController.text.trim();
    final stockStr = _stockController.text.trim();

    bool hasError = false;

    if (batchNumber.isEmpty) {
      setState(() => _batchNumberError = AppStrings.batchNumberRequired);
      hasError = true;
    }

    if (_expiryDate == null) {
      setState(() => _expiryError = AppStrings.expiryDateRequired);
      hasError = true;
    }

    final stock = int.tryParse(stockStr);
    if (stockStr.isEmpty || stock == null || stock < 0) {
      setState(() => _stockError = AppStrings.stockNegative);
      hasError = true;
    }

    if (hasError) return;

    if (_isCallbackMode) {
      // Callback mode: return batch to caller
      final batch = _isEditing
          ? widget.existingBatch!.copyWith(
              batchNumber: batchNumber,
              expiryDate: _expiryDate!,
              stockQuantity: stock!,
            )
          : ProductBatch(
              productId: widget.productId,
              batchNumber: batchNumber,
              expiryDate: _expiryDate!,
              stockQuantity: stock!,
            );
      Navigator.pop(context);
      widget.onSaved!(batch);
      return;
    }

    // Provider mode: save directly
    final provider = context.read<ProductProvider>();

    if (_isEditing) {
      final updated = widget.existingBatch!.copyWith(
        batchNumber: batchNumber,
        expiryDate: _expiryDate!,
        stockQuantity: stock!,
      );
      provider.updateBatch(widget.productId, updated);
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.batchUpdated);
    } else {
      final batch = ProductBatch(
        productId: widget.productId,
        batchNumber: batchNumber,
        expiryDate: _expiryDate!,
        stockQuantity: stock!,
      );
      provider.addBatch(widget.productId, batch);
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.batchAdded);
    }
  }
}
