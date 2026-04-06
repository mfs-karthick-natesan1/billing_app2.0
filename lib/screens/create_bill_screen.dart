import 'dart:io' show File;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/line_item.dart';
import '../models/product.dart';
import '../models/quotation.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/product_provider.dart';
import '../providers/quotation_provider.dart';
import '../providers/serial_number_provider.dart';
import '../services/barcode_scanner_service.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/bill_total_footer.dart';
import '../widgets/confirm_dialog.dart';
import '../models/customer.dart';
import '../widgets/customer_list_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/line_item_row.dart';
import '../widgets/search_bar_widget.dart';

class CreateBillScreen extends StatefulWidget {
  final BarcodeScannerService scannerService;
  final bool isQuotation;
  final bool showBack;

  const CreateBillScreen({
    super.key,
    this.scannerService = const MobileBarcodeScannerService(),
    this.isQuotation = false,
    this.showBack = false,
  });

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  bool _visitNotesExpanded = false;
  bool _imageMode = false;
  final _diagnosisController = TextEditingController();
  final _visitNotesController = TextEditingController();
  // Workshop quotation vehicle fields
  final _vehicleRegController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _kmReadingController = TextEditingController();
  // Quotation customer fields (new customer)
  final _newCustomerNameController = TextEditingController();
  final _newCustomerPhoneController = TextEditingController();
  bool _useNewCustomer = false;
  // Selected saved vehicle in workshop mode (null = new / manual)
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    final billProvider = context.read<BillProvider>();
    _diagnosisController.text = billProvider.activeDiagnosis ?? '';
    _visitNotesController.text = billProvider.activeVisitNotes ?? '';
    _vehicleRegController.text = billProvider.activeVehicleReg ?? '';
    _vehicleMakeController.text = billProvider.activeVehicleMake ?? '';
    _vehicleModelController.text = billProvider.activeVehicleModel ?? '';
    _kmReadingController.text = billProvider.activeKmReading ?? '';
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _visitNotesController.dispose();
    _vehicleRegController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _kmReadingController.dispose();
    _newCustomerNameController.dispose();
    _newCustomerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final productProvider = context.watch<ProductProvider>();
    final businessConfig = context.watch<BusinessConfigProvider>();
    final gstEnabled = businessConfig.gstEnabled;
    final isInterState = businessConfig.isInterState;
    final isClinic = businessConfig.isClinic;

    if ((billProvider.activeDiagnosis ?? '') != _diagnosisController.text) {
      _diagnosisController.text = billProvider.activeDiagnosis ?? '';
    }
    if ((billProvider.activeVisitNotes ?? '') != _visitNotesController.text) {
      _visitNotesController.text = billProvider.activeVisitNotes ?? '';
    }
    if (!billProvider.hasActiveItems && _visitNotesExpanded) {
      _visitNotesExpanded = false;
    }

    final isQuotation = widget.isQuotation;

