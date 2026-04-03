import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/sample_data.dart';
import '../constants/app_typography.dart';
import '../models/business_config.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/app_text_input.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/web_constraint.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstinController = TextEditingController();
  bool _gstEnabled = false;
  bool _sampleDataLoaded = false;
  BusinessType _businessType = BusinessType.general;

  String? _businessNameError;
  String? _phoneError;
  String? _gstinError;

  @override
  void initState() {
    super.initState();
    final businessConfig = context.read<BusinessConfigProvider>().config;
    _businessType = businessConfig.businessType;
    _sampleDataLoaded = context.read<ProductProvider>().products.isNotEmpty;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    return _businessNameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Set Up Your Shop'),
      body: WebConstraint(
        maxWidth: 600,
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Business Type Dropdown
            Text(AppStrings.businessTypeLabel, style: AppTypography.body),
            const SizedBox(height: AppSpacing.small),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.muted.withValues(alpha: 0.3),
                ),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<BusinessType>(
                  value: _businessType,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: BusinessType.general,
                      child: Text(AppStrings.businessTypeGeneral),
                    ),
                    DropdownMenuItem(
                      value: BusinessType.pharmacy,
                      child: Text(AppStrings.businessTypePharmacy),
                    ),
                    DropdownMenuItem(
                      value: BusinessType.salon,
                      child: Text(AppStrings.businessTypeSalon),
                    ),
                    DropdownMenuItem(
                      value: BusinessType.clinic,
                      child: Text(AppStrings.businessTypeClinic),
                    ),
                    DropdownMenuItem(
                      value: BusinessType.jewellery,
                      child: Text(AppStrings.businessTypeJewellery),
                    ),
                    DropdownMenuItem(
                      value: BusinessType.restaurant,
                      child: Text(AppStrings.businessTypeRestaurant),
                    ),
                    DropdownMenuItem(
                      value: BusinessType.workshop,
                      child: Text(AppStrings.businessTypeWorkshop),
                    ),
                    DropdownMenuItem(
                      value: BusinessType.mobileShop,
                      child: Text(AppStrings.businessTypeMobileShop),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      if (_sampleDataLoaded) {
                        context.read<ProductProvider>().clearProducts();
                        context.read<CustomerProvider>().clearAllData();
                        context.read<BillProvider>().clearAllBills();
                      }
                      setState(() {
                        _businessType = val;
                        _sampleDataLoaded = false;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            AppTextInput(
              label: AppStrings.businessNameLabel,
              hint: AppStrings.businessNameHint,
              required: true,
              controller: _businessNameController,
              errorText: _businessNameError,
              maxLength: 100,
              onChanged: (_) => setState(() => _businessNameError = null),
            ),
            const SizedBox(height: AppSpacing.medium),
            AppTextInput(
              label: AppStrings.phoneLabel,
              hint: AppStrings.phoneHint,
              required: true,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              errorText: _phoneError,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() => _phoneError = null),
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppStrings.gstRegistered, style: AppTypography.body),
                Switch(
                  value: _gstEnabled,
                  onChanged: (val) => setState(() {
                    _gstEnabled = val;
                    if (!val) _gstinError = null;
                  }),
                  activeTrackColor: AppColors.primary,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
            if (_gstEnabled) ...[
              const SizedBox(height: AppSpacing.medium),
              AppTextInput(
                label: AppStrings.gstNumberLabel,
                hint: AppStrings.gstNumberHint,
                required: true,
                controller: _gstinController,
                autoUppercase: true,
                maxLength: 15,
                errorText: _gstinError,
                onChanged: (_) => setState(() => _gstinError = null),
              ),
            ],
            const SizedBox(height: AppSpacing.large),
            if (!_sampleDataLoaded)
              Center(
                child: TextButton(
                  onPressed: _loadSampleData,
                  child: Text(
                    AppStrings.loadSampleData,
                    style: AppTypography.body.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            if (_sampleDataLoaded)
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Text(
                  AppStrings.sampleDataLoaded,
                  style: AppTypography.label.copyWith(color: AppColors.success),
                ),
              ),
            const SizedBox(height: AppSpacing.large),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isFormValid ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.muted.withValues(
                    alpha: 0.3,
                  ),
                  disabledForegroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppSpacing.buttonRadius,
                    ),
                  ),
                ),
                child: Text(
                  AppStrings.startBilling,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isFormValid ? Colors.white : AppColors.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _loadSampleData() {
    final productProvider = context.read<ProductProvider>();
    final customerProvider = context.read<CustomerProvider>();
    final billProvider = context.read<BillProvider>();
    productProvider.loadSampleDataForBusinessType(_businessType);
    final billingHistory = SampleData.generateBillingHistory(
      products: productProvider.products,
      businessType: _businessType,
      customerCount: 50,
      invoiceCount: 100,
    );
    customerProvider.replaceAllData(customers: billingHistory.customers);
    billProvider.replaceAllData(billingHistory.bills);
    setState(() => _sampleDataLoaded = true);
    AppSnackbar.success(context, 'Sample data loaded');
  }

  void _submit() {
    final businessName = _businessNameController.text.trim();
    final phone = _phoneController.text.trim();
    final gstin = _gstinController.text.trim();

    bool hasError = false;

    if (businessName.isEmpty) {
      setState(() => _businessNameError = AppStrings.businessNameRequired);
      hasError = true;
    } else if (businessName.length < 2) {
      setState(() => _businessNameError = AppStrings.businessNameMinLength);
      hasError = true;
    }

    if (phone.isEmpty) {
      setState(() => _phoneError = AppStrings.phoneRequired);
      hasError = true;
    } else if (phone.length != 10) {
      setState(() => _phoneError = AppStrings.phoneInvalid);
      hasError = true;
    }

    if (_gstEnabled) {
      if (gstin.isEmpty) {
        setState(() => _gstinError = AppStrings.gstNumberRequired);
        hasError = true;
      } else if (!_isValidGstin(gstin)) {
        setState(() => _gstinError = AppStrings.gstNumberInvalid);
        hasError = true;
      }
    }

    if (hasError) return;

    context.read<BusinessConfigProvider>().saveConfig(
      businessName: businessName,
      phone: phone,
      gstEnabled: _gstEnabled,
      gstin: _gstEnabled ? gstin : null,
      businessType: _businessType,
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  bool _isValidGstin(String gstin) {
    if (gstin.length != 15) return false;
    final pattern = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[A-Z0-9]{1}Z[A-Z0-9]{1}$',
    );
    return pattern.hasMatch(gstin);
  }
}
