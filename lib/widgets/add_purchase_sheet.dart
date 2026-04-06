import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/payment_info.dart';
import '../models/product.dart';
import '../models/purchase_entry.dart';
import '../models/purchase_line_item.dart';
import '../models/supplier.dart';
import '../providers/product_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/serial_number_provider.dart';
import '../providers/supplier_provider.dart';
import 'app_snackbar.dart';
import 'app_text_input.dart';
import 'payment_mode_selector.dart';

class AddPurchaseSheet extends StatefulWidget {
  final PurchaseEntry? existingEntry;

  const AddPurchaseSheet({super.key, this.existingEntry});

  static Future<void> show(BuildContext context, [PurchaseEntry? entry]) {
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
          ChangeNotifierProvider.value(
            value: context.read<PurchaseProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<ProductProvider>(),
          ),
          ChangeNotifierProvider.value(
            value: context.read<SupplierProvider>(),
          ),
        ],
        child: AddPurchaseSheet(existingEntry: entry),
      ),
    );
  }

  @override
  State<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends State<AddPurchaseSheet> {
  Supplier? _selectedSupplier;
  final _adHocSupplierController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _productSearchController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  PaymentMode _paymentMode = PaymentMode.cash;
  final List<_PurchaseLine> _lines = [];
  String? _itemError;

  bool get _isEdit => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    if (entry != null) {
      _selectedDate = entry.date;
      _paymentMode = entry.paymentMode;
      _invoiceNumberController.text = entry.invoiceNumber ?? '';
      _notesController.text = entry.notes ?? '';
      if (entry.supplierName != null && entry.supplierId == null) {
        _adHocSupplierController.text = entry.supplierName!;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final entry = widget.existingEntry;
    if (entry != null && _lines.isEmpty) {
      final productProvider = context.read<ProductProvider>();
      final supplierProvider = context.read<SupplierProvider>();
      // Pre-select supplier
      if (entry.supplierId != null) {
        _selectedSupplier = supplierProvider.getSupplierById(entry.supplierId!);
      }
      // Pre-fill line items
      for (final item in entry.items) {
        final product = productProvider.findById(item.productId);
        if (product != null) {
          _lines.add(_PurchaseLine.fromItem(product, item));
        }
      }
    }
  }

  @override
  void dispose() {
    _adHocSupplierController.dispose();
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _productSearchController.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  double get _runningTotal =>
      _lines.fold(0.0, (sum, line) => sum + line.totalCost);

  @override
  Widget build(BuildContext context) {
    final supplierProvider = context.watch<SupplierProvider>();
    final productProvider = context.watch<ProductProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_isEdit ? 'Edit Purchase' : AppStrings.addPurchase, style: AppTypography.heading),
                    Text(
                      Formatters.currency(_runningTotal),
                      style: AppTypography.currency,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  children: [
                    // Supplier picker
                    Text(
                      AppStrings.supplierNameLabel,
                      style:
                          AppTypography.label.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    _buildSupplierPicker(supplierProvider),
                    const SizedBox(height: AppSpacing.small),

                    // Date picker
                    InkWell(
                      onTap: _pickDate,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.muted.withValues(alpha: 0.3),
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(_selectedDate),
                              style: AppTypography.body,
                            ),
                            const Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),

                    // Invoice number
                    AppTextInput(
                      label: AppStrings.invoiceNumberLabel,
                      hint: AppStrings.invoiceNumberHint,
                      controller: _invoiceNumberController,
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Product lines
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.purchaseItems,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _showProductSearch(context, productProvider),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(AppStrings.addProduct),
                        ),
                      ],
                    ),
                    if (_itemError != null) ...[
                      Text(
                        _itemError!,
                        style:
                            AppTypography.label.copyWith(color: AppColors.error),
                      ),
                      const SizedBox(height: 4),
                    ],
                    ..._lines.asMap().entries.map((entry) {
                      final index = entry.key;
                      final line = entry.value;
                      return _buildLineItem(line, index);
                    }),
                    if (_lines.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: AppColors.muted.withValues(alpha: 0.05),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                          border: Border.all(
                            color: AppColors.muted.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            AppStrings.addProductsToPurchase,
                            style: AppTypography.label,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.medium),

                    // Payment mode
                    Text(
                      AppStrings.paymentModeLabel,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    PaymentModeSelector(
                      selected: _paymentMode,
                      onChanged: (mode) =>
                          setState(() => _paymentMode = mode),
                    ),
                    const SizedBox(height: AppSpacing.small),

                    // Notes
                    Text(
                      AppStrings.supplierNotesLabel,
                      style:
                          AppTypography.label.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: AppStrings.optionalNotesHint,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.cardRadius),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.large),
                  ],
                ),
              ),
              // Save button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.buttonRadius),
                        ),
                      ),
                      child: Text(
                        '${AppStrings.savePurchase}  ${Formatters.currency(_runningTotal)}',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupplierPicker(SupplierProvider supplierProvider) {
    final activeSuppliers = supplierProvider.getActiveSuppliers();
    if (activeSuppliers.isEmpty) {
      return AppTextInput(
        label: '',
        hint: AppStrings.supplierNameHint,
        controller: _adHocSupplierController,
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: _selectedSupplier?.id,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      hint: Text(AppStrings.selectSupplier, style: AppTypography.label),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Ad-hoc (no supplier)'),
        ),
        ...activeSuppliers.map(
          (s) => DropdownMenuItem<String?>(
            value: s.id,
            child: Text(s.name),
          ),
        ),
      ],
      onChanged: (id) {
        setState(() {
          if (id == null) {
            _selectedSupplier = null;
          } else {
            _selectedSupplier = supplierProvider.getSupplierById(id);
          }
        });
      },
    );
  }

  Widget _buildLineItem(_PurchaseLine line, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line.product.name,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.error,
                onPressed: () {
                  setState(() {
                    _lines[index].dispose();
                    _lines.removeAt(index);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: line.qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: AppStrings.qty,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                  style: AppTypography.body,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: line.priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: AppStrings.purchasePriceLabel,
                    prefixText: 'Rs. ',
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                  ),
                  style: AppTypography.body,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              // GST rate dropdown
              DropdownButton<double>(
                value: line.gstRate,
                isDense: true,
                underline: const SizedBox(),
                items: const [0, 5, 12, 18, 28].map((rate) {
                  return DropdownMenuItem(
                    value: rate.toDouble(),
                    child: Text(
                      rate == 0 ? 'No GST' : '$rate%',
                      style: AppTypography.label,
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() {
                  line.gstRate = val ?? 0;
                  if (line.gstRate == 0) line.isTaxInclusive = false;
                }),
              ),
            ],
          ),
          // Tax inclusive toggle — only shown when GST rate is set
          if (line.gstRate > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 36,
                  child: Switch.adaptive(
                    value: line.isTaxInclusive,
                    activeTrackColor: AppColors.primary,
                    onChanged: (val) =>
                        setState(() => line.isTaxInclusive = val),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Price includes GST',
                  style: AppTypography.label.copyWith(color: AppColors.muted),
                ),
                const Spacer(),
                // Tax breakdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Base: ${Formatters.currency(line.baseAmount)}',
                      style: AppTypography.label.copyWith(color: AppColors.muted),
                    ),
                    Text(
                      'Tax: ${Formatters.currency(line.taxAmount)}',
                      style: AppTypography.label.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ],
          // Total
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              Formatters.currency(line.totalCost),
              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Serial number entry for tracked products
          if (line.product.trackSerialNumbers && line.quantity.toInt() > 0) ...[
            const SizedBox(height: 6),
            _buildSerialNumberEntry(line),
          ],
        ],
      ),
    );
  }

  Widget _buildSerialNumberEntry(_PurchaseLine line) {
    final needed = line.quantity.toInt();
    final filled = line.serialNumbers.where((s) => s.trim().isNotEmpty).length;
    final allFilled = filled == needed;

    return GestureDetector(
      onTap: () => _showSerialNumberDialog(line),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: allFilled
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: allFilled ? AppColors.primary : AppColors.error,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              allFilled ? Icons.check_circle_outline : Icons.qr_code_scanner,
              size: 16,
              color: allFilled ? AppColors.primary : AppColors.error,
            ),
            const SizedBox(width: 6),
            Text(
              allFilled
                  ? 'Serial Nos. entered ($filled/$needed)'
                  : 'Enter serial numbers ($filled/$needed)',
              style: AppTypography.label.copyWith(
                color: allFilled ? AppColors.primary : AppColors.error,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: allFilled ? AppColors.primary : AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  void _showSerialNumberDialog(_PurchaseLine line) {
    final needed = line.quantity.toInt();
    if (needed <= 0) return;
    // Sync list size to current quantity
    while (line.serialNumbers.length < needed) {
      line.serialNumbers.add('');
    }
    if (line.serialNumbers.length > needed) {
      line.serialNumbers = line.serialNumbers.sublist(0, needed);
    }
    final controllers = List.generate(
      needed,
      (i) => TextEditingController(text: line.serialNumbers[i]),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Serial Numbers — ${line.product.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: needed,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => TextField(
              controller: controllers[i],
              decoration: InputDecoration(
                labelText: 'S/N ${i + 1}',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                for (var i = 0; i < needed; i++) {
                  if (i < line.serialNumbers.length) {
                    line.serialNumbers[i] = controllers[i].text;
                  }
                }
              });
              for (final c in controllers) {
                c.dispose();
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showProductSearch(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => _ProductSearchSheet(
        productProvider: productProvider,
        purchaseProvider: context.read<PurchaseProvider>(),
        onSelected: (product) {
          setState(() {
            _itemError = null;
            final lastPrice = context
                .read<PurchaseProvider>()
                .getLastPurchasePrice(product.id);
            _lines.add(_PurchaseLine(product, lastPrice: lastPrice));
          });
        },
      ),
    );
  }

  void _save() {
    if (_lines.isEmpty) {
      setState(() => _itemError = AppStrings.addAtLeastOneItem);
      return;
    }

    for (final line in _lines) {
      if (line.quantity <= 0 || line.pricePerUnit <= 0) {
        setState(() => _itemError = AppStrings.purchaseItemsIncomplete);
        return;
      }
      if (line.product.trackSerialNumbers) {
        final needed = line.quantity.toInt();
        final filled = line.serialNumbers.where((s) => s.trim().isNotEmpty).length;
        if (filled < needed) {
          setState(() => _itemError =
              'Enter all ${needed} serial numbers for ${line.product.name}');
          return;
        }
      }
    }

    // Capture all context-dependent references before popping — provider mutations
    // (addPurchase / incrementStock) call notifyListeners() which would queue a
    // rebuild for this sheet while it's still in the tree, triggering the
    // _dependents.isEmpty assertion. Popping first removes the sheet cleanly.
    final purchaseProvider = context.read<PurchaseProvider>();
    final productProvider = context.read<ProductProvider>();
    final supplierProvider = context.read<SupplierProvider>();
    final serialNumberProvider = context.read<SerialNumberProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final supplierName = _selectedSupplier?.name ??
        (_adHocSupplierController.text.trim().isNotEmpty
            ? _adHocSupplierController.text.trim()
            : null);

    final items = _lines.map((line) {
      return PurchaseLineItem(
        productId: line.product.id,
        productName: line.product.name,
        quantity: line.quantity,
        unitOfMeasure: line.product.unit,
        purchasePricePerUnit: line.pricePerUnit,
        gstRate: line.gstRate,
        isTaxInclusive: line.isTaxInclusive,
      );
    }).toList();

    final invoiceNum = _invoiceNumberController.text.trim();
    final notes = _notesController.text.trim();

    final entry = PurchaseEntry(
      supplierId: _selectedSupplier?.id,
      supplierName: supplierName,
      date: _selectedDate,
      items: items,
      paymentMode: _paymentMode,
      invoiceNumber: invoiceNum.isNotEmpty ? invoiceNum : null,
      notes: notes.isNotEmpty ? notes : null,
    );

    // Pop BEFORE provider mutations so the sheet is removed from the tree
    // before notifyListeners fires (avoids _dependents.isEmpty assertion).
    Navigator.pop(context);

    if (_isEdit) {
      purchaseProvider.updatePurchase(
        widget.existingEntry!.id,
        entry,
        productProvider: productProvider,
        supplierProvider: supplierProvider,
      );
    } else {
      purchaseProvider.addPurchase(
        entry,
        productProvider: productProvider,
        supplierProvider: supplierProvider,
      );
    }

    // Register serial numbers for tracked products (new entries only)
    if (!_isEdit) {
      for (final line in _lines) {
        if (line.product.trackSerialNumbers && line.serialNumbers.isNotEmpty) {
          serialNumberProvider.addFromPurchase(
            numbers: line.serialNumbers,
            productId: line.product.id,
            productName: line.product.name,
            purchaseEntryId: entry.id,
          );
        }
      }
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(_isEdit ? 'Purchase updated' : AppStrings.purchaseAdded),
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.medium,
      ),
      dismissDirection: DismissDirection.horizontal,
    ));
  }
}

class _PurchaseLine {
  final Product product;
  final TextEditingController qtyController;
  final TextEditingController priceController;
  double gstRate;
  bool isTaxInclusive;
  List<String> serialNumbers;

  _PurchaseLine(this.product, {double? lastPrice})
      : qtyController = TextEditingController(text: '1'),
        priceController = TextEditingController(
          text: lastPrice?.toStringAsFixed(2) ?? '',
        ),
        gstRate = 0,
        isTaxInclusive = false,
        serialNumbers = [];

  _PurchaseLine.fromItem(this.product, PurchaseLineItem item)
      : qtyController = TextEditingController(
          text: item.quantity.toStringAsFixed(
              item.quantity == item.quantity.roundToDouble() ? 0 : 2),
        ),
        priceController = TextEditingController(
          text: item.purchasePricePerUnit.toStringAsFixed(2),
        ),
        gstRate = item.gstRate,
        isTaxInclusive = item.isTaxInclusive,
        serialNumbers = [];

  double get quantity => double.tryParse(qtyController.text) ?? 0;
  double get pricePerUnit => double.tryParse(priceController.text) ?? 0;
  double get totalCost => quantity * pricePerUnit;
  double get taxAmount {
    if (gstRate <= 0) return 0;
    if (isTaxInclusive) return totalCost * gstRate / (100 + gstRate);
    return totalCost * gstRate / 100;
  }
  double get baseAmount => isTaxInclusive ? totalCost - taxAmount : totalCost;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}

class _ProductSearchSheet extends StatefulWidget {
  final ProductProvider productProvider;
  final PurchaseProvider purchaseProvider;
  final ValueChanged<Product> onSelected;

  const _ProductSearchSheet({
    required this.productProvider,
    required this.purchaseProvider,
    required this.onSelected,
  });

  @override
  State<_ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<_ProductSearchSheet> {
  final _controller = TextEditingController();
  List<Product> _results = [];

  @override
  void dispose() {
    _controller.dispose();
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
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: AppStrings.searchProducts,
              prefixIcon: const Icon(Icons.search, color: AppColors.muted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (query) {
              setState(() {
                _results =
                    widget.productProvider.searchProducts(query, limit: 10);
              });
            },
          ),
          const SizedBox(height: AppSpacing.small),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: _results.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: Text(
                        _controller.text.isEmpty
                            ? AppStrings.searchProducts
                            : AppStrings.noProductsFound,
                        style: AppTypography.label,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final product = _results[index];
                      return ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          'Stock: ${product.stockQuantity} | ${Formatters.currency(product.sellingPrice)}',
                          style: AppTypography.label,
                        ),
                        onTap: () {
                          widget.onSelected(product);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
