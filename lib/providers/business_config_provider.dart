import 'package:flutter/foundation.dart';
import '../models/business_config.dart';
import '../services/db_service.dart';

class BusinessConfigProvider extends ChangeNotifier {
  BusinessConfig _config;
  final VoidCallback? _onChanged;

  DbService? dbService;

  BusinessConfigProvider({
    BusinessConfig? initialConfig,
    VoidCallback? onChanged,
  }) : _config = initialConfig ?? const BusinessConfig(),
       _onChanged = onChanged;

  BusinessConfig get config => _config;
  bool get isSetupCompleted => _config.setupCompleted;
  String get businessName => _config.businessName;
  bool get gstEnabled => _config.gstEnabled;
  String get billPrefix => _config.billPrefix;
  BusinessType get businessType => _config.businessType;
  bool get isPharmacy => _config.businessType == BusinessType.pharmacy;
  bool get isSalon => _config.businessType == BusinessType.salon;
  bool get isClinic => _config.businessType == BusinessType.clinic;
  bool get isJewellery => _config.businessType == BusinessType.jewellery;
  bool get isRestaurant => _config.businessType == BusinessType.restaurant;
  bool get isWorkshop => _config.businessType == BusinessType.workshop;
  bool get isMobileShop => _config.businessType == BusinessType.mobileShop;
  String? get upiId => _config.upiId;
  int get tableCount => _config.tableCount;
  List<String>? get tableLabels => _config.tableLabels;
  bool get isInterState => _config.isInterState;
  bool get isCompositionScheme => _config.isCompositionScheme;
  String? get drugLicenseNumber => _config.drugLicenseNumber;
  bool get enableAdvancePayment => _config.enableAdvancePayment;

  void saveConfig({
    required String businessName,
    required String phone,
    required bool gstEnabled,
    String? gstin,
    String billPrefix = 'INV',
    BusinessType businessType = BusinessType.general,
    InvoicePageSize defaultInvoicePageSize = InvoicePageSize.a5,
    InvoiceShareFormat defaultWhatsappFormat = InvoiceShareFormat.text,
    String invoiceFooterText = 'Thank you for your business!',
    String invoiceTermsText = '',
    bool isInterState = false,
    bool isCompositionScheme = false,
    String? drugLicenseNumber,
    bool showGstinOnInvoice = true,
    bool showCustomerPhoneOnInvoice = true,
  }) {
    _config = BusinessConfig(
      businessName: businessName,
      phone: phone,
      gstEnabled: gstEnabled,
      gstin: gstin,
      setupCompleted: true,
      billPrefix: billPrefix,
      businessType: businessType,
      defaultInvoicePageSize: defaultInvoicePageSize,
      defaultWhatsappFormat: defaultWhatsappFormat,
      invoiceFooterText: invoiceFooterText,
      invoiceTermsText: invoiceTermsText,
      isInterState: isInterState,
      isCompositionScheme: isCompositionScheme,
      drugLicenseNumber: drugLicenseNumber,
      showGstinOnInvoice: showGstinOnInvoice,
      showCustomerPhoneOnInvoice: showCustomerPhoneOnInvoice,
    );
    dbService?.saveConfig(_config);
    _onChanged?.call();
    notifyListeners();
  }

  void updateLogo(String? logoBase64) {
    _config = _config.copyWithLogo(logoBase64);
    dbService?.saveConfig(_config);
    _onChanged?.call();
    notifyListeners();
  }

  void updateConfig({
    String? businessName,
    String? phone,
    String? address,
    String? email,
    bool? gstEnabled,
    String? gstin,
    String? billPrefix,
    BusinessType? businessType,
    InvoicePageSize? defaultInvoicePageSize,
    InvoiceShareFormat? defaultWhatsappFormat,
    String? invoiceFooterText,
    String? invoiceTermsText,
    bool? isInterState,
    bool? isCompositionScheme,
    String? drugLicenseNumber,
    bool? showGstinOnInvoice,
    bool? showCustomerPhoneOnInvoice,
    bool? showWatermarkOnInvoice,
    bool? notifLowStock,
    bool? notifExpiry,
    bool? notifCreditDue,
    int? notifCreditDueDays,
    bool? notifRecurringExpense,
    bool? notifEodReminder,
    int? notifEodHour,
    int? notifEodMinute,
    String? upiId,
    int? tableCount,
    List<String>? tableLabels,
    bool? enableAdvancePayment,
  }) {
    _config = _config.copyWith(
      businessName: businessName,
      phone: phone,
      address: address,
      email: email,
      gstEnabled: gstEnabled,
      gstin: gstin,
      billPrefix: billPrefix,
      businessType: businessType,
      defaultInvoicePageSize: defaultInvoicePageSize,
      defaultWhatsappFormat: defaultWhatsappFormat,
      invoiceFooterText: invoiceFooterText,
      invoiceTermsText: invoiceTermsText,
      isInterState: isInterState,
      isCompositionScheme: isCompositionScheme,
      drugLicenseNumber: drugLicenseNumber,
      showGstinOnInvoice: showGstinOnInvoice,
      showCustomerPhoneOnInvoice: showCustomerPhoneOnInvoice,
      showWatermarkOnInvoice: showWatermarkOnInvoice,
      notifLowStock: notifLowStock,
      notifExpiry: notifExpiry,
      notifCreditDue: notifCreditDue,
      notifCreditDueDays: notifCreditDueDays,
      notifRecurringExpense: notifRecurringExpense,
      notifEodReminder: notifEodReminder,
      notifEodHour: notifEodHour,
      notifEodMinute: notifEodMinute,
      upiId: upiId,
      tableCount: tableCount,
      tableLabels: tableLabels,
      enableAdvancePayment: enableAdvancePayment,
    );
    dbService?.saveConfig(_config);
    _onChanged?.call();
    notifyListeners();
  }

  void resetForSetup({BusinessType? businessType}) {
    _config = BusinessConfig(
      businessType: businessType ?? _config.businessType,
    );
    _onChanged?.call();
    notifyListeners();
  }
}