    return PopScope(
      canPop: !billProvider.hasActiveItems,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await ConfirmDialog.show(
          context,
          title: AppStrings.discardBill,
          confirmLabel: AppStrings.discardAction,
          cancelLabel: AppStrings.keepEditing,
          isDestructive: true,
        );
        if (discard && context.mounted) {
          billProvider.clearActiveBill();
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppTopBar(
          title: isQuotation ? AppStrings.newQuotation : AppStrings.newBill,
          showBack: widget.showBack,
          actions: [
            if (_imageMode && billProvider.hasActiveItems)
              IconButton(
                onPressed: () async {
                  final confirm = await ConfirmDialog.show(
                    context,
                    title: 'Clear all items?',
                    confirmLabel: 'Clear',
                    cancelLabel: 'Cancel',
                    isDestructive: true,
                  );
                  if (confirm) billProvider.clearActiveBill();
                },
                icon: const Icon(Icons.clear_all, color: AppColors.muted),
                tooltip: 'Clear all',
              ),
            // For non-quotation bills: show customer chip/button in app bar
            if (!isQuotation) ...[
              if (billProvider.activeCustomer != null)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.small),
                  child: Chip(
                    label: Text(
                      billProvider.activeCustomer!.defaultDiscountPercent > 0
                          ? '${billProvider.activeCustomer!.name} (${billProvider.activeCustomer!.defaultDiscountPercent.toStringAsFixed(billProvider.activeCustomer!.defaultDiscountPercent == billProvider.activeCustomer!.defaultDiscountPercent.roundToDouble() ? 0 : 1)}%)'
                          : billProvider.activeCustomer!.name,
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    backgroundColor: AppColors.primaryLight(0.10),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => billProvider.setActiveCustomer(null),
                    side: BorderSide.none,
                  ),
                )
              else
                IconButton(
                  onPressed: () async {
                    final customer = await CustomerListSheet.show(context);
                    if (customer != null) {
                      billProvider.setActiveCustomer(customer);
                      setState(() => _selectedVehicleId = null);
                    }
                  },
                  icon: const Icon(
                    Icons.person_add,
                    size: 24,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ],
        ),
        body: Column(
          children: [
            // Mode toggle — hidden for quotations
            if (!isQuotation)
              _BillingModeToggle(
                imageMode: _imageMode,
                onChanged: (v) => setState(() => _imageMode = v),
              ),

            if (!_imageMode) ...[
              // Search bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: SearchBarWidget(
                  autofocus: true,
                  onSearch: (query) => productProvider.searchProducts(query),
                  onProductSelected: (product) => billProvider.addItemToBill(
                    product,
                    businessType: businessConfig.businessType,
                  ),
                  onScanBarcode: () => _scanAndAddByBarcode(
                    billProvider: billProvider,
                    productProvider: productProvider,
                    businessConfig: businessConfig,
                  ),
                ),
              ),
              // Customer section (for quotations)
              if (isQuotation)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  child: _QuotationCustomerCard(
                    existingCustomer: billProvider.activeCustomer,
                    useNewCustomer: _useNewCustomer,
                    nameController: _newCustomerNameController,
                    phoneController: _newCustomerPhoneController,
                    onSelectExisting: () async {
                      final customer = await CustomerListSheet.show(context);
                      if (customer != null && mounted) {
                        billProvider.setActiveCustomer(customer);
                        setState(() => _useNewCustomer = false);
                      }
                    },
                    onUseNew: () {
                      billProvider.setActiveCustomer(null);
                      setState(() => _useNewCustomer = true);
                    },
                    onClearExisting: () {
                      billProvider.setActiveCustomer(null);
                    },
                    onCancelNew: () => setState(() => _useNewCustomer = false),
                  ),
                ),
              // Workshop / Mobile shop vehicle/device info (for quotations)
              if (isQuotation && (businessConfig.isWorkshop || businessConfig.isMobileShop))
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.small),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(businessConfig.isMobileShop ? Icons.phone_android : Icons.directions_car, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                businessConfig.isMobileShop ? 'Device Details' : 'Vehicle Details',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _vehicleRegController,
                                  decoration: InputDecoration(
                                    labelText: businessConfig.isMobileShop ? 'IMEI / Serial No.' : 'Reg Number',
                                    hintText: businessConfig.isMobileShop ? 'e.g. 358xxxxxxxxx' : 'e.g. TN01AB1234',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              Expanded(
                                child: TextField(
                                  controller: _kmReadingController,
                                  decoration: InputDecoration(
                                    labelText: businessConfig.isMobileShop ? 'Color / Storage' : 'KM Reading',
                                    hintText: businessConfig.isMobileShop ? 'e.g. Black 128GB' : 'e.g. 12500',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                    ),
                                  ),
                                  keyboardType: businessConfig.isMobileShop ? TextInputType.text : TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _vehicleMakeController,
                                  decoration: InputDecoration(
                                    labelText: businessConfig.isMobileShop ? 'Brand' : 'Make',
                                    hintText: businessConfig.isMobileShop ? 'e.g. Samsung' : 'e.g. Honda',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              Expanded(
                                child: TextField(
                                  controller: _vehicleModelController,
                                  decoration: InputDecoration(
                                    labelText: 'Model',
                                    hintText: 'e.g. Activa 6G',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Clinic visit notes
              if (isClinic)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.small),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(
                            () => _visitNotesExpanded = !_visitNotesExpanded,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.medium,
                              vertical: AppSpacing.small,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.medical_information_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: AppSpacing.small),
                                Text(
                                  AppStrings.visitNotesSection,
                                  style: AppTypography.body.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _visitNotesExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_visitNotesExpanded)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.medium,
                              0,
                              AppSpacing.medium,
                              AppSpacing.medium,
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _diagnosisController,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.diagnosisLabel,
                                    hintText: AppStrings.diagnosisHint,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius,
                                      ),
                                    ),
                                  ),
                                  onChanged: (v) => billProvider.setVisitNotes(
                                    diagnosis: v.isNotEmpty ? v : null,
                                    visitNotes:
                                        _visitNotesController.text.isNotEmpty
                                        ? _visitNotesController.text
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.small),
                                TextField(
                                  controller: _visitNotesController,
                                  decoration: InputDecoration(
                                    labelText: AppStrings.visitNotesLabel,
                                    hintText: AppStrings.visitNotesHint,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius,
                                      ),
                                    ),
                                  ),
                                  maxLines: 2,
                                  onChanged: (v) => billProvider.setVisitNotes(
                                    diagnosis:
                                        _diagnosisController.text.isNotEmpty
                                        ? _diagnosisController.text
                                        : null,
                                    visitNotes: v.isNotEmpty ? v : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              // Workshop / Mobile shop vehicle/device info (for regular bills)
              if (!isQuotation && (businessConfig.isWorkshop || businessConfig.isMobileShop))
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.small),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                businessConfig.isMobileShop ? Icons.phone_android : Icons.two_wheeler,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                businessConfig.isMobileShop ? 'Device Details' : 'Vehicle Details',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          // Saved vehicle picker — shown when customer has vehicles
                          if (billProvider.activeCustomer != null &&
                              billProvider.activeCustomer!.vehicles.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.small),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  ...billProvider.activeCustomer!.vehicles.map(
                                    (v) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                        label: Text(
                                          v.model != null && v.model!.isNotEmpty
                                              ? '${v.reg} · ${v.model}'
                                              : v.reg,
                                          style: AppTypography.label,
                                        ),
                                        selected: _selectedVehicleId == v.id,
                                        onSelected: (_) =>
                                            _selectVehicle(v, billProvider),
                                        selectedColor:
                                            AppColors.primaryLight(0.15),
                                        side: BorderSide(
                                          color: _selectedVehicleId == v.id
                                              ? AppColors.primary
                                              : AppColors.mutedLight(0.4),
                                        ),
                                      ),
                                    ),
                                  ),
                                  ChoiceChip(
                                    label: const Text('+ New vehicle'),
                                    selected: _selectedVehicleId == null,
                                    onSelected: (_) =>
                                        _selectNewVehicle(billProvider),
                                    selectedColor: AppColors.primaryLight(0.15),
                                    side: BorderSide(
                                      color: _selectedVehicleId == null
                                          ? AppColors.primary
                                          : AppColors.mutedLight(0.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.small),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _vehicleRegController,
                                  decoration: InputDecoration(
                                    labelText: businessConfig.isMobileShop ? 'IMEI / Serial No.' : 'Reg Number',
                                    hintText: businessConfig.isMobileShop ? 'e.g. 358xxxxxxxxx' : 'e.g. TN01AB1234',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) =>
                                      _syncVehicleInfo(billProvider),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              Expanded(
                                child: TextField(
                                  controller: _kmReadingController,
                                  decoration: InputDecoration(
                                    labelText: businessConfig.isMobileShop ? 'Color / Storage' : 'KM Reading',
                                    hintText: businessConfig.isMobileShop ? 'e.g. Black 128GB' : 'e.g. 12500',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius,
                                      ),
                                    ),
                                  ),
                                  keyboardType: businessConfig.isMobileShop ? TextInputType.text : TextInputType.number,
                                  onChanged: (_) =>
                                      _syncVehicleInfo(billProvider),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.small),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _vehicleMakeController,
                                  decoration: InputDecoration(
                                    labelText: 'Make',
                                    hintText: 'e.g. Honda',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) =>
                                      _syncVehicleInfo(billProvider),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                              Expanded(
                                child: TextField(
                                  controller: _vehicleModelController,
                                  decoration: InputDecoration(
                                    labelText: 'Model',
                                    hintText: 'e.g. Activa 6G',
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.cardRadius,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) =>
                                      _syncVehicleInfo(billProvider),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // Line items list
              Expanded(
                child: billProvider.activeLineItems.isEmpty
                    ? const EmptyState(
                        icon: Icons.search,
                        title: AppStrings.startAddingProducts,
                        description: AppStrings.startAddingProductsDesc,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.medium,
                        ),
                        itemCount: billProvider.activeLineItems.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: AppSpacing.small),
                        itemBuilder: (context, index) {
                          final item = billProvider.activeLineItems[index];
                          return LineItemRow(
                            item: item,
                            onQuantityChanged: (qty) =>
                                billProvider.updateQuantity(index, qty),
                            onDiscountChanged: (discount) =>
                                billProvider.updateLineDiscount(
                              index,
                              discount,
                            ),
                            onDelete: () {
                              final removed = billProvider.removeItemForUndo(
                                index,
                              );
                              if (removed != null) {
                                AppSnackbar.undo(
                                  context,
                                  message: '${removed.product.name} removed',
                                  onUndo: () =>
                                      billProvider.restoreItem(index, removed),
                                );
                              }
                            },
                            availableSerialNumbers: item.product.trackSerialNumbers
                                ? context.watch<SerialNumberProvider>().availableFor(item.product.id)
                                : null,
                            onSerialNumberChanged: item.product.trackSerialNumbers
                                ? (ids) => billProvider.updateSerialIds(index, ids)
                                : null,
                          );
                        },
                      ),
              ),
            ] else ...[
              // Image grid mode
              Expanded(
                child: _ImageGridBody(
                  products: productProvider.products,
                  activeItems: billProvider.activeLineItems,
                  onAdd: (product) => billProvider.addItemToBill(
                    product,
                    businessType: businessConfig.businessType,
                  ),
                  onUpdate: (index, qty) => billProvider.updateQuantity(
                    index,
                    qty,
                  ),
                  onRemove: (index) => billProvider.removeItemForUndo(index),
                ),
              ),
            ],

            // Footer
            BillTotalFooter(
              subtotal: billProvider.activeSubtotal,
              lineDiscount: billProvider.activeTotalLineDiscount,
              discount: billProvider.activeDiscount,
              cgst: billProvider.activeCgst(isInterState: isInterState),
              sgst: billProvider.activeSgst(isInterState: isInterState),
              igst: billProvider.activeIgst(isInterState: isInterState),
              grandTotal: billProvider.activeGrandTotal(
                isInterState: isInterState,
                gstEnabled: gstEnabled,
              ),
              gstEnabled: gstEnabled,
              isInterState: isInterState,
              hasItems: billProvider.hasActiveItems,
              discountIsPercent: billProvider.discountIsPercent,
              discountValue: billProvider.discountValue,
              buttonLabel: isQuotation ? AppStrings.createQuotation : null,
              onProceedToPayment: isQuotation
                  ? () => _createQuotation(
                        billProvider: billProvider,
                        isInterState: isInterState,
                        gstEnabled: gstEnabled,
                        vehicleReg: _vehicleRegController.text.trim().isEmpty ? null : _vehicleRegController.text.trim(),
                        vehicleMake: _vehicleMakeController.text.trim().isEmpty ? null : _vehicleMakeController.text.trim(),
                        vehicleModel: _vehicleModelController.text.trim().isEmpty ? null : _vehicleModelController.text.trim(),
                        kmReading: _kmReadingController.text.trim().isEmpty ? null : _kmReadingController.text.trim(),
                        newCustomerName: _useNewCustomer && _newCustomerNameController.text.trim().isNotEmpty ? _newCustomerNameController.text.trim() : null,
                        newCustomerPhone: _useNewCustomer && _newCustomerPhoneController.text.trim().isNotEmpty ? _newCustomerPhoneController.text.trim() : null,
                      )
                  : () {
                      Navigator.pushNamed(context, '/payment');
                    },
              onDiscountChanged: ({
                required bool isPercent,
                required double value,
              }) {
                billProvider.setDiscount(isPercent: isPercent, value: value);
              },
              onClearDiscount: () => billProvider.clearDiscount(),
            ),
          ],
        ),
      ),
    );
  }

  void _selectVehicle(CustomerVehicle vehicle, BillProvider billProvider) {
    setState(() => _selectedVehicleId = vehicle.id);
    _vehicleRegController.text = vehicle.reg;
    _vehicleMakeController.text = vehicle.make ?? '';
    _vehicleModelController.text = vehicle.model ?? '';
    _kmReadingController.text = '';
    _syncVehicleInfo(billProvider);
  }

  void _selectNewVehicle(BillProvider billProvider) {
    setState(() => _selectedVehicleId = null);
    _vehicleRegController.clear();
    _vehicleMakeController.clear();
    _vehicleModelController.clear();
    _kmReadingController.clear();
    _syncVehicleInfo(billProvider);
  }

  void _syncVehicleInfo(BillProvider billProvider) {
    billProvider.setVehicleInfo(
      vehicleReg: _vehicleRegController.text.trim().isEmpty
          ? null
          : _vehicleRegController.text.trim(),
      vehicleMake: _vehicleMakeController.text.trim().isEmpty
          ? null
          : _vehicleMakeController.text.trim(),
      vehicleModel: _vehicleModelController.text.trim().isEmpty
          ? null
          : _vehicleModelController.text.trim(),
      kmReading: _kmReadingController.text.trim().isEmpty
          ? null
          : _kmReadingController.text.trim(),
    );
  }

  void _createQuotation({
    required BillProvider billProvider,
    required bool isInterState,
    required bool gstEnabled,
    String? vehicleReg,
    String? vehicleMake,
    String? vehicleModel,
    String? kmReading,
    String? newCustomerName,
    String? newCustomerPhone,
  }) {
    final quotationProvider = context.read<QuotationProvider>();
    final quotationNumber = quotationProvider.generateQuotationNumber();

    final quotation = Quotation(
      quotationNumber: quotationNumber,
      customerId: billProvider.activeCustomer?.id,
      customerName: billProvider.activeCustomer?.name ?? newCustomerName,
      customerPhone: billProvider.activeCustomer?.phone ?? newCustomerPhone,
      customer: billProvider.activeCustomer,
      items: List.from(billProvider.activeLineItems),
      vehicleReg: vehicleReg,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      kmReading: kmReading,
      subtotal: billProvider.activeSubtotal,
      discount: billProvider.activeDiscount,
      cgst:
          gstEnabled
          ? billProvider.activeCgst(isInterState: isInterState)
          : 0,
      sgst:
          gstEnabled
          ? billProvider.activeSgst(isInterState: isInterState)
          : 0,
      igst:
          gstEnabled
          ? billProvider.activeIgst(isInterState: isInterState)
          : 0,
      grandTotal: billProvider.activeGrandTotal(isInterState: isInterState, gstEnabled: gstEnabled),
      isInterState: isInterState,
    );

    quotationProvider.addQuotation(quotation);
    billProvider.clearActiveBill();
    AppSnackbar.success(context, AppStrings.quotationSaved);
    Navigator.pop(context);
  }

  Future<void> _scanAndAddByBarcode({
    required BillProvider billProvider,
    required ProductProvider productProvider,
    required BusinessConfigProvider businessConfig,
  }) async {
    final barcode = await widget.scannerService.scanBarcode(context);
    if (!mounted || barcode == null) return;

    final product = productProvider.findByBarcode(barcode);
    if (product == null) {
      AppSnackbar.error(context, AppStrings.barcodeNotFound);
      return;
    }

    billProvider.addItemToBill(
      product,
      businessType: businessConfig.businessType,
    );
    AppSnackbar.success(
      context,
      '${AppStrings.productAddedByBarcode}: ${product.name}',
    );
  }
}

