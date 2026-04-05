import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/sample_data.dart';
import '../constants/app_typography.dart';
import '../models/business_config.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/cash_book_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/return_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/user_provider.dart';
import '../app_bootstrap.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/permission_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_input.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/add_edit_user_sheet.dart';
import '../widgets/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';
  final _businessNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  String? _logoBase64;
  final _gstinController = TextEditingController();
  final _billPrefixController = TextEditingController();
  final _invoiceFooterController = TextEditingController();
  final _invoiceTermsController = TextEditingController();
  bool _gstEnabled = false;
  bool _isInterState = false;
  bool _isCompositionScheme = false;
  final _drugLicenseController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _tableCountController = TextEditingController(text: '10');
  BusinessType _businessType = BusinessType.general;
  bool _showGstinOnInvoice = true;
  bool _showCustomerPhoneOnInvoice = true;
  bool _showWatermarkOnInvoice = true;
  bool _enableAdvancePayment = false;
  InvoiceShareFormat _defaultWhatsappFormat = InvoiceShareFormat.text;
  InvoicePageSize _defaultInvoicePageSize = InvoicePageSize.a5;
  AppThemeMode _appThemeMode = AppThemeMode.system;
  bool _requirePinOnOpen = true;
  int _autoLockMinutes = 5;
  bool _notifLowStock = true;
  bool _notifExpiry = true;
  bool _notifCreditDue = true;
  int _notifCreditDueDays = 30;
  bool _notifRecurringExpense = true;
  bool _notifEodReminder = true;
  TimeOfDay _notifEodTime = const TimeOfDay(hour: 21, minute: 0);

  String? _businessNameError;
  String? _phoneError;
  String? _gstinError;
  String? _billPrefixError;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      PackageInfo.fromPlatform().then((info) {
        if (mounted) {
          setState(() {
            _appVersion = '${info.version} (build ${info.buildNumber})';
          });
        }
      });
    }
    final config = context.read<BusinessConfigProvider>().config;
    _businessNameController.text = config.businessName;
    _phoneController.text = config.phone;
    _addressController.text = config.address;
    _emailController.text = config.email;
    _logoBase64 = config.logoBase64;
    _gstinController.text = config.gstin ?? '';
    _billPrefixController.text = config.billPrefix;
    _invoiceFooterController.text = config.invoiceFooterText;
    _invoiceTermsController.text = config.invoiceTermsText;
    _gstEnabled = config.gstEnabled;
    _isInterState = config.isInterState;
    _isCompositionScheme = config.isCompositionScheme;
    _drugLicenseController.text = config.drugLicenseNumber ?? '';
    _businessType = config.businessType;
    _upiIdController.text = config.upiId ?? '';
    _tableCountController.text = config.tableCount.toString();
    _showGstinOnInvoice = config.showGstinOnInvoice;
    _showCustomerPhoneOnInvoice = config.showCustomerPhoneOnInvoice;
    _showWatermarkOnInvoice = config.showWatermarkOnInvoice;
    _enableAdvancePayment = config.enableAdvancePayment;
    _defaultWhatsappFormat = config.defaultWhatsappFormat;
    _defaultInvoicePageSize = config.defaultInvoicePageSize;
    _appThemeMode = config.appThemeMode;
    _notifLowStock = config.notifLowStock;
    _notifExpiry = config.notifExpiry;
    _notifCreditDue = config.notifCreditDue;
    _notifCreditDueDays = config.notifCreditDueDays;
    _notifRecurringExpense = config.notifRecurringExpense;
    _notifEodReminder = config.notifEodReminder;
    _notifEodTime = TimeOfDay(
      hour: config.notifEodHour,
      minute: config.notifEodMinute,
    );
    final userProvider = Provider.of<UserProvider?>(context, listen: false);
    if (userProvider != null) {
      _requirePinOnOpen = userProvider.requirePinOnOpen;
      _autoLockMinutes = userProvider.autoLockMinutes;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _billPrefixController.dispose();
    _invoiceFooterController.dispose();
    _invoiceTermsController.dispose();
    _drugLicenseController.dispose();
    _upiIdController.dispose();
    _tableCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider?>();

    return Scaffold(
      appBar: const AppTopBar(title: AppStrings.settingsTitle, showBack: true),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: kIsWeb ? 800 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── 1. Business Profile Card ───────────────────────
                _card(Icons.store_outlined, AppStrings.businessProfileSection, [
                  _labeledDropdown(
                    label: AppStrings.businessTypeLabel,
                    child: DropdownButton<BusinessType>(
                      value: _businessType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: BusinessType.general, child: Text(AppStrings.businessTypeGeneral)),
                        DropdownMenuItem(value: BusinessType.pharmacy, child: Text(AppStrings.businessTypePharmacy)),
                        DropdownMenuItem(value: BusinessType.salon, child: Text(AppStrings.businessTypeSalon)),
                        DropdownMenuItem(value: BusinessType.clinic, child: Text(AppStrings.businessTypeClinic)),
                        DropdownMenuItem(value: BusinessType.jewellery, child: Text(AppStrings.businessTypeJewellery)),
                        DropdownMenuItem(value: BusinessType.restaurant, child: Text(AppStrings.businessTypeRestaurant)),
                        DropdownMenuItem(value: BusinessType.workshop, child: Text(AppStrings.businessTypeWorkshop)),
                        DropdownMenuItem(value: BusinessType.mobileShop, child: Text(AppStrings.businessTypeMobileShop)),
                      ],
                      onChanged: (val) { if (val != null) setState(() => _businessType = val); },
                    ),
                  ),
                  if (_businessType == BusinessType.restaurant) ...[
                    const SizedBox(height: AppSpacing.medium),
                    AppTextInput(
                      label: AppStrings.tableCountLabel,
                      hint: AppStrings.tableCountHint,
                      controller: _tableCountController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
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
                  TextField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Business Address',
                      hintText: 'e.g. 123 Main St, Chennai - 600001',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  AppTextInput(
                    label: 'Email',
                    hint: 'e.g. billing@mybusiness.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text('Business Logo', style: AppTypography.body),
                  const SizedBox(height: AppSpacing.small),
                  Row(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.muted.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                          color: AppColors.muted.withValues(alpha: 0.05),
                        ),
                        child: _logoBase64 != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 1),
                                child: Image.memory(base64Decode(_logoBase64!), fit: BoxFit.contain),
                              )
                            : const Icon(Icons.business, color: AppColors.muted, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.medium),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickLogo,
                            icon: const Icon(Icons.upload, size: 16),
                            label: Text(_logoBase64 == null ? 'Upload Logo' : 'Change Logo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              textStyle: AppTypography.label,
                            ),
                          ),
                          if (_logoBase64 != null) ...[
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () => setState(() => _logoBase64 = null),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Remove Logo'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ]),

                // ── 2. Tax Settings Card ───────────────────────────
                _card(Icons.receipt_long_outlined, AppStrings.taxSettingsSection, [
                  _switchRow(AppStrings.gstRegistered, _gstEnabled, (val) => setState(() {
                    _gstEnabled = val;
                    if (!val) _gstinError = null;
                  })),
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
                    const SizedBox(height: AppSpacing.small),
                    _switchRow(AppStrings.interStateSupply, _isInterState, (val) => setState(() => _isInterState = val)),
                    _switchRow(AppStrings.compositionScheme, _isCompositionScheme, (val) => setState(() => _isCompositionScheme = val)),
                    if (_businessType == BusinessType.pharmacy) ...[
                      const SizedBox(height: AppSpacing.small),
                      AppTextInput(
                        label: AppStrings.drugLicenseLabel,
                        hint: AppStrings.drugLicenseHint,
                        controller: _drugLicenseController,
                        maxLength: 30,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.small),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/gstr1-export'),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text(AppStrings.gstr1Export),
                    ),
                  ],
                ]),

                // ── 3. Payment Settings Card ───────────────────────
                _card(Icons.payment_outlined, 'Payment Settings', [
                  AppTextInput(
                    label: 'UPI ID',
                    hint: 'e.g. yourname@upi',
                    controller: _upiIdController,
                  ),
                  const SizedBox(height: 4),
                  Text('Used to generate a QR code at checkout.', style: AppTypography.label.copyWith(color: AppColors.muted, fontSize: 11)),
                ]),

                // ── 4. Invoice & Sharing Card ──────────────────────
                _card(Icons.description_outlined, AppStrings.invoiceSharingSection, [
                  AppTextInput(
                    label: AppStrings.billPrefixLabel,
                    hint: AppStrings.billPrefixHint,
                    required: true,
                    controller: _billPrefixController,
                    autoUppercase: true,
                    maxLength: 10,
                    errorText: _billPrefixError,
                    onChanged: (_) => setState(() => _billPrefixError = null),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _labeledDropdown(
                    label: AppStrings.defaultInvoicePageSize,
                    child: DropdownButton<InvoicePageSize>(
                      value: _defaultInvoicePageSize,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: InvoicePageSize.a5, child: Text(AppStrings.invoicePageSizeA5)),
                        DropdownMenuItem(value: InvoicePageSize.a4, child: Text(AppStrings.invoicePageSizeA4)),
                      ],
                      onChanged: (value) { if (value != null) setState(() => _defaultInvoicePageSize = value); },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _labeledDropdown(
                    label: AppStrings.defaultWhatsAppFormat,
                    child: DropdownButton<InvoiceShareFormat>(
                      value: _defaultWhatsappFormat,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: InvoiceShareFormat.text, child: Text(AppStrings.whatsappFormatText)),
                        DropdownMenuItem(value: InvoiceShareFormat.pdf, child: Text(AppStrings.whatsappFormatPdf)),
                        DropdownMenuItem(value: InvoiceShareFormat.image, child: Text(AppStrings.whatsappFormatImage)),
                      ],
                      onChanged: (value) { if (value != null) setState(() => _defaultWhatsappFormat = value); },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  AppTextInput(
                    label: AppStrings.invoiceFooterLabel,
                    hint: AppStrings.invoiceFooterHint,
                    controller: _invoiceFooterController,
                    maxLength: 120,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  AppTextInput(
                    label: AppStrings.invoiceTermsLabel,
                    hint: AppStrings.invoiceTermsHint,
                    controller: _invoiceTermsController,
                    maxLength: 250,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  _switchRow(AppStrings.showGstinOnInvoice, _showGstinOnInvoice, (v) => setState(() => _showGstinOnInvoice = v)),
                  _switchRow(AppStrings.showCustomerPhoneOnInvoice, _showCustomerPhoneOnInvoice, (v) => setState(() => _showCustomerPhoneOnInvoice = v)),
                  _switchRow('Show Watermark on Invoice', _showWatermarkOnInvoice, (v) => setState(() => _showWatermarkOnInvoice = v)),
                  _switchRow('Enable Advance Payments', _enableAdvancePayment, (v) => setState(() => _enableAdvancePayment = v), subtitle: 'Allow recording & using customer advances'),
                ]),

                // ── 5. Users & Access Card (conditional) ──────────
                if (userProvider != null)
                  _card(Icons.people_outlined, AppStrings.usersAccessTitle, [
                    if (userProvider.singleUserMode) ...[
                      Text(AppStrings.enableUserManagementDesc, style: AppTypography.label),
                      const SizedBox(height: AppSpacing.small),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => AddEditUserSheet.show(context, ownerSetup: true),
                          child: const Text(AppStrings.createOwnerAccount),
                        ),
                      ),
                    ] else if (userProvider.isOwner) ...[
                      SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamed(context, '/users'),
                          child: const Text(AppStrings.manageUsers),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _switchRow(AppStrings.requirePinOnOpen, _requirePinOnOpen, (v) => setState(() => _requirePinOnOpen = v)),
                      const SizedBox(height: 4),
                      _labeledDropdown(
                        label: AppStrings.autoLockTimeout,
                        child: DropdownButton<int>(
                          value: _autoLockMinutes,
                          isExpanded: true,
                          items: const [5, 10, 30, 0].map((v) => DropdownMenuItem<int>(value: v, child: Text(v == 0 ? AppStrings.never : _autoLockLabel(v)))).toList(),
                          onChanged: (v) { if (v != null) setState(() => _autoLockMinutes = v); },
                        ),
                      ),
                    ] else
                      Text(AppStrings.ownerOnlyAction, style: AppTypography.label),
                  ]),

                // ── 6. Notifications Card ──────────────────────────
                _card(Icons.notifications_outlined, AppStrings.notificationsSection, [
                  _notifToggle(
                    label: AppStrings.notifLowStock,
                    subtitle: AppStrings.notifLowStockDesc,
                    value: _notifLowStock,
                    onChanged: (v) => setState(() => _notifLowStock = v),
                  ),
                  if (_businessType == BusinessType.pharmacy)
                    _notifToggle(
                      label: AppStrings.notifExpiry,
                      subtitle: AppStrings.notifExpiryDesc,
                      value: _notifExpiry,
                      onChanged: (v) => setState(() => _notifExpiry = v),
                    ),
                  _notifToggle(
                    label: AppStrings.notifCreditDue,
                    subtitle: AppStrings.notifCreditDueDesc,
                    value: _notifCreditDue,
                    onChanged: (v) => setState(() => _notifCreditDue = v),
                  ),
                  if (_notifCreditDue)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: AppSpacing.small),
                      child: Row(
                        children: [
                          Text(AppStrings.notifCreditDaysLabel, style: AppTypography.label),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.muted.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _notifCreditDueDays,
                                  isExpanded: true,
                                  items: const [7, 15, 30, 45, 60, 90].map((d) => DropdownMenuItem<int>(value: d, child: Text('$d'))).toList(),
                                  onChanged: (v) { if (v != null) setState(() => _notifCreditDueDays = v); },
                                ),
                              ),
                            ),
                          ),
                          Text(' days', style: AppTypography.label),
                        ],
                      ),
                    ),
                  _notifToggle(
                    label: AppStrings.notifRecurringExpense,
                    subtitle: AppStrings.notifRecurringExpenseDesc,
                    value: _notifRecurringExpense,
                    onChanged: (v) => setState(() => _notifRecurringExpense = v),
                  ),
                  _notifToggle(
                    label: AppStrings.notifEodReminder,
                    subtitle: AppStrings.notifEodReminderDesc,
                    value: _notifEodReminder,
                    onChanged: (v) => setState(() => _notifEodReminder = v),
                  ),
                  if (_notifEodReminder)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: AppSpacing.small),
                      child: Row(
                        children: [
                          Text(AppStrings.notifEodTimeLabel, style: AppTypography.label),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () async {
                              final picked = await showTimePicker(context: context, initialTime: _notifEodTime);
                              if (picked != null) setState(() => _notifEodTime = picked);
                            },
                            child: Text(_notifEodTime.format(context)),
                          ),
                        ],
                      ),
                    ),
                ]),

                // ── 7. Suppliers & Purchases Card ──────────────────
                _card(Icons.local_shipping_outlined, AppStrings.suppliersTitle, [
                  Row(children: [
                    Expanded(child: SizedBox(height: 44, child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/suppliers'),
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text(AppStrings.suppliersTitle),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                    ))),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(child: SizedBox(height: 44, child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/purchases'),
                      icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                      label: const Text(AppStrings.purchasesTitle),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
                    ))),
                  ]),
                ]),

                // ── 8. Appearance Card ─────────────────────────────
                _card(Icons.palette_outlined, 'Appearance', [
                  Text('App Theme', style: AppTypography.label.copyWith(color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.small),
                  SegmentedButton<AppThemeMode>(
                    segments: const [
                      ButtonSegment(value: AppThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined, size: 16)),
                      ButtonSegment(value: AppThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_outlined, size: 16)),
                      ButtonSegment(value: AppThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined, size: 16)),
                    ],
                    selected: {_appThemeMode},
                    onSelectionChanged: (s) => setState(() => _appThemeMode = s.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ]),

                // ── 9. App Info Card ───────────────────────────────
                _card(Icons.info_outline, AppStrings.appInfoSection, [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(AppStrings.appName, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold)),
                    Text('v${_appVersion.isNotEmpty ? _appVersion : '1.0.0'}', style: AppTypography.label.copyWith(color: AppColors.muted)),
                  ]),
                ]),

                // ── 9. Data Card ───────────────────────────────────
                _card(Icons.storage_outlined, AppStrings.dataSection, [
                  Text(AppStrings.exportBackupDesc, style: AppTypography.label.copyWith(color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.small),
                  SizedBox(height: 44, child: OutlinedButton.icon(
                    onPressed: _exportBackup,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: Text(AppStrings.exportBackup, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35))),
                  )),
                  const SizedBox(height: AppSpacing.medium),
                  Text(AppStrings.logoutAndLoadSampleDataDesc, style: AppTypography.label.copyWith(color: AppColors.muted)),
                  const SizedBox(height: AppSpacing.small),
                  SizedBox(height: 44, child: OutlinedButton.icon(
                    onPressed: _logoutAndLoadSampleData,
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(AppStrings.logoutAndLoadSampleData, style: AppTypography.body.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withValues(alpha: 0.35))),
                  )),
                ]),

                // ── Save Button ────────────────────────────────────
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
                    ),
                    child: Text(AppStrings.saveSettings, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),

                // ── 10. Account Card (auth only) ───────────────────
                if (AuthService.businessId != null) ...[
                  const SizedBox(height: AppSpacing.small),
                  _card(Icons.manage_accounts_outlined, 'Account', [
                    _accountTile(icon: Icons.stars_rounded, label: 'Manage Subscription', subtitle: 'View plan & billing details', onTap: () => Navigator.pushNamed(context, '/subscription'), color: AppColors.primary),
                    const Divider(height: 1),
                    _accountTile(icon: Icons.lock_outline, label: 'Change Password', onTap: _showChangePasswordSheet),
                    const Divider(height: 1),
                    _accountTile(icon: Icons.inbox_outlined, label: 'My Support Tickets', subtitle: 'View & track your tickets', onTap: () => Navigator.pushNamed(context, '/support-tickets'), color: AppColors.primary),
                    const Divider(height: 1),
                    _accountTile(icon: Icons.support_agent, label: 'Raise Support Ticket', subtitle: 'Report an issue or request', onTap: _showSupportSheet),
                    const Divider(height: 1),
                    _accountTile(icon: Icons.logout, label: 'Sign Out', onTap: _signOut, color: AppColors.error),
                  ]),
                ],

                const SizedBox(height: AppSpacing.large),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Card container for each settings section — collapsible
  Widget _card(IconData icon, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 1),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryLight(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            title: Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.bold, fontSize: 15)),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: AppColors.muted,
            collapsedIconColor: AppColors.muted,
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: 4),
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Dropdown wrapped in a bordered container
  Widget _labeledDropdown({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: AppColors.muted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: DropdownButtonHideUnderline(child: child),
        ),
      ],
    );
  }

  // Simple switch row inside a card
  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.body),
                if (subtitle != null)
                  Text(subtitle, style: AppTypography.label.copyWith(color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  // Account action tile (for the bottom account card)
  Widget _accountTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    String? subtitle,
  }) {
    final c = color ?? AppColors.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.body.copyWith(color: c)),
                  if (subtitle != null)
                    Text(subtitle, style: AppTypography.label.copyWith(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.muted.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _notifToggle({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.body),
                Text(
                  subtitle,
                  style: AppTypography.label.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) return;
      setState(() => _logoBase64 = base64Encode(bytes));
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Could not pick image');
    }
  }

  void _save() {
    final userProvider = Provider.of<UserProvider?>(context, listen: false);
    if (userProvider != null &&
        !userProvider.singleUserMode &&
        !userProvider.canPerform(Permission.editSettings)) {
      AppSnackbar.error(context, AppStrings.ownerOnlyAction);
      return;
    }

    final businessName = _businessNameController.text.trim();
    final phone = _phoneController.text.trim();
    final gstin = _gstinController.text.trim();
    final billPrefix = _billPrefixController.text.trim();

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

    if (billPrefix.isEmpty) {
      setState(() => _billPrefixError = AppStrings.billPrefixRequired);
      hasError = true;
    }

    if (hasError) return;

    final configProvider = context.read<BusinessConfigProvider>();
    configProvider.updateConfig(
      businessName: businessName,
      phone: phone,
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      gstEnabled: _gstEnabled,
      gstin: _gstEnabled ? gstin : null,
      billPrefix: billPrefix,
      businessType: _businessType,
      defaultInvoicePageSize: _defaultInvoicePageSize,
      defaultWhatsappFormat: _defaultWhatsappFormat,
      invoiceFooterText: _invoiceFooterController.text.trim(),
      invoiceTermsText: _invoiceTermsController.text.trim(),
      isInterState: _gstEnabled ? _isInterState : false,
      isCompositionScheme: _gstEnabled ? _isCompositionScheme : false,
      drugLicenseNumber: _gstEnabled
          ? (_drugLicenseController.text.trim().isNotEmpty
              ? _drugLicenseController.text.trim()
              : null)
          : null,
      showGstinOnInvoice: _showGstinOnInvoice,
      showCustomerPhoneOnInvoice: _showCustomerPhoneOnInvoice,
      showWatermarkOnInvoice: _showWatermarkOnInvoice,
      enableAdvancePayment: _enableAdvancePayment,
      notifLowStock: _notifLowStock,
      notifExpiry: _notifExpiry,
      notifCreditDue: _notifCreditDue,
      notifCreditDueDays: _notifCreditDueDays,
      notifRecurringExpense: _notifRecurringExpense,
      notifEodReminder: _notifEodReminder,
      notifEodHour: _notifEodTime.hour,
      notifEodMinute: _notifEodTime.minute,
      upiId: _upiIdController.text.trim().isNotEmpty
          ? _upiIdController.text.trim()
          : null,
      tableCount: int.tryParse(_tableCountController.text.trim()) ?? 10,
      appThemeMode: _appThemeMode,
    );
    configProvider.updateLogo(_logoBase64);

    // Reschedule notifications with updated settings
    final updatedConfig = configProvider.config;
    NotificationService.scheduleDailyChecks(
      config: updatedConfig,
      productProvider: context.read<ProductProvider>(),
      customerProvider: context.read<CustomerProvider>(),
      expenseProvider: context.read<ExpenseProvider>(),
    );

    if (userProvider != null &&
        !userProvider.singleUserMode &&
        userProvider.isOwner) {
      userProvider.updateSecuritySettings(
        requirePinOnOpen: _requirePinOnOpen,
        autoLockMinutes: _autoLockMinutes,
      );
    }

    AppSnackbar.success(context, AppStrings.settingsSaved);
    Navigator.pop(context);
  }

  Future<void> _showSupportSheet() async {
    final categories = ['Bug / Error', 'Feature Request', 'Billing / Subscription', 'Account Issue', 'Other'];
    String selectedCategory = categories.first;
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final userEmail = AuthService.currentUser?.email ?? '';
    List<int>? screenshotBytes;
    String? screenshotName;
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.medium,
              right: AppSpacing.medium,
              top: AppSpacing.medium,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.large,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.muted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text('Raise Support Ticket', style: AppTypography.heading),
                    const SizedBox(height: 4),
                    Text(
                      'We\'ll respond to $userEmail within 24 hours.',
                      style: AppTypography.label.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Text('Category', style: AppTypography.label),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setModalState(() => selectedCategory = v ?? categories.first),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    TextFormField(
                      controller: subjectCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a subject' : null,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    TextFormField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe the issue or request in detail...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a description' : null,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    // Screenshot attachment
                    if (screenshotBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          Uint8List.fromList(screenshotBytes!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              screenshotName ?? 'screenshot',
                              style: AppTypography.label.copyWith(color: AppColors.muted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: () => setModalState(() {
                              screenshotBytes = null;
                              screenshotName = null;
                            }),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ] else
                      OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('Attach Screenshot'),
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            const maxSize = 5 * 1024 * 1024; // 5 MB
                            final allowedTypes = {'jpg', 'jpeg', 'png', 'webp'};
                            final ext = file.name.split('.').last.toLowerCase();
                            if (!allowedTypes.contains(ext)) {
                              if (context.mounted) {
                                AppSnackbar.error(context, 'Only JPG, PNG, or WebP images are allowed.');
                              }
                            } else if (file.size > maxSize) {
                              if (context.mounted) {
                                AppSnackbar.error(context, 'Screenshot must be under 5 MB.');
                              }
                            } else if (file.bytes != null) {
                              setModalState(() {
                                screenshotBytes = file.bytes!.toList();
                                screenshotName = file.name;
                              });
                            }
                          }
                        },
                      ),
                    const SizedBox(height: AppSpacing.large),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(isSubmitting ? 'Submitting...' : 'Submit Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSubmitting = true);
                                try {
                                  await AuthService.submitSupportTicket(
                                    category: selectedCategory,
                                    subject: subjectCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    screenshotBytes: screenshotBytes,
                                    fileName: screenshotName,
                                  );
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) AppSnackbar.success(context, 'Ticket submitted successfully');
                                } catch (e) {
                                  setModalState(() => isSubmitting = false);
                                  if (mounted) AppSnackbar.error(context, 'Failed to submit: $e');
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    subjectCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _showChangePasswordSheet() async {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.medium,
              right: AppSpacing.medium,
              top: AppSpacing.medium,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.large,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Change Password', style: AppTypography.heading),
                  const SizedBox(height: AppSpacing.large),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter new password';
                      if (v.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  TextFormField(
                    controller: confirmPassCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v != newPassCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.large),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final nav = Navigator.of(ctx);
                        try {
                          await AuthService.changePassword(
                            newPassword: newPassCtrl.text.trim(),
                          );
                          if (mounted) {
                            nav.pop();
                            AppSnackbar.success(context, 'Password updated successfully');
                          }
                        } catch (e) {
                          if (mounted) {
                            AppSnackbar.error(context, 'Failed: ${e.toString()}');
                          }
                        }
                      },
                      child: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );

    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
  }

  Future<void> _signOut() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      message: 'Sign out of your account? You will need to sign in again.',
      confirmLabel: 'Sign Out',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    await AuthService.signOut();
    await AppBootstrap.restart?.call();
  }

  bool _isValidGstin(String gstin) {
    if (gstin.length != 15) return false;
    final pattern = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[A-Z0-9]{1}Z[A-Z0-9]{1}$',
    );
    return pattern.hasMatch(gstin);
  }

  Future<void> _exportBackup() async {
    try {
      final billProvider = context.read<BillProvider>();
      final productProvider = context.read<ProductProvider>();
      final customerProvider = context.read<CustomerProvider>();
      final expenseProvider = context.read<ExpenseProvider>();
      final supplierProvider = context.read<SupplierProvider>();

      final backup = {
        'exportedAt': DateTime.now().toIso8601String(),
        'bills': billProvider.bills.map((b) => b.toJson()).toList(),
        'products': productProvider.products.map((p) => p.toJson()).toList(),
        'customers': customerProvider.customers.map((c) => c.toJson()).toList(),
        'expenses': expenseProvider.expenses.map((e) => e.toJson()).toList(),
        'suppliers': supplierProvider.suppliers.map((s) => s.toJson()).toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(backup);
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final file = File('${dir.path}/billready_backup_$timestamp.json');
      await file.writeAsString(json);
      await Share.shareXFiles([XFile(file.path)], subject: 'BillReady Data Backup');
      await file.delete();

      if (mounted) {
        AppSnackbar.success(context, AppStrings.exportBackupDone);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, AppStrings.exportBackupFailed);
      }
    }
  }

  Future<void> _logoutAndLoadSampleData() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.logoutAndLoadSampleData,
      message: AppStrings.logoutAndLoadSampleDataConfirm,
      confirmLabel: AppStrings.logoutAction,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    final selectedBusinessType = _businessType;
    context.read<BillProvider>().clearAllBills();
    context.read<CustomerProvider>().clearAllData();
    context.read<ExpenseProvider>().clearAllData();
    context.read<CashBookProvider>().clearAllData();
    context.read<PurchaseProvider>().clearAllData();
    context.read<SupplierProvider>().clearAllData();
    context.read<ReturnProvider>().clearAllData();
    context.read<UserProvider?>()?.logout();
    final productProvider = context.read<ProductProvider>();
    productProvider.loadSampleDataForBusinessType(selectedBusinessType);
    final billingHistory = SampleData.generateBillingHistory(
      products: productProvider.products,
      businessType: selectedBusinessType,
      customerCount: 50,
      invoiceCount: 100,
    );
    context.read<CustomerProvider>().replaceAllData(
      customers: billingHistory.customers,
    );
    context.read<BillProvider>().replaceAllData(billingHistory.bills);
    context.read<BusinessConfigProvider>().resetForSetup(
      businessType: selectedBusinessType,
    );
    context.read<NavigationProvider>().setTab(0);

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/setup', (route) => false);
  }

  static String _autoLockLabel(int value) => '$value min';
}
