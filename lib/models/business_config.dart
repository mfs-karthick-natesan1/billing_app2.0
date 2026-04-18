enum BusinessType { general, pharmacy, salon, clinic, jewellery, restaurant, workshop, mobileShop }

enum AppThemeMode { system, light, dark }

enum InvoicePageSize { a5, a4 }

enum InvoiceShareFormat { text, pdf, image }

class BusinessConfig {
  final String businessName;
  final String phone;
  final String address;
  final String email;
  final String? logoBase64;
  final bool gstEnabled;
  final String? gstin;
  final bool setupCompleted;
  final String billPrefix;
  final BusinessType businessType;
  final InvoicePageSize defaultInvoicePageSize;
  final InvoiceShareFormat defaultWhatsappFormat;
  final String invoiceFooterText;
  final String invoiceTermsText;
  final bool isInterState;
  final bool isCompositionScheme;
  final String? drugLicenseNumber;
  final bool showGstinOnInvoice;
  final bool showCustomerPhoneOnInvoice;
  final bool showWatermarkOnInvoice;
  final bool enableAdvancePayment;
  // Payment settings
  final String? upiId;
  final String? gpayNumber;
  final bool showGpayOnInvoice;
  // Restaurant settings
  final int tableCount;
  final List<String>? tableLabels;

  // Appearance
  final AppThemeMode appThemeMode;

  // Force update: minimum build number required to run the app
  final int minBuildNumber;

  // Notification settings
  final bool notifLowStock;
  final bool notifExpiry;
  final bool notifCreditDue;
  final int notifCreditDueDays;
  final bool notifRecurringExpense;
  final bool notifEodReminder;
  final int notifEodHour;
  final int notifEodMinute;

  const BusinessConfig({
    this.businessName = '',
    this.phone = '',
    this.address = '',
    this.email = '',
    this.logoBase64,
    this.gstEnabled = false,
    this.gstin,
    this.setupCompleted = false,
    this.billPrefix = 'INV',
    this.businessType = BusinessType.general,
    this.defaultInvoicePageSize = InvoicePageSize.a5,
    this.defaultWhatsappFormat = InvoiceShareFormat.text,
    this.invoiceFooterText = 'Thank you for your business!',
    this.invoiceTermsText = '',
    this.isInterState = false,
    this.isCompositionScheme = false,
    this.drugLicenseNumber,
    this.showGstinOnInvoice = true,
    this.showCustomerPhoneOnInvoice = true,
    this.showWatermarkOnInvoice = true,
    this.enableAdvancePayment = false,
    this.upiId,
    this.gpayNumber,
    this.showGpayOnInvoice = false,
    this.tableCount = 10,
    this.tableLabels,
    this.notifLowStock = true,
    this.notifExpiry = true,
    this.notifCreditDue = true,
    this.notifCreditDueDays = 30,
    this.notifRecurringExpense = true,
    this.notifEodReminder = true,
    this.notifEodHour = 21,
    this.notifEodMinute = 0,
    this.appThemeMode = AppThemeMode.system,
    this.minBuildNumber = 0,
  });

  // Sentinel to distinguish "clear logo" from "keep existing"
  BusinessConfig copyWithLogo(String? logo) {
    return BusinessConfig(
      businessName: businessName,
      phone: phone,
      address: address,
      email: email,
      logoBase64: logo,
      gstEnabled: gstEnabled,
      gstin: gstin,
      setupCompleted: setupCompleted,
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
      enableAdvancePayment: enableAdvancePayment,
      upiId: upiId,
      gpayNumber: gpayNumber,
      showGpayOnInvoice: showGpayOnInvoice,
      tableCount: tableCount,
      tableLabels: tableLabels,
      notifLowStock: notifLowStock,
      notifExpiry: notifExpiry,
      notifCreditDue: notifCreditDue,
      notifCreditDueDays: notifCreditDueDays,
      notifRecurringExpense: notifRecurringExpense,
      notifEodReminder: notifEodReminder,
      notifEodHour: notifEodHour,
      notifEodMinute: notifEodMinute,
    );
  }