// ─── Quotation Customer Card ──────────────────────────────────────────────────

class _QuotationCustomerCard extends StatelessWidget {
  final Customer? existingCustomer;
  final bool useNewCustomer;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onSelectExisting;
  final VoidCallback onUseNew;
  final VoidCallback onClearExisting;
  final VoidCallback onCancelNew;

  const _QuotationCustomerCard({
    required this.existingCustomer,
    required this.useNewCustomer,
    required this.nameController,
    required this.phoneController,
    required this.onSelectExisting,
    required this.onUseNew,
    required this.onClearExisting,
    required this.onCancelNew,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Customer (Optional)',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (existingCustomer != null)
                  GestureDetector(
                    onTap: onClearExisting,
                    child: const Icon(Icons.close, size: 18, color: AppColors.muted),
                  )
                else if (useNewCustomer)
                  GestureDetector(
                    onTap: onCancelNew,
                    child: Text(
                      'Cancel',
                      style: AppTypography.label.copyWith(color: AppColors.muted),
                    ),
                  ),
              ],
            ),
            if (existingCustomer != null) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                existingCustomer!.name,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
              ),
              if (existingCustomer!.phone?.isNotEmpty ?? false)
                Text(
                  existingCustomer!.phone!,
                  style: AppTypography.label.copyWith(color: AppColors.muted),
                ),
              const SizedBox(height: AppSpacing.small),
              GestureDetector(
                onTap: onSelectExisting,
                child: Text(
                  'Change customer',
                  style: AppTypography.label.copyWith(color: AppColors.primary),
                ),
              ),
            ] else if (useNewCustomer) ...[
              const SizedBox(height: AppSpacing.small),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name',
                  hintText: 'e.g. Ravi Kumar',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.small),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  hintText: '10-digit mobile number',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
                keyboardType: TextInputType.phone,
                maxLength: 10,
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.small),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSelectExisting,
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('Select Existing'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: AppTypography.label,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onUseNew,
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('New Customer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: AppTypography.label,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Mode Toggle ──────────────────────────────────────────────────────────────

class _BillingModeToggle extends StatelessWidget {
  final bool imageMode;
  final ValueChanged<bool> onChanged;

  const _BillingModeToggle({
    required this.imageMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: 6,
      ),
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: false,
            label: Text('Search'),
            icon: Icon(Icons.search, size: 16),
          ),
          ButtonSegment(
            value: true,
            label: Text('Grid'),
            icon: Icon(Icons.grid_view, size: 16),
          ),
        ],
        selected: {imageMode},
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

// ─── Image Grid Body ──────────────────────────────────────────────────────────

class _ImageGridBody extends StatefulWidget {
  final List<Product> products;
  final List<LineItem> activeItems;
  final void Function(Product) onAdd;
  final void Function(int index, double qty) onUpdate;
  final void Function(int index) onRemove;

  const _ImageGridBody({
    required this.products,
    required this.activeItems,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_ImageGridBody> createState() => _ImageGridBodyState();
}

class _ImageGridBodyState extends State<_ImageGridBody> {
  String? _selectedCategory;
  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};

  GlobalKey _keyFor(String cat) =>
      _categoryKeys.putIfAbsent(cat, () => GlobalKey());

  List<String> get _categories {
    final seen = <String>{};
    return widget.products
        .map((p) => p.category ?? '')
        .where((c) => c.isNotEmpty && seen.add(c))
        .toList();
  }

  double _getQty(String productId) {
    final idx = widget.activeItems.indexWhere(
      (i) => i.product.id == productId,
    );
    return idx >= 0 ? widget.activeItems[idx].quantity : 0;
  }

  int _itemIndex(String productId) =>
      widget.activeItems.indexWhere((i) => i.product.id == productId);

  void _increment(Product product) {
    final idx = _itemIndex(product.id);
    if (idx >= 0) {
      widget.onUpdate(
        idx,
        widget.activeItems[idx].quantity + product.quantityStep,
      );
    } else {
      widget.onAdd(product);
    }
  }

  void _decrement(Product product) {
    final idx = _itemIndex(product.id);
    if (idx < 0) return;
    final newQty =
        widget.activeItems[idx].quantity - product.quantityStep;
    if (newQty <= 0) {
      widget.onRemove(idx);
    } else {
      widget.onUpdate(idx, newQty);
    }
  }

  void _remove(Product product) {
    final idx = _itemIndex(product.id);
    if (idx >= 0) widget.onRemove(idx);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;

    if (widget.products.isEmpty) {
      return const EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products',
        description: 'Add products to see them here',
      );
    }

    final effectiveCat =
        _selectedCategory != null && categories.contains(_selectedCategory)
        ? _selectedCategory!
        : categories.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availWidth = constraints.maxWidth - 76;
        final int crossCount = availWidth > 900 ? 6 : availWidth > 580 ? 4 : 3;
        final double aspectRatio =
            availWidth > 900 ? 0.9 : availWidth > 580 ? 0.78 : 0.72;
        return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category sidebar
        Container(
          width: 76,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              right: BorderSide(
                color: AppColors.mutedLight(0.3),
              ),
            ),
          ),
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = cat == effectiveCat;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                  final key = _keyFor(cat);
                  if (key.currentContext != null) {
                    Scrollable.ensureVisible(
                      key.currentContext!,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight(0.10)
                        : Colors.transparent,
                    border: Border(
                      left: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: AppTypography.label.copyWith(
                      fontSize: 12,
                      color: isSelected ? AppColors.primary : AppColors.muted,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),

        // Product grid
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              for (final cat in categories) ...[
                SliverToBoxAdapter(
                  key: _keyFor(cat),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.small,
                      AppSpacing.medium,
                      AppSpacing.small,
                      4,
                    ),
                    child: Text(
                      cat,
                      style: AppTypography.label.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          childAspectRatio: aspectRatio,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                    itemCount: widget.products
                        .where((p) => (p.category ?? '') == cat)
                        .length,
                    itemBuilder: (context, index) {
                      final catProducts = widget.products
                          .where((p) => (p.category ?? '') == cat)
                          .toList();
                      final product = catProducts[index];
                      final qty = _getQty(product.id);
                      return _ProductGridCard(
                        product: product,
                        qty: qty,
                        onAdd: () => _increment(product),
                        onDecrement: () => _decrement(product),
                        onRemove: () => _remove(product),
                      );
                    },
                  ),
                ),
              ],
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.large),
              ),
            ],
          ),
        ),
      ],
        );
      },
    );
  }
}

