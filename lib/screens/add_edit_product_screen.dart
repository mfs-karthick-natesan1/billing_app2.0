import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/categories.dart';
import '../constants/formatters.dart';
import '../constants/gst_slabs.dart';
import '../constants/uom_constants.dart';
import '../constants/units.dart';
import '../models/product.dart';
import '../models/product_batch.dart';
import '../providers/business_config_provider.dart';
import '../providers/product_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/supplier_provider.dart';
import '../widgets/add_batch_sheet.dart';
import '../widgets/app_dropdown.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_input.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/confirm_dialog.dart';

class AddEditProductScreen extends StatefulWidget {
  const AddEditProductScreen({super.key});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  late final bool _isEditing;
  Product? _existingProduct;
  bool _initialized = false;

  // Pre-generated ID for new products (so batches can reference it)
  late final String _newProductId;

  // Local pending batches for new products
  final List<ProductBatch> _pendingBatches = [];

  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _durationController = TextEditingController();
  final _customUomController = TextEditingController();
  final _minQtyController = TextEditingController();
  final _stepQtyController = TextEditingController();
  final _hsnCodeController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _reorderQtyController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _defaultDiscountController = TextEditingController();
  String? _imageUrl;
  String? _preferredSupplierId;
  String? _selectedCategory;
  String _selectedUnit = Units.defaultUnit;
  int _selectedGstSlab = GstSlabs.defaultSlab;
  double _selectedGstRate = 0.0;
  bool _gstInclusivePrice = false;
  bool _isService = false;
  bool _trackSerialNumbers = false;

  String? _nameError;
  String? _barcodeError;
  String? _priceError;
  String? _stockError;
  String? _customUomError;
  String? _hsnCodeError;