  BusinessConfig copyWith({
    String? businessName,
    String? phone,
    String? address,
    String? email,
    bool? gstEnabled,
    String? gstin,
    bool? setupCompleted,
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
    bool? enableAdvancePayment,
    String? upiId,
    String? gpayNumber,
    bool? showGpayOnInvoice,
    int? tableCount,
    List<String>? tableLabels,
    bool? notifLowStock,
    bool? notifExpiry,
    bool? notifCreditDue,
    int? notifCreditDueDays,
    bool? notifRecurringExpense,
    bool? notifEodReminder,
    int? notifEodHour,
    int? notifEodMinute,
    AppThemeMode? appThemeMode,
  }) {
    return BusinessConfig(
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      logoBase64: logoBase64,  // preserved; use copyWithLogo to change
      gstEnabled: gstEnabled ?? this.gstEnabled,
      gstin: gstin ?? this.gstin,
      setupCompleted: setupCompleted ?? this.setupCompleted,
      billPrefix: billPrefix ?? this.billPrefix,
      businessType: businessType ?? this.businessType,
      defaultInvoicePageSize:
          defaultInvoicePageSize ?? this.defaultInvoicePageSize,
      defaultWhatsappFormat:
          defaultWhatsappFormat ?? this.defaultWhatsappFormat,
      invoiceFooterText: invoiceFooterText ?? this.invoiceFooterText,
      invoiceTermsText: invoiceTermsText ?? this.invoiceTermsText,
      isInterState: isInterState ?? this.isInterState,
      isCompositionScheme: isCompositionScheme ?? this.isCompositionScheme,
      drugLicenseNumber: drugLicenseNumber ?? this.drugLicenseNumber,
      showGstinOnInvoice: showGstinOnInvoice ?? this.showGstinOnInvoice,
      showCustomerPhoneOnInvoice:
          showCustomerPhoneOnInvoice ?? this.showCustomerPhoneOnInvoice,
      showWatermarkOnInvoice:
          showWatermarkOnInvoice ?? this.showWatermarkOnInvoice,
      enableAdvancePayment: enableAdvancePayment ?? this.enableAdvancePayment,
      upiId: upiId ?? this.upiId,
      gpayNumber: gpayNumber ?? this.gpayNumber,
      showGpayOnInvoice: showGpayOnInvoice ?? this.showGpayOnInvoice,
      tableCount: tableCount ?? this.tableCount,
      tableLabels: tableLabels ?? this.tableLabels,
      notifLowStock: notifLowStock ?? this.notifLowStock,
      notifExpiry: notifExpiry ?? this.notifExpiry,
      notifCreditDue: notifCreditDue ?? this.notifCreditDue,
      notifCreditDueDays: notifCreditDueDays ?? this.notifCreditDueDays,
      notifRecurringExpense:
          notifRecurringExpense ?? this.notifRecurringExpense,
      notifEodReminder: notifEodReminder ?? this.notifEodReminder,
      notifEodHour: notifEodHour ?? this.notifEodHour,
      notifEodMinute: notifEodMinute ?? this.notifEodMinute,
      appThemeMode: appThemeMode ?? this.appThemeMode,
      minBuildNumber: minBuildNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'phone': phone,
      'address': address,
      'email': email,
      'logoBase64': logoBase64,
      'gstEnabled': gstEnabled,
      'gstin': gstin,
      'setupCompleted': setupCompleted,
      'billPrefix': billPrefix,
      'businessType': businessType.name,
      'defaultInvoicePageSize': defaultInvoicePageSize.name,
      'defaultWhatsappFormat': defaultWhatsappFormat.name,
      'invoiceFooterText': invoiceFooterText,
      'invoiceTermsText': invoiceTermsText,
      'isInterState': isInterState,
      'isCompositionScheme': isCompositionScheme,
      'drugLicenseNumber': drugLicenseNumber,
      'showGstinOnInvoice': showGstinOnInvoice,
      'showCustomerPhoneOnInvoice': showCustomerPhoneOnInvoice,
      'showWatermarkOnInvoice': showWatermarkOnInvoice,
      'enableAdvancePayment': enableAdvancePayment,
      'upiId': upiId,
      'gpayNumber': gpayNumber,
      'showGpayOnInvoice': showGpayOnInvoice,
      'tableCount': tableCount,
      'tableLabels': tableLabels,
      'notifLowStock': notifLowStock,
      'notifExpiry': notifExpiry,
      'notifCreditDue': notifCreditDue,
      'notifCreditDueDays': notifCreditDueDays,
      'notifRecurringExpense': notifRecurringExpense,
      'notifEodReminder': notifEodReminder,
      'notifEodHour': notifEodHour,
      'notifEodMinute': notifEodMinute,
      'appThemeMode': appThemeMode.name,
      'minBuildNumber': minBuildNumber,
    };
  }