// ─── Product Grid Card ────────────────────────────────────────────────────────

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final double qty;
  final VoidCallback onAdd;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _ProductGridCard({
    required this.product,
    required this.qty,
    required this.onAdd,
    required this.onDecrement,
    required this.onRemove,
  });

  bool get _selected => qty > 0;

  Widget _buildImage() {
    final url = product.imageUrl;
    Widget placeholder = Container(
      color: AppColors.mutedLight(0.12),
      child: const Center(
        child: Icon(Icons.image_outlined, color: AppColors.muted, size: 28),
      ),
    );
    if (url == null || url.isEmpty) return placeholder;
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder,
      );
    }
    if (kIsWeb) return placeholder;
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }

  String _formatQty(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  String _formatPrice(double v) =>
      '₹${v % 1 == 0 ? v.toInt() : v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _selected ? null : onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: _selected ? AppColors.primary : AppColors.mutedLight(0.2),
            width: _selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.cardRadius - 1),
                    ),
                    child: _buildImage(),
                  ),
                ),
                // Info + controls
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTypography.label.copyWith(
                            fontSize: 11,
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        if (!_selected)
                          // Price + add button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  _formatPrice(product.sellingPrice),
                                  style: AppTypography.label.copyWith(
                                    fontSize: 12,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: onAdd,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          // Price + stepper row
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _formatPrice(product.sellingPrice),
                                style: AppTypography.label.copyWith(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _CircleBtn(
                                    icon: Icons.remove,
                                    onTap: onDecrement,
                                  ),
                                  Text(
                                    _formatQty(qty),
                                    style: AppTypography.label.copyWith(
                                      fontSize: 12,
                                      color: AppColors.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  _CircleBtn(
                                    icon: Icons.add,
                                    onTap: onAdd,
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Remove (×) button — top right when selected
            if (_selected)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 11,
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
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 12, color: Colors.white),
      ),
    );
  }
}