  bool get _hasChanges {
    if (!_isEditing) {
      return _nameController.text.isNotEmpty ||
          _barcodeController.text.isNotEmpty ||
          _priceController.text.isNotEmpty ||
          _stockController.text != '0' ||
          _pendingBatches.isNotEmpty;
    }
    final p = _existingProduct!;
    final barcode = _normalizedBarcode(_barcodeController.text);
    return _nameController.text.trim() != p.name ||
        barcode != p.barcode ||
        (double.tryParse(_priceController.text) ?? 0) != p.sellingPrice ||
        (int.tryParse(_stockController.text) ?? 0) != p.stockQuantity ||
        _selectedCategory != p.category ||
        _selectedUnit != p.unit ||
        _selectedGstSlab != p.gstSlabPercent;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _existingProduct = ModalRoute.of(context)?.settings.arguments as Product?;
      _isEditing = _existingProduct != null;
      _newProductId = const Uuid().v4();

      final isSalon = context.read<BusinessConfigProvider>().isSalon;

      if (_isEditing) {
        final p = _existingProduct!;
        _nameController.text = p.name;
        _barcodeController.text = p.barcode ?? '';
        _priceController.text = p.sellingPrice.toStringAsFixed(
          p.sellingPrice == p.sellingPrice.roundToDouble() ? 0 : 2,
        );
        _stockController.text = '${p.stockQuantity}';
        _selectedCategory = p.category;
        _selectedUnit = p.unit;
        _customUomController.text = p.customUomLabel ?? '';
        _minQtyController.text = UomConstants.formatQty(p.minQuantity);
        _stepQtyController.text = UomConstants.formatQty(p.quantityStep);
        _selectedGstSlab = p.gstSlabPercent;
        _hsnCodeController.text = p.hsnCode ?? '';
        _selectedGstRate = p.gstRate;
        _gstInclusivePrice = p.gstInclusivePrice;
        _isService = p.isService;
        _trackSerialNumbers = p.trackSerialNumbers;
        if (p.durationMinutes != null) {
          _durationController.text = '${p.durationMinutes}';
        }
        if (p.reorderLevel != null) {
          _reorderLevelController.text = Formatters.qty(p.reorderLevel!);
        }
        if (p.reorderQuantity != null) {
          _reorderQtyController.text = Formatters.qty(p.reorderQuantity!);
        }
        _preferredSupplierId = p.preferredSupplierId;
        _imageUrl = p.imageUrl;
        if (p.costPrice > 0) {
          _costPriceController.text = p.costPrice.toStringAsFixed(
            p.costPrice == p.costPrice.roundToDouble() ? 0 : 2,
          );
        }
        if (p.defaultDiscountPercent > 0) {
          _defaultDiscountController.text = p.defaultDiscountPercent
              .toStringAsFixed(
                p.defaultDiscountPercent ==
                        p.defaultDiscountPercent.roundToDouble()
                    ? 0
                    : 1,
              );
        }
      } else {
        _stockController.text = '0';
        _minQtyController.text = '1';
        _stepQtyController.text = '1';
        _isService = isSalon;
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _durationController.dispose();
    _customUomController.dispose();
    _minQtyController.dispose();
    _stepQtyController.dispose();
    _hsnCodeController.dispose();
    _reorderLevelController.dispose();
    _reorderQtyController.dispose();
    _costPriceController.dispose();
    _defaultDiscountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configProvider = context.watch<BusinessConfigProvider>();
    final isPharmacy = configProvider.isPharmacy;
    final isSalon = configProvider.isSalon;

    // For pharmacy editing, refresh batches from provider
    Product? currentProduct;
    if (_isEditing && isPharmacy) {
      currentProduct = context.watch<ProductProvider>().findById(
        _existingProduct!.id,
      );
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await ConfirmDialog.show(
          context,
          title: AppStrings.discardChanges,
          confirmLabel: AppStrings.discardAction,
          cancelLabel: AppStrings.keepEditing,
          isDestructive: true,
        );
        if (discard && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: _isEditing ? AppStrings.editProduct : AppStrings.addProduct,
          showBack: true,
          actions: _isEditing
              ? [
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: AppStrings.deleteProduct,
                    onPressed: _deleteProduct,
                  ),
                ]
              : null,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Service toggle for salon business type
              if (isSalon) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.serviceToggleLabel,
                      style: AppTypography.body,
                    ),
                    Switch(
                      value: _isService,
                      onChanged: (val) => setState(() => _isService = val),
                      activeTrackColor: AppColors.primary,
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              AppTextInput(
                label: AppStrings.productNameLabel,
                hint: AppStrings.productNameHint,
                required: true,
                controller: _nameController,
                errorText: _nameError,
                maxLength: 150,
                onChanged: (_) => setState(() => _nameError = null),
              ),
              const SizedBox(height: AppSpacing.medium),
              // Product image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: AppColors.muted.withValues(alpha: 0.2),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            _imageUrl!.startsWith('http')
                                ? Image.network(_imageUrl!, fit: BoxFit.cover)
                                : Image.file(File(_imageUrl!), fit: BoxFit.cover),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageUrl = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: AppColors.muted,
                              size: 36,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: AppTypography.label.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              AppTextInput(
                label: AppStrings.barcodeLabel,
                hint: AppStrings.barcodeHint,
                controller: _barcodeController,
                errorText: _barcodeError,
                maxLength: 64,
                onChanged: (_) => setState(() => _barcodeError = null),
              ),
              const SizedBox(height: AppSpacing.medium),
              AppTextInput(
                label: _isService
                    ? AppStrings.serviceFee
                    : AppStrings.sellingPriceLabel,
                required: true,
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefix: 'Rs. ',
                errorText: _priceError,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (_) => setState(() => _priceError = null),
              ),
              const SizedBox(height: AppSpacing.medium),
              // Cost price (purchase / actual price) for profit calculation (purchase / actual price) for profit calculation
              AppTextInput(
                label: 'Cost Price (Purchase Price)',
                hint: '0.00',
                controller: _costPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefix: 'Rs. ',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (_) => setState(() {}),
              ),
              // Live profit preview
              if (_costPriceController.text.isNotEmpty ||
                  _priceController.text.isNotEmpty) ...[
                const SizedBox(height: 6),
                _ProfitPreview(
                  costPrice:
                      double.tryParse(_costPriceController.text) ?? 0,
                  sellingPrice:
                      double.tryParse(_priceController.text) ?? 0,
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              if (_isService) ...[
                AppTextInput(
                  label: AppStrings.durationLabel,
                  hint: AppStrings.durationHint,
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              if (!isPharmacy && !_isService) ...[
                AppTextInput(
                  label: AppStrings.stockQuantityLabel,
                  required: true,
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  errorText: _stockError,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _stockError = null),
                  suffix: _selectedUnit != 'custom'
                      ? _selectedUnit
                      : (_customUomController.text.isNotEmpty
                          ? _customUomController.text
                          : null),
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              AppDropdown<String>(
                label: AppStrings.categoryLabel,
                hint: AppStrings.selectCategory,
                value: _selectedCategory,
                items: Categories.forBusinessTypeWithCurrent(
                  configProvider.businessType,
                  _selectedCategory,
                ),
                itemLabel: (c) => c,
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: AppSpacing.medium),
              AppDropdown<String>(
                label: AppStrings.unitLabel,
                value: _selectedUnit,
                items: Units.all,
                itemLabel: (u) => Units.label(u),
                onChanged: (v) =>
                    setState(() => _selectedUnit = v ?? Units.defaultUnit),
              ),
              if (_selectedUnit == 'custom') ...[
                const SizedBox(height: AppSpacing.medium),
                AppTextInput(
                  label: AppStrings.customUomLabel,
                  hint: AppStrings.customUomHint,
                  required: true,
                  controller: _customUomController,
                  errorText: _customUomError,
                  maxLength: 30,
                  onChanged: (_) => setState(() => _customUomError = null),
                ),
              ],
              if (!_isService) ...[
                const SizedBox(height: AppSpacing.medium),
                Row(
                  children: [
                    Expanded(
                      child: AppTextInput(
                        label: AppStrings.minQuantityLabel,
                        hint: AppStrings.minQuantityHint,
                        controller: _minQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: AppTextInput(
                        label: AppStrings.quantityStepLabel,
                        hint: AppStrings.quantityStepHint,
                        controller: _stepQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              if (!_isService) ...[
                const SizedBox(height: AppSpacing.medium),
                Row(
                  children: [
                    Expanded(
                      child: AppTextInput(
                        label: AppStrings.reorderLevelLabel,
                        hint: AppStrings.reorderLevelHint,
                        controller: _reorderLevelController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: AppTextInput(
                        label: AppStrings.reorderQuantityLabel,
                        hint: AppStrings.reorderQuantityHint,
                        controller: _reorderQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                AppDropdown<String>(
                  label: AppStrings.preferredSupplierLabel,
                  hint: AppStrings.selectPreferredSupplier,
                  value: _preferredSupplierId,
                  items: context
                      .watch<SupplierProvider>()
                      .getActiveSuppliers()
                      .map((s) => s.id)
                      .toList(),
                  itemLabel: (id) =>
                      context.read<SupplierProvider>().getSupplierById(id)?.name ??
                      id,
                  onChanged: (v) => setState(() => _preferredSupplierId = v),
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              AppTextInput(
                label: AppStrings.defaultDiscountLabel,
                hint: AppStrings.defaultDiscountHint,
                controller: _defaultDiscountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                suffix: '%',
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d{0,1}'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              AppDropdown<int>(
                label: AppStrings.gstSlabLabel,
                value: _selectedGstSlab,
                items: GstSlabs.all,
                itemLabel: (g) => GstSlabs.label(g),
                onChanged: (v) => setState(() {
                  _selectedGstSlab = v ?? GstSlabs.defaultSlab;
                  _selectedGstRate = (v ?? 0).toDouble();
                }),
              ),
              if (configProvider.gstEnabled) ...[
                const SizedBox(height: AppSpacing.medium),
                AppTextInput(
                  label: AppStrings.hsnCodeLabel,
                  hint: AppStrings.hsnCodeHint,
                  controller: _hsnCodeController,
                  errorText: _hsnCodeError,
                  maxLength: 8,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (_) => setState(() => _hsnCodeError = null),
                ),
                const SizedBox(height: AppSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppStrings.gstInclusiveLabel,
                      style: AppTypography.body,
                    ),
                    Switch(
                      value: _gstInclusivePrice,
                      onChanged: (val) =>
                          setState(() => _gstInclusivePrice = val),
                      activeTrackColor: AppColors.primary,
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
              ],

              // Serial Number Tracking
              if (!_isService) ...[
                const SizedBox(height: AppSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Track Serial Numbers', style: AppTypography.body),
                        Text(
                          'Assign a serial no. to each unit sold',
                          style: AppTypography.label.copyWith(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _trackSerialNumbers,
                      onChanged: (val) =>
                          setState(() => _trackSerialNumbers = val),
                      activeTrackColor: AppColors.primary,
                      activeThumbColor: Colors.white,
                    ),
                  ],
                ),
              ],

              // Pharmacy Batch Section
              if (isPharmacy) ...[
                const SizedBox(height: AppSpacing.large),
                _isEditing
                    ? _buildBatchSectionForExisting(currentProduct)
                    : _buildBatchSectionForNew(),
              ],

              const SizedBox(height: AppSpacing.large),
              SizedBox(
                height: 48,
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
                    _isEditing ? AppStrings.saveChanges : AppStrings.save,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (_isEditing) ...[
                const SizedBox(height: AppSpacing.medium),
                Center(
                  child: TextButton(
                    onPressed: _deleteProduct,
                    child: Text(
                      AppStrings.deleteProduct,
                      style: AppTypography.body.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Batch section for existing products (uses provider)
  Widget _buildBatchSectionForExisting(Product? product) {
    final batches = product?.batches ?? _existingProduct!.batches;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.batches,
              style: AppTypography.heading.copyWith(fontSize: 16),
            ),
            TextButton.icon(
              onPressed: () =>
                  AddBatchSheet.show(context, productId: _existingProduct!.id),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(AppStrings.addBatch),
            ),
          ],
        ),
        if (batches.isEmpty)
          _buildEmptyBatchState()
        else
          ...batches.map(
            (batch) => _buildBatchCard(
              batch,
              onEdit: () => AddBatchSheet.show(
                context,
                productId: _existingProduct!.id,
                existingBatch: batch,
              ),
              onDelete: () => _deleteBatchFromProvider(batch),
            ),
          ),
      ],
    );
  }

  // Batch section for new products (uses local pending list)
  Widget _buildBatchSectionForNew() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.batches,
              style: AppTypography.heading.copyWith(fontSize: 16),
            ),
            TextButton.icon(
              onPressed: () => AddBatchSheet.showWithCallback(
                context,
                productId: _newProductId,
                onSaved: (batch) {
                  setState(() => _pendingBatches.add(batch));
                  AppSnackbar.success(context, AppStrings.batchAdded);
                },
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text(AppStrings.addBatch),
            ),
          ],
        ),
        if (_pendingBatches.isEmpty)
          _buildEmptyBatchState()
        else
          ..._pendingBatches.map(
            (batch) => _buildBatchCard(
              batch,
              onEdit: () => AddBatchSheet.showWithCallback(
                context,
                productId: _newProductId,
                existingBatch: batch,
                onSaved: (updated) {
                  setState(() {
                    final idx = _pendingBatches.indexWhere(
                      (b) => b.id == updated.id,
                    );
                    if (idx != -1) _pendingBatches[idx] = updated;
                  });
                  AppSnackbar.success(context, AppStrings.batchUpdated);
                },
              ),
              onDelete: () => _deletePendingBatch(batch),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyBatchState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Text(AppStrings.noBatches, style: AppTypography.body),
          const SizedBox(height: 4),
          Text(
            AppStrings.noBatchesDesc,
            style: AppTypography.label,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBatchCard(
    ProductBatch batch, {
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final expiryStr = DateFormat('dd MMM yyyy').format(batch.expiryDate);
    final isExpiringSoon = batch.isExpiringSoon;
    final isExpired = batch.isExpired;

    Color? expiryColor;
    String? expiryTag;
    if (isExpired) {
      expiryColor = AppColors.error;
      expiryTag = AppStrings.expired;
    } else if (isExpiringSoon) {
      expiryColor = AppColors.error;
      expiryTag = AppStrings.expiringSoon;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color:
              expiryColor?.withValues(alpha: 0.3) ??
              AppColors.muted.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.batchNumber,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Exp: $expiryStr',
                      style: AppTypography.label.copyWith(
                        color: expiryColor ?? AppColors.muted,
                      ),
                    ),
                    if (expiryTag != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: expiryColor!.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          expiryTag,
                          style: AppTypography.label.copyWith(
                            fontSize: 10,
                            color: expiryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock: ${batch.stockQuantity}',
                  style: AppTypography.label,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: 18, color: AppColors.muted),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.error,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  void _deleteBatchFromProvider(ProductBatch batch) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: '${AppStrings.deleteBatch} ${batch.batchNumber}?',
      message: AppStrings.deleteConfirm,
      confirmLabel: AppStrings.deleteBatch,
      isDestructive: true,
    );
    if (confirm && mounted) {
      context.read<ProductProvider>().deleteBatch(
        _existingProduct!.id,
        batch.id,
      );
      AppSnackbar.success(context, AppStrings.batchDeleted);
    }
  }

  void _deletePendingBatch(ProductBatch batch) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: '${AppStrings.deleteBatch} ${batch.batchNumber}?',
      message: AppStrings.deleteConfirm,
      confirmLabel: AppStrings.deleteBatch,
      isDestructive: true,
    );
    if (confirm && mounted) {
      setState(() => _pendingBatches.removeWhere((b) => b.id == batch.id));
      AppSnackbar.success(context, AppStrings.batchDeleted);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() => _imageUrl = result.files.single.path);
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    final barcode = _normalizedBarcode(_barcodeController.text);
    final priceStr = _priceController.text.trim();
    final stockStr = _stockController.text.trim();
    final configProv = context.read<BusinessConfigProvider>();
    final isPharmacy = configProv.isPharmacy;

    bool hasError = false;

    if (name.isEmpty) {
      setState(() => _nameError = AppStrings.productNameRequired);
      hasError = true;
    } else if (name.length < 2) {
      setState(() => _nameError = AppStrings.productNameMinLength);
      hasError = true;
    } else {
      final provider = context.read<ProductProvider>();
      if (provider.nameExists(
        name,
        excludeId: _isEditing ? _existingProduct!.id : null,
      )) {
        setState(() => _nameError = AppStrings.productNameDuplicate);
        hasError = true;
      }
      if (barcode != null &&
          provider.barcodeExists(
            barcode,
            excludeId: _isEditing ? _existingProduct!.id : null,
          )) {
        setState(() => _barcodeError = AppStrings.barcodeDuplicate);
        hasError = true;
      }
    }

    final price = double.tryParse(priceStr);
    if (priceStr.isEmpty) {
      setState(() => _priceError = AppStrings.sellingPriceRequired);
      hasError = true;
    } else if (price == null || price <= 0) {
      setState(() => _priceError = AppStrings.sellingPricePositive);
      hasError = true;
    }

    int? stock;
    if (!isPharmacy && !_isService) {
      stock = int.tryParse(stockStr);
      if (stock != null && stock < 0) {
        setState(() => _stockError = AppStrings.stockNegative);
        hasError = true;
      }
    }

    if (_selectedUnit == 'custom' && _customUomController.text.trim().isEmpty) {
      setState(() => _customUomError = AppStrings.customUomRequired);
      hasError = true;
    }

    if (hasError) return;

    final provider = context.read<ProductProvider>();

    final duration = int.tryParse(_durationController.text.trim());
    final minQty = double.tryParse(_minQtyController.text.trim()) ?? 1.0;
    final stepQty = double.tryParse(_stepQtyController.text.trim()) ?? 1.0;
    final customUom = _selectedUnit == 'custom'
        ? _customUomController.text.trim()
        : null;
    final hsnCode = _hsnCodeController.text.trim();
    final gstRate = _selectedGstRate;
    final reorderLevel = double.tryParse(_reorderLevelController.text.trim());
    final reorderQty = double.tryParse(_reorderQtyController.text.trim());
    final costPrice =
        double.tryParse(_costPriceController.text.trim()) ?? 0;
    final defaultDiscount =
        double.tryParse(_defaultDiscountController.text.trim()) ?? 0;

    if (_isEditing) {
      final currentProduct = provider.findById(_existingProduct!.id);
      final updated = _existingProduct!.copyWith(
        name: name,
        barcode: barcode,
        sellingPrice: price!,
        stockQuantity: _isService
            ? 0
            : isPharmacy
            ? (currentProduct?.totalBatchStock ??
                  _existingProduct!.stockQuantity)
            : (stock ?? 0),
        category: _selectedCategory,
        unit: _selectedUnit,
        customUomLabel: customUom,
        minQuantity: _isService ? 1.0 : minQty,
        quantityStep: _isService ? 1.0 : stepQty,
        hsnCode: hsnCode.isNotEmpty ? hsnCode : null,
        gstRate: gstRate,
        gstInclusivePrice: _gstInclusivePrice,
        gstSlabPercent: _selectedGstSlab,
        batches: currentProduct?.batches,
        isService: _isService,
        durationMinutes: _isService ? duration : null,
        reorderLevel: _isService ? null : reorderLevel,
        reorderQuantity: _isService ? null : reorderQty,
        costPrice: costPrice,
        preferredSupplierId: _isService ? null : _preferredSupplierId,
        defaultDiscountPercent: defaultDiscount,
        imageUrl: _imageUrl,
        trackSerialNumbers: _isService ? false : _trackSerialNumbers,
      );
      provider.updateProduct(updated);
      Navigator.pop(context);
      AppSnackbar.success(
        context,
        _isService ? AppStrings.serviceUpdated : AppStrings.productUpdated,
      );
    } else {
      final batchStock = _pendingBatches.fold(
        0,
        (sum, b) => sum + b.stockQuantity,
      );
      final product = Product(
        id: _newProductId,
        name: name,
        barcode: barcode,
        sellingPrice: price!,
        stockQuantity: _isService
            ? 0
            : isPharmacy
            ? batchStock
            : (stock ?? 0),
        category: _selectedCategory,
        unit: _selectedUnit,
        customUomLabel: customUom,
        minQuantity: _isService ? 1.0 : minQty,
        quantityStep: _isService ? 1.0 : stepQty,
        hsnCode: hsnCode.isNotEmpty ? hsnCode : null,
        gstRate: gstRate,
        gstInclusivePrice: _gstInclusivePrice,
        gstSlabPercent: _selectedGstSlab,
        batches: isPharmacy ? _pendingBatches : null,
        isService: _isService,
        durationMinutes: _isService ? duration : null,
        reorderLevel: _isService ? null : reorderLevel,
        reorderQuantity: _isService ? null : reorderQty,
        costPrice: costPrice,
        preferredSupplierId: _isService ? null : _preferredSupplierId,
        defaultDiscountPercent: defaultDiscount,
        imageUrl: _imageUrl,
        trackSerialNumbers: _isService ? false : _trackSerialNumbers,
      );
      final subProvider = context.read<SubscriptionProvider>();
      if (!subProvider.canAddProduct(provider.products.length)) {
        final max = subProvider.limits.maxProducts;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Product Limit Reached'),
            content: Text(
              'You have reached the $max product limit on your current plan. '
              'Upgrade to add more products.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/subscription');
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
        );
        return;
      }
      provider.addProduct(product);
      Navigator.pop(context);
      AppSnackbar.success(
        context,
        _isService ? AppStrings.serviceAdded : AppStrings.productSaved,
      );
    }
  }

  String? _normalizedBarcode(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  void _deleteProduct() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Delete ${_existingProduct!.name}?',
      message: AppStrings.deleteConfirm,
      confirmLabel: AppStrings.deleteProduct,
      isDestructive: true,
    );
    if (confirm && mounted) {
      context.read<ProductProvider>().deleteProduct(_existingProduct!.id);
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.productDeleted);
    }
  }
}

// ─── Live profit preview ──────────────────────────────────────────────────────

class _ProfitPreview extends StatelessWidget {
  final double costPrice;
  final double sellingPrice;

  const _ProfitPreview({required this.costPrice, required this.sellingPrice});

  @override
  Widget build(BuildContext context) {
    if (sellingPrice <= 0) return const SizedBox.shrink();
    final profit = sellingPrice - costPrice;
    final margin = sellingPrice > 0 ? (profit / sellingPrice) * 100 : 0.0;
    final isValid = costPrice > 0;
    final color = !isValid
        ? AppColors.muted
        : profit >= 0
            ? AppColors.success
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            profit >= 0 ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isValid
                ? 'Profit: ₹${profit.toStringAsFixed(2)}  |  Margin: ${margin.toStringAsFixed(1)}%'
                : 'Enter cost price to see profit',
            style: AppTypography.label.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
