class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'BillReady';
  static const String tagline = 'Simple billing for your shop';

  // Splash
  static const String splashTitle = appName;
  static const String splashSubtitle = tagline;

  // Setup
  static const String setupTitle = 'Set Up Your Shop';
  static const String businessNameLabel = 'Business Name';
  static const String businessNameHint = 'Enter your shop name';
  static const String businessNameRequired = 'Business name is required';
  static const String businessNameMinLength = 'Must be at least 2 characters';
  static const String phoneLabel = 'Phone Number';
  static const String phoneHint = 'Enter 10-digit phone number';
  static const String phoneRequired = 'Phone number is required';
  static const String phoneInvalid =
      'Please enter a valid 10-digit phone number';
  static const String gstRegistered = 'GST Registered?';
  static const String gstNumberLabel = 'GST Number';
  static const String gstNumberHint = '15-character GSTIN';
  static const String gstNumberRequired = 'GST number is required';
  static const String gstNumberInvalid =
      'Please enter a valid 15-character GSTIN';
  static const String loadSampleData = 'Load Sample Data?';
  static const String sampleDataLoaded =
      'Sample data loaded: products, 50 customers, and 100 invoices for the last 3 months.';
  static const String startBilling = 'Start Billing';

  static const String menu = 'Menu';

  // Dashboard
  static const String homeTitle = 'Home';
  static const String todaysSales = "Today's Sales";
  static const String billsToday = 'Bills Today';
  static const String outstandingCredit = 'Outstanding Credit';
  static const String lowStock = 'Low Stock';
  static const String recentBills = 'Recent Bills';
  static const String viewAll = 'View All';
  static const String noBillsYet = 'No bills yet';
  static const String noBillsDesc =
      'Create your first bill to see sales data here';
  static const String createBill = 'Create Bill';
  static const String expensesTitle = 'Expenses';
  static const String trackYourExpenses = 'Track your expenses';
  static const String todaysExpenses = "Today's Expenses";
  static const String expensesCount = 'Expense Count';

  // Create Bill
  static const String newBill = 'New Bill';
  static const String searchProducts = 'Search products...';
  static const String scanBarcode = 'Scan Barcode';
  static const String scanBarcodeDescription =
      'Point the camera at a product barcode to add it instantly.';
  static const String barcodeNotFound = 'No product found for this barcode';
  static const String productAddedByBarcode = 'Product added by barcode';
  static const String startAddingProducts = 'Start adding products';
  static const String startAddingProductsDesc =
      'Search for products above to add them to this bill';
  static const String subtotal = 'Subtotal';
  static const String discount = 'Discount';
  static const String addDiscount = 'Add Discount';
  static const String cgst = 'CGST';
  static const String sgst = 'SGST';
  static const String grandTotal = 'Grand Total';
  static const String proceedToPayment = 'Proceed to Payment';
  static const String discardBill = 'Discard this bill?';
  static const String discardAction = 'Discard';
  static const String keepEditing = 'Keep Editing';
  static const String noProductsFound = 'No products found';

  // Payment
  static const String payment = 'Payment';
  static const String cash = 'Cash';
  static const String creditUdhar = 'Credit (Udhar)';
  static const String amountReceived = 'Amount Received';
  static const String change = 'Change';
  static const String customer = 'Customer';
  static const String selectCustomer = 'Select or search customer';
  static const String fullCredit = 'Full Credit';
  static const String partialPayment = 'Partial Payment';
  static const String amountPaidNow = 'Amount Paid Now';
  static const String creditAmount = 'Credit Amount';
  static const String completeBill = 'Complete Bill';
  static const String amountMinError = 'Amount must be at least';
  static const String customerRequired =
      'Customer is required for credit bills';
  static const String amountGreaterThanZero = 'Amount must be greater than 0';
  static const String amountCannotExceedTotal = 'Amount cannot exceed total';
  static const String amountCannotExceedOutstanding =
      'Amount cannot exceed outstanding';

  // Bill Done
  static const String billCreated = 'Bill Created!';
  static const String newBillAction = 'New Bill';
  static const String goHome = 'Go Home';

  // Products
  static const String productsTitle = 'Products';
  static const String addProduct = 'Add Product';
  static const String editProduct = 'Edit Product';
  static const String productNameLabel = 'Product Name';
  static const String productNameHint = 'Enter product name';
  static const String productNameRequired = 'Product name is required';
  static const String productNameMinLength =
      'Product name must be at least 2 characters';
  static const String productNameDuplicate =
      'A product with this name already exists';
  static const String barcodeLabel = 'Barcode';
  static const String barcodeHint = 'Enter barcode number';
  static const String barcodeDuplicate =
      'A product with this barcode already exists';
  static const String enterBarcode = 'Enter Barcode';
  static const String enterBarcodeManually = 'Enter barcode manually';
  static const String useBarcode = 'Use Barcode';
  static const String sellingPriceLabel = 'Selling Price';
  static const String sellingPriceRequired = 'Selling price is required';
  static const String sellingPricePositive = 'Price must be greater than 0';
  static const String stockQuantityLabel = 'Stock Quantity';
  static const String stockNegative = 'Stock quantity cannot be negative';
  static const String categoryLabel = 'Category';
  static const String selectCategory = 'Select category';
  static const String unitLabel = 'Unit';
  static const String selectUnit = 'Select unit';
  static const String gstSlabLabel = 'GST Slab';
  static const String selectGstSlab = 'Select GST rate';
  static const String save = 'Save';
  static const String saveChanges = 'Save Changes';
  static const String deleteProduct = 'Delete Product';
  static const String productSaved = 'Product saved';
  static const String productUpdated = 'Product updated';
  static const String productDeleted = 'Product deleted';
  static const String noProductsYet = 'No products yet';
  static const String noProductsDesc =
      'Add your first product to start billing';
  static const String noSearchResults = 'No products found';
  static const String noSearchResultsDesc = 'Try a different search term';
  static const String importProductsCsv = 'Import Products (CSV)';
  static const String all = 'All';
  static const String lowStockFilter = 'Low Stock';
  static const String outOfStockFilter = 'Out of Stock';
  static const String outOfStock = 'Out of Stock';
  static const String discardChanges = 'Discard changes?';
  static const String deleteConfirm = 'This cannot be undone.';

  // CSV Import
  static const String importProducts = 'Import Products';
  static const String importDesc =
      'Download the template, fill in your products, then upload the file to import them.';
  static const String downloadTemplate = 'Download Template';
  static const String selectCsvFile = 'Select CSV File';
  static const String previewImport = 'Preview Import';
  static const String importComplete = 'Import Complete';
  static const String productsImported = 'products imported!';
  static const String rowsSkipped = 'rows were skipped due to errors.';
  static const String viewProducts = 'View Products';
  static const String invalidCsvFormat =
      'Invalid CSV format. Please use the provided template.';
  static const String csvFileTooLarge =
      'File too large. Maximum allowed size is 1 MB.';

  // Customers
  static const String customersTitle = 'Customers';
  static const String noCustomersYet = 'No customers yet';
  static const String noCustomersDesc =
      'Customers will appear here when you create credit bills';
  static const String customerName = 'Customer Name';
  static const String customerPhone = 'Phone Number';
  static const String addCustomer = 'Add Customer';
  static const String editCustomer = 'Edit Customer';
  static const String deleteCustomer = 'Delete Customer';
  static const String deleteCustomerConfirm =
      'This customer will be permanently removed. This cannot be undone.';
  static const String customerUpdated = 'Customer updated';
  static const String customerDeleted = 'Customer deleted';
  static const String cannotDeleteWithBalance =
      'Cannot delete customer with outstanding balance';
  static const String customerNameRequired = 'Customer name is required';
  static const String customerNameMinLength =
      'Name must be at least 2 characters';
  static const String customerNameDuplicate =
      'A customer with this name already exists';
  static const String recordPayment = 'Record Payment';
  static const String creditHistory = 'Credit History';

  // Bill History
  static const String billHistoryTitle = 'Bill History';
  static const String searchBills = 'Search by bill # or customer...';
  static const String today = 'Today';
  static const String thisWeek = 'This Week';
  static const String thisMonth = 'This Month';
  static const String noBillsFound = 'No bills found';
  static const String noBillsFoundDesc = 'Try a different search or filter';
  static const String billDetails = 'Bill Details';
  static const String qty = 'Qty';
  static const String price = 'Price';
  static const String credit = 'Credit';

  // Expenses
  static const String noExpensesYet = 'No expenses recorded yet';
  static const String noExpensesDesc = 'Tap + to add your first expense';
  static const String noExpensesFound = 'No expenses found';
  static const String noExpensesFoundDesc = 'Try a different search or filter';
  static const String searchExpenses = 'Search description or vendor...';
  static const String addExpense = 'Add Expense';
  static const String editExpense = 'Edit Expense';
  static const String amountLabel = 'Amount';
  static const String amountHint = 'Enter amount';
  static const String amountRequired = 'Amount is required';
  static const String categoryRequired = 'Category is required';
  static const String dateLabel = 'Date';
  static const String vendorNameLabel = 'Vendor Name';
  static const String vendorNameHint = 'e.g. EB Office, ABC Suppliers';
  static const String descriptionLabel = 'Description';
  static const String descriptionHint = 'e.g. Electricity bill for March';
  static const String paymentModeLabel = 'Payment Mode';
  static const String recurringExpense = 'Recurring expense';
  static const String recurringFrequencyLabel = 'Recurring Frequency';
  static const String saveExpense = 'Save Expense';
  static const String updateExpense = 'Update Expense';
  static const String expenseAdded = 'Expense added';
  static const String expenseUpdated = 'Expense updated';
  static const String expenseDeleted = 'Expense deleted';
  static const String deleteExpense = 'Delete Expense';
  static const String deleteExpenseConfirm =
      'This expense will be permanently removed.';
  static const String receiptComingSoon = 'Receipt photo support coming soon';
  static const String addReceipt = 'Add Receipt';
  static const String allExpensesFilter = 'All';
  static const String todayFilter = 'Today';
  static const String thisWeekFilter = 'This Week';
  static const String thisMonthFilter = 'This Month';
  static const String customRangeFilter = 'Custom Range';
  static const String clearFilters = 'Clear Filters';
  static const String fromLabel = 'From';
  static const String toLabel = 'To';
  static const String byCategory = 'By Category';
  static const String byPaymentMode = 'Payment Mode';
  static const String allPaymentModes = 'All Modes';
  static const String upi = 'UPI';
  static const String bankTransfer = 'Bank Transfer';
  static const String monthlyTotal = 'This Month';
  static const String pickDateRange = 'Pick Date Range';
  static const String customCategoryName = 'Custom Category Name';
  static const String customCategoryHint = 'e.g. Cleaning';
  static const String customCategoryNameRequired =
      'Custom category name is required';
  static const String cashInHandComparison = 'Expenses vs Sales';
  static const String recurringDaily = 'Daily';
  static const String recurringWeekly = 'Weekly';
  static const String recurringMonthly = 'Monthly';
  static const String recurringYearly = 'Yearly';
  static const String autoCreateExpense = 'Create automatically';
  static const String autoCreateDesc =
      'Auto-create expense on due date when app opens';
  static const String remindOnly = 'Remind me only';
  static const String nextDueLabel = 'Next due';
  static const String recurringDueThisWeek = 'recurring expenses due this week';
  static const String autoCreatedExpenses = 'recurring expenses auto-created';

  // Cash Book
  static const String cashBookTitle = 'Cash Book';
  static const String openingBalance = 'Opening Balance';
  static const String cashSales = 'Cash Sales';
  static const String cashReceived = 'Cash Received';
  static const String otherCashIn = 'Other Cash In';
  static const String cashExpenses = 'Cash Expenses';
  static const String supplierPayments = 'Supplier Payments';
  static const String otherCashOut = 'Other Cash Out';
  static const String closingBalance = 'Closing Balance';
  static const String dayNotes = 'Day Notes';
  static const String addCashIn = 'Add Cash In';
  static const String addCashOut = 'Add Cash Out';
  static const String closeDay = 'Close Day';
  static const String reopenDay = 'Reopen Day';
  static const String dayClosed = 'Day Closed';
  static const String dayClosedBadge = 'Day Closed ✓';
  static const String physicalCashCount = 'Physical Cash Count';
  static const String physicalCashCountHint = 'Enter the actual cash in hand';
  static const String cashDiscrepancy = 'Discrepancy';
  static const String recordPhysicalCount = 'Record Count';
  static const String noDiscrepancy = 'No discrepancy';
  static const String closeDayConfirmTitle = 'Close this day?';
  static const String closeDayConfirmDesc =
      'You can reopen only if the next day is not closed.';
  static const String dayClosedSuccess = 'Day closed successfully';
  static const String dayReopenedSuccess = 'Day reopened';
  static const String cannotReopenDay =
      'Cannot reopen. Next day is already closed.';
  static const String pendingDaysWarning = 'Previous days are still open';
  static const String pendingDaysCountSuffix = 'days pending closure';
  static const String addCashEntry = 'Add Cash Entry';
  static const String editCashEntry = 'Edit Cash Entry';
  static const String entryType = 'Entry Type';
  static const String entryDescription = 'Description';
  static const String entryDescriptionHint = 'e.g. Owner investment';
  static const String entryDescriptionRequired = 'Description is required';
  static const String cashEntrySaved = 'Cash entry saved';
  static const String cashEntryUpdated = 'Cash entry updated';
  static const String cashEntryDeleted = 'Cash entry deleted';
  static const String deleteCashEntry = 'Delete Cash Entry';
  static const String deleteCashEntryConfirm = 'This entry will be removed.';
  static const String monthlyView = 'Monthly View';
  static const String monthSummary = 'Month Summary';
  static const String totalInflows = 'Total Inflows';
  static const String totalOutflows = 'Total Outflows';
  static const String netCashFlow = 'Net Cash Flow';
  static const String setOpeningBalance = 'Set Opening Balance';
  static const String openingBalanceRequired = 'Opening balance is required';
  static const String openingBalanceUpdated = 'Opening balance updated';
  static const String cashInHand = 'Cash in Hand';
  static const String yesterdayClose = 'Yesterday Close';
  static const String optionalNotesHint = 'Optional notes...';

  // Expense categories
  static const String expenseCategoryRent = 'Rent';
  static const String expenseCategoryElectricity = 'Electricity';
  static const String expenseCategorySalary = 'Salary';
  static const String expenseCategoryTransport = 'Transport';
  static const String expenseCategoryRawMaterial = 'Raw Material';
  static const String expenseCategoryMaintenance = 'Maintenance';
  static const String expenseCategoryPackaging = 'Packaging';
  static const String expenseCategoryTelephone = 'Telephone/Internet';
  static const String expenseCategoryMarketing = 'Marketing';
  static const String expenseCategoryTaxes = 'Taxes';
  static const String expenseCategoryInsurance = 'Insurance';
  static const String expenseCategoryEquipment = 'Equipment';
  static const String expenseCategoryFoodBeverage = 'Food & Beverage';
  static const String expenseCategoryMiscellaneous = 'Miscellaneous';
  static const String expenseCategoryProfessionalFees = 'Professional Fees';
  static const String expenseCategoryLoan = 'Loan/EMI';
  static const String expenseCategoryCustom = 'Custom';

  // Settings
  static const String settingsTitle = 'Settings';
  static const String businessProfileSection = 'Business Profile';
  static const String taxSettingsSection = 'Tax Settings';
  static const String billSettingsSection = 'Bill Settings';
  static const String appInfoSection = 'App Info';
  static const String dataSection = 'Data';
  static const String billPrefixLabel = 'Bill Prefix';
  static const String billPrefixHint = 'e.g. INV, BILL, REC';
  static const String billPrefixRequired = 'Bill prefix is required';
  static const String settingsSaved = 'Settings saved successfully';
  static const String saveSettings = 'Save Settings';
  static const String logoutAndLoadSampleData = 'Logout & Load Sample Data';
  static const String logoutAndLoadSampleDataDesc =
      'Clears bills, customers, expenses, and cash book before returning to setup with sample products.';
  static const String logoutAndLoadSampleDataConfirm =
      'This will erase current session data and take you back to setup.';
  static const String logoutAction = 'Logout';
  static const String usersAccessTitle = 'Users & Access';
  static const String manageUsers = 'Manage Users';
  static const String enableUserManagement = 'Enable User Management';
  static const String enableUserManagementDesc =
      'Create an owner account to enable role-based access and PIN login.';
  static const String createOwnerAccount = 'Create Owner Account';
  static const String requirePinOnOpen = 'Require PIN on app open';
  static const String autoLockTimeout = 'Auto-lock timeout';
  static const String never = 'Never';
  static const String version = 'Version';
  static const String invoiceSharingSection = 'Invoice & Sharing';
  static const String invoiceFooterLabel = 'Invoice Footer';
  static const String invoiceFooterHint = 'e.g. Thank you for your business!';
  static const String invoiceTermsLabel = 'Terms & Conditions';
  static const String invoiceTermsHint =
      'Optional terms shown in shared invoice text';
  static const String showGstinOnInvoice = 'Show GSTIN on invoice';
  static const String showCustomerPhoneOnInvoice =
      'Show customer phone on invoice';
  static const String defaultWhatsAppFormat = 'Default WhatsApp Format';
  static const String whatsappFormatText = 'Text Only';
  static const String whatsappFormatPdf = 'PDF Attachment';
  static const String whatsappFormatImage = 'Image';
  static const String defaultInvoicePageSize = 'Default Invoice Size';
  static const String invoicePageSizeA5 = 'PDF A5';
  static const String invoicePageSizeA4 = 'PDF A4';
  static const String invoiceActions = 'Invoice Actions';
  static const String shareWhatsApp = 'WhatsApp';
  static const String shareSystem = 'Share';
  static const String copyInvoice = 'Copy';
  static const String print = 'Print';
  static const String pdf = 'PDF';
  static const String image = 'Image';
  static const String invoiceCopied = 'Invoice text copied';
  static const String whatsappNotAvailable =
      'Unable to open WhatsApp. Please check installation.';
  static const String featureComingSoon = 'This option is coming soon';
  static const String invoiceActionFailed =
      'Unable to process invoice action. Please try again.';
  static const String printUnavailableSharedPdf =
      'Print unavailable. Shared PDF instead.';

  // User Management
  static const String userLoginTitle = 'User Login';
  static const String userMenu = 'User Menu';
  static const String selectUser = 'Select user';
  static const String enterPin = 'Enter 4-digit PIN';
  static const String enterPinFor = 'Enter PIN for';
  static const String tapAUserToContinue = 'Tap a user to continue';
  static const String forgotPinHelp = 'Forgot PIN? Ask owner to reset.';
  static const String switchUser = 'Switch User';
  static const String lockApp = 'Lock App';
  static const String wrongPin = 'Wrong PIN';
  static const String tooManyAttempts = 'Too many attempts. Try again shortly.';
  static const String tryAgainIn = 'Try again in';
  static const String secondsSuffix = 'seconds';
  static const String noUsersConfigured = 'No users configured';
  static const String singleUserModeActive = 'Single-user mode is active.';
  static const String backToApp = 'Back to App';
  static const String loginRequired = 'Login required to continue';
  static const String accessDenied = 'Access Denied';
  static const String ownerOnlyAction = 'Only owner can perform this action';
  static const String addUser = 'Add User';
  static const String editUser = 'Edit User';
  static const String updateUser = 'Update User';
  static const String role = 'Role';
  static const String pin = 'PIN';
  static const String confirmPin = 'Confirm PIN';
  static const String newPinOptional = 'New PIN (optional)';
  static const String pinInvalid = 'PIN must be 4 digits';
  static const String pinMismatch = 'PIN confirmation does not match';
  static const String name = 'Name';
  static const String nameMinLength = 'Name must be at least 2 characters';
  static const String phoneAlreadyUsed =
      'Phone is already used by another user';
  static const String userSaved = 'User saved';
  static const String userSaveFailed = 'Unable to save user';
  static const String activeUser = 'Active User';
  static const String primaryUser = 'Primary';
  static const String deactivateUser = 'Deactivate User';
  static const String reactivateUser = 'Reactivate User';
  static const String deactivateUserConfirm =
      'This user will not be able to login until reactivated.';
  static const String reactivateUserConfirm =
      'This user will be able to login again.';
  static const String addFirstUserHint =
      'Add a user to start role-based access control.';

  // Pharmacy / Batch
  static const String businessTypeLabel = 'Business Type';
  static const String businessTypeGeneral = 'General Store';
  static const String businessTypePharmacy = 'Pharmacy';
  static const String batchNumber = 'Batch Number';
  static const String batchNumberHint = 'e.g. BN-2025-001';
  static const String batchNumberRequired = 'Batch number is required';
  static const String expiryDate = 'Expiry Date';
  static const String expiryDateRequired = 'Expiry date is required';
  static const String expiryDatePast = 'Expiry date cannot be in the past';
  static const String addBatch = 'Add Batch';
  static const String editBatch = 'Edit Batch';
  static const String deleteBatch = 'Delete Batch';
  static const String batches = 'Batches';
  static const String noBatches = 'No batches';
  static const String noBatchesDesc =
      'Add a batch with stock and expiry information';
  static const String batchAdded = 'Batch added';
  static const String batchUpdated = 'Batch updated';
  static const String batchDeleted = 'Batch deleted';
  static const String expiringSoon = 'Expiring Soon';
  static const String expired = 'Expired';
  static const String fefoApplied = 'FEFO: Nearest expiry batch selected';

  // Clinic
  static const String businessTypeClinic = 'Clinic';
  static const String businessTypeJewellery = 'Jewellery Shop';
  static const String patient = 'Patient';
  static const String ageLabel = 'Age';
  static const String ageHint = 'Enter age';
  static const String genderLabel = 'Gender';
  static const String selectGender = 'Select gender';
  static const String bloodGroupLabel = 'Blood Group';
  static const String selectBloodGroup = 'Select blood group';
  static const String allergiesLabel = 'Allergies';
  static const String allergiesHint = 'e.g. Penicillin, Dust';
  static const String medicalNotesLabel = 'Medical Notes';
  static const String medicalNotesHint = 'Any medical conditions or notes';
  static const String diagnosisLabel = 'Diagnosis';
  static const String diagnosisHint = 'Enter diagnosis';
  static const String visitNotesLabel = 'Visit Notes';
  static const String visitNotesHint = 'Enter visit notes';
  static const String patientInfo = 'Patient Info';
  static const String visitNotesSection = 'Visit Notes';

  // Salon
  static const String businessTypeSalon = 'Salon';
  static const String serviceToggleLabel = 'This is a service';
  static const String serviceFee = 'Service Fee';
  static const String durationLabel = 'Duration (minutes)';
  static const String durationHint = 'e.g. 30';
  static const String durationMinutes = 'min';
  static const String services = 'Services';
  static const String noServices = 'No services yet';
  static const String noServicesDesc =
      'Add your first service to start billing';
  static const String serviceAdded = 'Service saved';
  static const String serviceUpdated = 'Service updated';
  static const String lowStockThresholdLabel = 'Low Stock Threshold';

  // GST
  static const String igst = 'IGST';
  static const String hsnCodeLabel = 'HSN/SAC Code';
  static const String hsnCodeHint = 'e.g. 30049099';
  static const String gstInclusiveLabel = 'Price includes GST';
  static const String interStateSupply = 'Inter-state supply (IGST)';
  static const String compositionScheme = 'Composition Scheme';
  static const String drugLicenseLabel = 'Drug License Number';
  static const String drugLicenseHint = 'e.g. DL-20B-12345';
  static const String billOfSupply = 'Bill of Supply';
  static const String taxInvoice = 'Tax Invoice';
  static const String customerGstinLabel = 'Customer GSTIN';
  static const String customerGstinHint = '15-character GSTIN (B2B)';
  static const String gstr1Export = 'GSTR-1 Export';
  static const String gstr1ExportDesc =
      'Export monthly sales data in GSTR-1 format for GST portal upload.';
  static const String selectMonth = 'Select Month';
  static const String exportCsv = 'Export CSV';
  static const String totalTaxableValue = 'Total Taxable Value';
  static const String totalCgst = 'Total CGST';
  static const String totalSgst = 'Total SGST';
  static const String totalIgst = 'Total IGST';
  static const String totalBills = 'Total Bills';
  static const String noBillsInPeriod = 'No bills in selected period';
  static const String csvExported = 'GSTR-1 CSV exported';
  static const String csvExportFailed = 'Failed to export CSV';
  static const String exportBackup = 'Export Data Backup';
  static const String exportBackupDesc = 'Download a full JSON backup of all your business data';
  static const String exportBackupDone = 'Backup exported';
  static const String exportBackupFailed = 'Failed to export backup';

  // UOM
  static const String customUomLabel = 'Custom Unit Name';
  static const String customUomHint = 'e.g. plate, strip, tube';
  static const String customUomRequired = 'Custom unit name is required';
  static const String minQuantityLabel = 'Minimum Quantity';
  static const String minQuantityHint = 'e.g. 0.25, 0.5, 1';
  static const String quantityStepLabel = 'Quantity Step';
  static const String quantityStepHint = 'Increment per tap';

  // Customer Visit History
  static const String visitHistory = 'Visit History';
  static const String allVisits = 'All Visits';
  static const String totalVisits = 'Visits';
  static const String totalSpent = 'Total Spent';
  static const String lastVisit = 'Last Visit';
  static const String noVisits = 'No visits yet';
  static const String favouriteService = 'Favourite';
  static const String servicesAvailed = 'Services';
  static const String productsLabel = 'Products';

  // Suppliers
  static const String suppliersTitle = 'Suppliers';
  static const String addSupplier = 'Add Supplier';
  static const String editSupplier = 'Edit Supplier';
  static const String noSuppliersYet = 'No suppliers yet';
  static const String noSuppliersDesc =
      'Add your first supplier to manage purchases';
  static const String searchSuppliers = 'Search suppliers...';
  static const String searchQuotations = 'Search by number or customer...';
  static const String searchJobCards = 'Search by vehicle, job no. or customer...';
  static const String supplierNameLabel = 'Supplier Name';
  static const String supplierNameRequired = 'Supplier name is required';
  static const String supplierNameMinLength =
      'Name must be at least 2 characters';
  static const String supplierGstinLabel = 'Supplier GSTIN';
  static const String supplierGstinHint = '15-character GSTIN';
  static const String supplierAddressLabel = 'Address';
  static const String supplierAddressHint = 'Enter supplier address';
  static const String supplierCategoriesLabel = 'Product Categories';
  static const String supplierCategoriesHint = 'e.g. Rice, Medicines';
  static const String supplierNotesLabel = 'Notes';
  static const String supplierNotesHint = 'Any notes about this supplier';
  static const String supplierAdded = 'Supplier added';
  static const String supplierUpdated = 'Supplier updated';
  static const String supplierDeactivated = 'Supplier deactivated';
  static const String payable = 'payable';
  static const String noDues = 'No dues';
  static const String outstandingPayable = 'Outstanding Payable';
  static const String deactivateSupplier = 'Deactivate Supplier';
  static const String deactivateSupplierConfirm =
      'This supplier will be hidden from the active list.';
  static const String recordSupplierPayment = 'Record Payment to Supplier';
  static const String supplierPaymentRecorded = 'Supplier payment recorded';
  static const String purchaseHistoryComingSoon =
      'Purchase history will appear here';

  // Purchases
  static const String purchasesTitle = 'Purchases';
  static const String addPurchase = 'Add Purchase';
  static const String noPurchasesYet = 'No purchases yet';
  static const String noPurchasesDesc = 'Tap + to record your first purchase';
  static const String todaysPurchases = "Today's Purchases";
  static const String thisMonthPurchases = 'This Month';
  static const String noPurchasesFound = 'No purchases found';
  static const String adHocPurchase = 'Ad-hoc Purchase';
  static const String invoiceNumberLabel = 'Invoice Number';
  static const String invoiceNumberHint = 'Supplier invoice #';
  static const String purchaseItems = 'Purchase Items';
  static const String addProductsToPurchase = 'Search to add products';
  static const String purchasePriceLabel = 'Price';
  static const String savePurchase = 'Save Purchase';
  static const String purchaseAdded = 'Purchase recorded';
  static const String addAtLeastOneItem = 'Add at least one item';
  static const String purchaseItemsIncomplete = 'Fill qty & price for all items';
  static const String selectSupplier = 'Select Supplier';
  static const String supplierNameHint = 'e.g. ABC Traders';
  static const String purchaseHistory = 'Purchase History';
  static const String avgCostPrice = 'Avg Cost';
  static const String lastPurchasePrice = 'Last Price';
  static const String noPurchaseHistory = 'No purchase history for this product';

  // Stock Adjustment
  static const String adjustStock = 'Adjust Stock';
  static const String currentStock = 'Current Stock';
  static const String newStockLabel = 'New Stock Quantity';
  static const String adjustmentReasonLabel = 'Reason';
  static const String saveAdjustment = 'Save Adjustment';
  static const String stockAdjusted = 'Stock adjusted';
  static const String noChange = 'No change';
  static const String willBeAdded = 'will be added';
  static const String willBeRemoved = 'will be removed';
  static const String adjustmentHistory = 'Recent Adjustments';

  // Reorder
  static const String reorderRequired = 'Reorder Required';
  static const String reorderLevelLabel = 'Reorder Level';
  static const String reorderLevelHint = 'Stock threshold for alert';
  static const String reorderQuantityLabel = 'Reorder Quantity';
  static const String reorderQuantityHint = 'How much to order';
  static const String preferredSupplierLabel = 'Preferred Supplier';
  static const String selectPreferredSupplier = 'Select supplier';
  static const String noReorderItems = 'All stocked up!';
  static const String noReorderItemsDesc =
      'No products are below their reorder level';
  static const String generateMessage = 'Generate Supplier Message';
  static const String createPurchaseFromReorder = 'Create Purchase';
  static const String reorderCount = 'Reorder';
  static const String messageCopied = 'Message copied to clipboard';
  static const String selectItemsFirst = 'Select at least one item';
  static const String stockReorderRequest = 'Stock Reorder Request';
  static const String pleaseConfirmAvailability =
      'Please confirm availability.';

  // Discounts
  static const String defaultDiscountLabel = 'Default Discount %';
  static const String defaultDiscountHint = 'e.g. 5, 10';
  static const String lineDiscountLabel = 'Line Discount';
  static const String editDiscount = 'Edit Discount';
  static const String addLineDiscount = 'Add Discount';
  static const String discountGivenToday = 'Discounts Today';
  static const String customerDiscountApplied = 'discount applied';

  // Returns / Refunds
  static const String returnItems = 'Return Items';
  static const String returnCreated = 'Return processed';
  static const String returnNumber = 'Return #';
  static const String creditNoteTitle = 'Credit Note';
  static const String originalBill = 'Original Bill';
  static const String refundMode = 'Refund Mode';
  static const String refundCash = 'Cash Refund';
  static const String refundCredit = 'Add to Credit';
  static const String refundExchange = 'Exchange';
  static const String returnReason = 'Reason for Return';
  static const String returnReasonHint = 'e.g. Defective, Wrong item';
  static const String returnQty = 'Return Qty';
  static const String maxQty = 'Max';
  static const String totalRefund = 'Total Refund';
  static const String processReturn = 'Process Return';
  static const String selectReturnItems = 'Select items to return';
  static const String returnMade = 'Return Made';
  static const String noItemsSelected = 'Select at least one item to return';
  static const String qtyExceedsMax = 'Quantity exceeds maximum returnable';
  static const String todaysReturns = "Today's Returns";

  // Credit Settlement
  static const String paymentHistory = 'Payment History';
  static const String customerLedger = 'Ledger';
  static const String noPaymentsYet = 'No payments recorded yet';
  static const String againstBill = 'Against Bill';
  static const String selectBill = 'Select Bill (Optional)';
  static const String generalPayment = 'General Payment';
  static const String paymentNotes = 'Notes';
  static const String paymentNotesHint = 'e.g. Partial payment, cheque #123';
  static const String balanceBefore = 'Balance Before';
  static const String balanceAfter = 'Balance After';
  static const String settlementReceipt = 'Settlement Receipt';
  static const String shareReceipt = 'Share Receipt';
  static const String totalPaid = 'Total Paid';
  static const String runningBalance = 'Balance';
  static const String billEntry = 'Bill';
  static const String paymentEntry = 'Payment';

  // EOD Summary
  static const String eodTitle = 'Day Summary';
  static const String eodSalesSection = 'Sales';
  static const String eodTotalBills = 'Total Bills';
  static const String eodCashCollected = 'Cash Collected';
  static const String eodUpiCollected = 'UPI Collected';
  static const String eodCreditGiven = 'Credit Given';
  static const String eodTotalRevenue = 'Total Revenue';
  static const String eodTopProducts = 'Top Products';
  static const String eodExpensesSection = 'Expenses';
  static const String eodPurchasesSection = 'Purchases';
  static const String eodReturnsSection = 'Returns';
  static const String eodNetProfit = 'Net Profit';
  static const String eodCashInHand = 'Cash in Hand';
  static const String eodOpeningBalance = 'Opening';
  static const String eodClosingBalance = 'Closing';
  static const String eodShareSummary = 'Share Summary';
  static const String eodCloseCashBook = 'Close Cash Book for Today';
  static const String eodViewDaySummary = 'View Day Summary';
  static const String eodNudge = 'Ready to close the day?';
  static const String eodNoSales = 'No sales today';
  static const String eodBillsSuffix = 'bills';
  static const String eodToCustomers = 'to';
  static const String eodCustomersSuffix = 'customers';
  static const String eodDiscounts = 'Discounts Given';

  // Notifications
  static const String notificationsSection = 'Notifications';
  static const String notifLowStock = 'Low Stock Alerts';
  static const String notifLowStockDesc = 'When product stock falls below reorder level';
  static const String notifExpiry = 'Expiry Alerts';
  static const String notifExpiryDesc = 'Alerts at 30, 15, and 7 days before batch expiry';
  static const String notifCreditDue = 'Credit Due Alerts';
  static const String notifCreditDueDesc = 'When customer credit is outstanding';
  static const String notifCreditDaysLabel = 'After days';
  static const String notifRecurringExpense = 'Recurring Expense Reminders';
  static const String notifRecurringExpenseDesc = 'Reminder 2 days before due';
  static const String notifEodReminder = 'EOD Reminder';
  static const String notifEodReminderDesc = 'Reminder to close cash book';
  static const String notifEodTimeLabel = 'Reminder Time';
  static const String notifLowStockTitle = 'Low Stock Alert';
  static const String notifExpiryTitle = 'Expiry Alert';
  static const String notifCreditDueTitle = 'Credit Due';
  static const String notifRecurringTitle = 'Recurring Expense Due';
  static const String notifEodTitle = 'Close Your Day';
  static const String notifEodBody = "Haven't closed today's cash book yet";
  static const String notifLowStockBody = 'is running low';
  static const String notifExpiryBody = 'expires in';
  static const String notifDays = 'days';
  static const String notifCreditBody = 'credit outstanding for';
  static const String notifRecurringBody = 'due in 2 days';

  // Quotations
  static const String quotationsTitle = 'Quotations';
  static const String newQuotation = 'New Quotation';
  static const String editQuotation = 'Edit Quotation';
  static const String quotationDetails = 'Quotation Details';
  static const String quotationNumber = 'Quotation #';
  static const String validUntil = 'Valid Until';
  static const String quotationNotes = 'Notes';
  static const String quotationNotesHint = 'Add terms or notes...';
  static const String createQuotation = 'Create Quotation';
  static const String convertToBill = 'Convert to Bill';
  static const String convertToBillConfirm =
      'This will create a new bill from this quotation. Proceed?';
  static const String quotationConverted = 'Quotation converted to bill';
  static const String markAsSent = 'Mark as Sent';
  static const String markAsApproved = 'Mark as Approved';
  static const String markAsRejected = 'Mark as Rejected';
  static const String deleteQuotation = 'Delete Quotation';
  static const String deleteQuotationConfirm =
      'Are you sure you want to delete this quotation?';
  static const String quotationDeleted = 'Quotation deleted';
  static const String quotationSaved = 'Quotation saved';
  static const String noQuotations = 'No quotations yet';
  static const String noQuotationsDesc =
      'Create a quotation to get started';
  static const String filterAll = 'All';
  static const String filterActive = 'Active';
  static const String filterSent = 'Sent';
  static const String filterApproved = 'Approved';
  static const String filterExpired = 'Expired';
  static const String estimate = 'ESTIMATE';
  static const String quotationStatusUpdated = 'Status updated';

  // Reports
  static const String reportsTitle = 'Reports';
  static const String reportRevenue = 'Revenue';
  static const String reportCogs = 'Cost of Goods (Purchases)';
  static const String reportGrossProfit = 'Gross Profit';
  static const String reportExpenses = 'Expenses';
  static const String reportNetProfit = 'Net Profit';
  static const String reportMonthlyTrend = 'Monthly Trend';
  static const String reportByPaymentMode = 'By Payment Mode';
  static const String reportDailyTrend = 'Daily Trend';
  static const String reportTopProducts = 'Top 10 Products';
  static const String reportStockValue = 'Total Stock Value';
  static const String reportTotalSkus = 'Total SKUs';
  static const String reportDeadStock30 = 'Slow-Moving (30 days)';
  static const String reportDailyBalance = 'Daily Closing Balance';
  static const String reportByGstSlab = 'Line Items by GST Slab';

  // Restaurant
  static const String tablesTitle = 'Tables';
  static const String tableAvailable = 'Available';
  static const String tableOccupied = 'Occupied';
  static const String tableOrder = 'Table Order';
  static const String newOrder = 'New Order';
  static const String sendToKitchen = 'Send to Kitchen';
  static const String billThisTable = 'Bill This Table';
  static const String kitchenOrderTicket = 'Kitchen Order Ticket';
  static const String tableCountLabel = 'Number of Tables';
  static const String tableCountHint = 'e.g. 10';
  static const String businessTypeRestaurant = 'Restaurant';
  static const String orderItems = 'Order Items';
  static const String noItemsInOrder = 'No items added yet';
  static const String orderSent = 'Order sent to kitchen';
  static const String tableLabel = 'Table';

  // Workshop
  static const String jobsTitle = 'Jobs';
  static const String jobCardTitle = 'Job Card';
  static const String newJobCard = 'New Job Card';
  static const String vehicleReg = 'Vehicle Reg No.';
  static const String vehicleRegHint = 'e.g. TN01AB1234';
  static const String vehicleRegRequired = 'Vehicle registration is required';
  static const String vehicleMake = 'Make';
  static const String vehicleMakeHint = 'e.g. Honda, Bajaj';
  static const String vehicleModel = 'Model';
  static const String vehicleModelHint = 'e.g. Activa, Pulsar';
  static const String kmReading = 'KM Reading';
  static const String kmReadingHint = 'e.g. 12500';
  static const String problemDescription = 'Problem Description';
  static const String problemDescriptionHint = 'Describe the issue';
  static const String problemRequired = 'Problem description is required';
  static const String diagnosisJobLabel = 'Diagnosis / Notes';
  static const String diagnosisJobHint = 'Mechanic notes';
  static const String estimatedCost = 'Estimated Cost';
  static const String estimatedCostHint = 'Enter estimate';
  static const String partsTab = 'Parts';
  static const String labourTab = 'Labour';
  static const String addPart = 'Add Part';
  static const String addLabour = 'Add Labour';
  static const String notifyCustomer = 'Notify Customer';
  static const String generateBill = 'Generate Bill';
  static const String jobCardSaved = 'Job card saved';
  static const String jobCardUpdated = 'Job card updated';
  static const String jobNumber = 'Job #';
  static const String statusReceived = 'Received';
  static const String statusDiagnosed = 'Diagnosed';
  static const String statusInProgress = 'In Progress';
  static const String statusReady = 'Ready for Pickup';
  static const String statusDelivered = 'Delivered';
  static const String statusCancelled = 'Cancelled';
  static const String advanceStatus = 'Advance Status';
  static const String notifyWhatsApp = 'Notify via WhatsApp';
  static const String businessTypeWorkshop = 'Bike Workshop';
  static const String businessTypeMobileShop = 'Mobile Shop';
  // Mobile shop job card labels
  static const String deviceImei = 'IMEI / Serial No.';
  static const String deviceImeiHint = 'e.g. 358xxxxxxxxx';
  static const String deviceImeiRequired = 'IMEI / Serial No. is required';
  static const String deviceBrand = 'Brand';
  static const String deviceBrandHint = 'e.g. Samsung, Apple';
  static const String deviceStorage = 'Color / Storage';
  static const String deviceStorageHint = 'e.g. Black 128GB';
  static const String noJobCards = 'No job cards yet';
  static const String noJobCardsDesc = 'Tap + to create the first job card';
  static const String jobBillConverted = 'Job card converted to bill';

  // General
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String undo = 'Undo';
  static const String items = 'items';
  static const String rsPrefix = 'Rs.';
}
