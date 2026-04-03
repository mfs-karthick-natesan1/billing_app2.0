import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/customer.dart';
import '../providers/business_config_provider.dart';
import '../providers/customer_provider.dart';
import 'app_snackbar.dart';
import 'app_text_input.dart';

class EditCustomerSheet extends StatefulWidget {
  final Customer customer;

  const EditCustomerSheet({super.key, required this.customer});

  static Future<void> show(BuildContext context, Customer customer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<CustomerProvider>()),
          ChangeNotifierProvider.value(
            value: context.read<BusinessConfigProvider>(),
          ),
        ],
        child: EditCustomerSheet(customer: customer),
      ),
    );
  }

  @override
  State<EditCustomerSheet> createState() => _EditCustomerSheetState();
}

class _EditCustomerSheetState extends State<EditCustomerSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _ageController;
  late final TextEditingController _gstinController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _medicalNotesController;
  late final TextEditingController _discountController;
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _nameError;
  String? _phoneError;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone ?? '');
    _gstinController = TextEditingController(
      text: widget.customer.gstin ?? '',
    );
    _ageController = TextEditingController(
      text: widget.customer.age?.toString() ?? '',
    );
    _allergiesController = TextEditingController(
      text: widget.customer.allergies ?? '',
    );
    _medicalNotesController = TextEditingController(
      text: widget.customer.medicalNotes ?? '',
    );
    _discountController = TextEditingController(
      text: widget.customer.defaultDiscountPercent > 0
          ? widget.customer.defaultDiscountPercent.toStringAsFixed(
              widget.customer.defaultDiscountPercent ==
                      widget.customer.defaultDiscountPercent.roundToDouble()
                  ? 0
                  : 1,
            )
          : '',
    );
    _selectedGender = widget.customer.gender;
    _selectedBloodGroup = widget.customer.bloodGroup;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    _ageController.dispose();
    _allergiesController.dispose();
    _medicalNotesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isClinic = context.watch<BusinessConfigProvider>().isClinic;

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
            Text(AppStrings.editCustomer, style: AppTypography.heading),
            const SizedBox(height: AppSpacing.medium),
            AppTextInput(
              label: AppStrings.customerName,
              hint: 'Enter customer name',
              controller: _nameController,
              required: true,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            AppTextInput(
              label: AppStrings.customerPhone,
              hint: AppStrings.phoneHint,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              errorText: _phoneError,
              onChanged: (_) {
                if (_phoneError != null) setState(() => _phoneError = null);
              },
            ),
            if (context.watch<BusinessConfigProvider>().gstEnabled) ...[
              const SizedBox(height: AppSpacing.medium),
              AppTextInput(
                label: AppStrings.customerGstinLabel,
                hint: AppStrings.customerGstinHint,
                controller: _gstinController,
                autoUppercase: true,
                maxLength: 15,
              ),
            ],
            if (isClinic) ...[
              const SizedBox(height: AppSpacing.medium),
              Row(
                children: [
                  Expanded(
                    child: AppTextInput(
                      label: AppStrings.ageLabel,
                      hint: AppStrings.ageHint,
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.genderLabel,
                          style: AppTypography.label,
                        ),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: InputDecoration(
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
                          items: _genders
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedGender = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(AppStrings.bloodGroupLabel, style: AppTypography.label),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodGroup,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                items: _bloodGroups
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBloodGroup = v),
              ),
              const SizedBox(height: AppSpacing.medium),
              AppTextInput(
                label: AppStrings.allergiesLabel,
                hint: AppStrings.allergiesHint,
                controller: _allergiesController,
              ),
              const SizedBox(height: AppSpacing.medium),
              AppTextInput(
                label: AppStrings.medicalNotesLabel,
                hint: AppStrings.medicalNotesHint,
                controller: _medicalNotesController,
              ),
            ],
            const SizedBox(height: AppSpacing.medium),
            AppTextInput(
              label: AppStrings.defaultDiscountLabel,
              hint: AppStrings.defaultDiscountHint,
              controller: _discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,1}'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            SizedBox(
              width: double.infinity,
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
                child: const Text(AppStrings.saveChanges),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate name
    if (name.isEmpty) {
      setState(() => _nameError = AppStrings.customerNameRequired);
      return;
    }
    if (name.length < 2) {
      setState(() => _nameError = AppStrings.customerNameMinLength);
      return;
    }

    // Validate phone (optional but must be 10 digits if provided)
    if (phone.isNotEmpty && phone.length != 10) {
      setState(() => _phoneError = AppStrings.phoneInvalid);
      return;
    }

    final ageText = _ageController.text.trim();
    final gstin = _gstinController.text.trim();
    final allergies = _allergiesController.text.trim();
    final medicalNotes = _medicalNotesController.text.trim();

    final discountText = _discountController.text.trim();
    final discountPercent = double.tryParse(discountText) ?? 0;

    final success = context.read<CustomerProvider>().updateCustomer(
      widget.customer.id,
      name: name,
      phone: phone.isNotEmpty ? phone : null,
      gstin: gstin.isNotEmpty ? gstin : null,
      age: ageText.isNotEmpty ? int.tryParse(ageText) : null,
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      allergies: allergies.isNotEmpty ? allergies : null,
      medicalNotes: medicalNotes.isNotEmpty ? medicalNotes : null,
      defaultDiscountPercent: discountPercent,
    );

    if (!success) {
      setState(() => _nameError = AppStrings.customerNameDuplicate);
      return;
    }

    Navigator.pop(context);
    AppSnackbar.success(context, AppStrings.customerUpdated);
  }
}
