import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/supplier.dart';
import '../providers/supplier_provider.dart';
import 'app_snackbar.dart';
import 'app_text_input.dart';

class AddEditSupplierSheet extends StatefulWidget {
  final Supplier? supplier;

  const AddEditSupplierSheet({super.key, this.supplier});

  static Future<void> show(BuildContext context, [Supplier? supplier]) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SupplierProvider>(),
        child: AddEditSupplierSheet(supplier: supplier),
      ),
    );
  }

  @override
  State<AddEditSupplierSheet> createState() => _AddEditSupplierSheetState();
}

class _AddEditSupplierSheetState extends State<AddEditSupplierSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _categoryController = TextEditingController();
  final List<String> _categories = [];
  String? _nameError;

  bool get _isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final s = widget.supplier!;
      _nameController.text = s.name;
      _phoneController.text = s.phone ?? '';
      _gstinController.text = s.gstin ?? '';
      _addressController.text = s.address ?? '';
      _notesController.text = s.notes ?? '';
      _categories.addAll(s.productCategories);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _categoryController.dispose();
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
              _isEdit ? AppStrings.editSupplier : AppStrings.addSupplier,
              style: AppTypography.heading,
            ),
            const SizedBox(height: AppSpacing.medium),

            AppTextInput(
              label: AppStrings.supplierNameLabel,
              required: true,
              controller: _nameController,
              errorText: _nameError,
              onChanged: (_) => setState(() => _nameError = null),
            ),
            const SizedBox(height: AppSpacing.small),

            AppTextInput(
              label: AppStrings.phoneLabel,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: AppSpacing.small),

            AppTextInput(
              label: AppStrings.supplierGstinLabel,
              controller: _gstinController,
              hint: AppStrings.supplierGstinHint,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(15),
              ],
            ),
            const SizedBox(height: AppSpacing.small),

            // Address (multi-line, use plain TextField)
            Text(
              AppStrings.supplierAddressLabel,
              style: AppTypography.label.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: AppStrings.supplierAddressHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.small),

            // Categories
            Text(
              AppStrings.supplierCategoriesLabel,
              style: AppTypography.label.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      hintText: AppStrings.supplierCategoriesHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    style: AppTypography.body,
                    onSubmitted: _addCategory,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () => _addCategory(_categoryController.text),
                ),
              ],
            ),
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.small),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _categories.map((cat) {
                  return Chip(
                    label: Text(cat, style: AppTypography.label),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _categories.remove(cat)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: AppSpacing.small),

            // Notes
            Text(
              AppStrings.supplierNotesLabel,
              style: AppTypography.label.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: AppStrings.supplierNotesHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: AppTypography.body,
            ),
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
                  _isEdit ? AppStrings.saveChanges : AppStrings.save,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCategory(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty && !_categories.contains(trimmed)) {
      setState(() {
        _categories.add(trimmed);
        _categoryController.clear();
      });
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = AppStrings.supplierNameRequired);
      return;
    }
    if (name.length < 2) {
      setState(() => _nameError = AppStrings.supplierNameMinLength);
      return;
    }

    final provider = context.read<SupplierProvider>();
    final phone = _phoneController.text.trim();
    final gstin = _gstinController.text.trim();
    final address = _addressController.text.trim();
    final notes = _notesController.text.trim();

    if (_isEdit) {
      provider.updateSupplier(
        widget.supplier!.id,
        name: name,
        phone: phone.isNotEmpty ? phone : null,
        gstin: gstin.isNotEmpty ? gstin : null,
        address: address.isNotEmpty ? address : null,
        productCategories: _categories,
        notes: notes.isNotEmpty ? notes : null,
      );
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.supplierUpdated);
    } else {
      provider.addSupplier(
        name: name,
        phone: phone.isNotEmpty ? phone : null,
        gstin: gstin.isNotEmpty ? gstin : null,
        address: address.isNotEmpty ? address : null,
        productCategories: _categories,
        notes: notes.isNotEmpty ? notes : null,
      );
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.supplierAdded);
    }
  }
}