  factory BusinessConfig.fromJson(Map<String, dynamic> json) {
    return BusinessConfig(
      businessName: json['businessName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      logoBase64: json['logoBase64'] as String?,
      gstEnabled: json['gstEnabled'] as bool? ?? false,
      gstin: json['gstin'] as String?,
      setupCompleted: json['setupCompleted'] as bool? ?? false,
      billPrefix: json['billPrefix'] as String? ?? 'INV',
      businessType: _businessTypeFromString(json['businessType'] as String?),
      defaultInvoicePageSize: _invoicePageSizeFromString(
        json['defaultInvoicePageSize'] as String?,
      ),
      defaultWhatsappFormat: _invoiceShareFormatFromString(
        json['defaultWhatsappFormat'] as String?,
      ),
      invoiceFooterText:
          json['invoiceFooterText'] as String? ??
          'Thank you for your business!',
      invoiceTermsText: json['invoiceTermsText'] as String? ?? '',
      isInterState: json['isInterState'] as bool? ?? false,
      isCompositionScheme: json['isCompositionScheme'] as bool? ?? false,
      drugLicenseNumber: json['drugLicenseNumber'] as String?,
      showGstinOnInvoice: json['showGstinOnInvoice'] as bool? ?? true,
      showCustomerPhoneOnInvoice:
          json['showCustomerPhoneOnInvoice'] as bool? ?? true,
      showWatermarkOnInvoice: json['showWatermarkOnInvoice'] as bool? ?? true,
      enableAdvancePayment: json['enableAdvancePayment'] as bool? ?? false,
      upiId: json['upiId'] as String?,
      gpayNumber: json['gpayNumber'] as String?,
      showGpayOnInvoice: json['showGpayOnInvoice'] as bool? ?? false,
      tableCount: json['tableCount'] as int? ?? 10,
      tableLabels: (json['tableLabels'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      notifLowStock: json['notifLowStock'] as bool? ?? true,
      notifExpiry: json['notifExpiry'] as bool? ?? true,
      notifCreditDue: json['notifCreditDue'] as bool? ?? true,
      notifCreditDueDays: json['notifCreditDueDays'] as int? ?? 30,
      notifRecurringExpense: json['notifRecurringExpense'] as bool? ?? true,
      notifEodReminder: json['notifEodReminder'] as bool? ?? true,
      notifEodHour: json['notifEodHour'] as int? ?? 21,
      notifEodMinute: json['notifEodMinute'] as int? ?? 0,
      appThemeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == (json['appThemeMode'] as String?),
        orElse: () => AppThemeMode.system,
      ),
      minBuildNumber: json['minBuildNumber'] as int? ?? 0,
    );
  }

  static BusinessType _businessTypeFromString(String? value) {
    if (value == null) return BusinessType.general;
    for (final type in BusinessType.values) {
      if (type.name == value) return type;
    }
    return BusinessType.general;
  }

  static InvoicePageSize _invoicePageSizeFromString(String? value) {
    if (value == null) return InvoicePageSize.a5;
    for (final pageSize in InvoicePageSize.values) {
      if (pageSize.name == value) return pageSize;
    }
    return InvoicePageSize.a5;
  }

  static InvoiceShareFormat _invoiceShareFormatFromString(String? value) {
    if (value == null) return InvoiceShareFormat.text;
    for (final format in InvoiceShareFormat.values) {
      if (format.name == value) return format;
    }
    return InvoiceShareFormat.text;
  }
}
