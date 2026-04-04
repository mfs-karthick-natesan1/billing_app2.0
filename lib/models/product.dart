import 'package:uuid/uuid.dart';
import 'product_batch.dart';
import '../core/utils/json_helpers.dart';

class Product {
  static const _unset = Object();

  final String id;
  final String name;
  final String? barcode;
  final double sellingPrice;
  final int stockQuantity;
  final String? category;
  final String unit;
  final String? customUomLabel;
  final double minQuantity;
  final double quantityStep;
  final String? hsnCode;
  final double gstRate;
  final bool gstInclusivePrice;
  final int gstSlabPercent;
  final int lowStockThreshold;
  final DateTime createdAt;
  final List<ProductBatch> batches;
  final bool isService;
  final int? durationMinutes;
  final double? reorderLevel;
  final double? reorderQuantity;
  final String? preferredSupplierId;
  final double costPrice;
  final double defaultDiscountPercent;
  final String? imageUrl;
  final bool trackSerialNumbers;

  Product({
    String? id,
    required this.name,
    this.barcode,
    required this.sellingPrice,
    this.stockQuantity = 0,
    this.category,
    this.unit = 'pcs',
    this.customUomLabel,
    this.minQuantity = 1.0,
    this.quantityStep = 1.0,
    this.hsnCode,
    this.gstRate = 0.0,
    this.gstInclusivePrice = false,
    this.gstSlabPercent = 0,
    this.lowStockThreshold = 10,
    DateTime? createdAt,
    List<ProductBatch>? batches,
    this.isService = false,
    this.durationMinutes,
    this.reorderLevel,
    this.reorderQuantity,
    this.preferredSupplierId,
    this.costPrice = 0.0,
    this.defaultDiscountPercent = 0,
    this.imageUrl,
    this.trackSerialNumbers = false,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       batches = batches ?? [];

  /// Returns the display UOM — custom label if set, otherwise the unit code.
  String get displayUom =>
      (unit == 'custom' && customUomLabel != null) ? customUomLabel! : unit;

  bool get isLowStock => isService
      ? false
      : stockQuantity > 0 && stockQuantity <= lowStockThreshold;
  bool get isOutOfStock => isService ? false : stockQuantity <= 0;
  double get profitAmount => sellingPrice - costPrice;
  double get profitMarginPercent =>
      sellingPrice > 0 ? (profitAmount / sellingPrice) * 100 : 0;

  bool get needsReorder =>
      !isService && reorderLevel != null && stockQuantity <= reorderLevel!;

  int get totalBatchStock => batches.fold(0, (sum, b) => sum + b.stockQuantity);

  List<ProductBatch> get availableBatches {
    final available =
        batches.where((b) => !b.isExpired && b.stockQuantity > 0).toList()
          ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return available;
  }

  ProductBatch? get nearestExpiryBatch {
    final available = availableBatches;
    return available.isEmpty ? null : available.first;
  }

  Product copyWith({
    String? name,
    Object? barcode = _unset,
    double? sellingPrice,
    int? stockQuantity,
    String? category,
    String? unit,
    Object? customUomLabel = _unset,
    double? minQuantity,
    double? quantityStep,
    Object? hsnCode = _unset,
    double? gstRate,
    bool? gstInclusivePrice,
    int? gstSlabPercent,
    int? lowStockThreshold,
    List<ProductBatch>? batches,
    bool? isService,
    int? durationMinutes,
    Object? reorderLevel = _unset,
    Object? reorderQuantity = _unset,
    Object? preferredSupplierId = _unset,
    double? costPrice,
    double? defaultDiscountPercent,
    Object? imageUrl = _unset,
    bool? trackSerialNumbers,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      barcode: identical(barcode, _unset) ? this.barcode : barcode as String?,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      customUomLabel: identical(customUomLabel, _unset)
          ? this.customUomLabel
          : customUomLabel as String?,
      minQuantity: minQuantity ?? this.minQuantity,
      quantityStep: quantityStep ?? this.quantityStep,
      hsnCode: identical(hsnCode, _unset) ? this.hsnCode : hsnCode as String?,
      gstRate: gstRate ?? this.gstRate,
      gstInclusivePrice: gstInclusivePrice ?? this.gstInclusivePrice,
      gstSlabPercent: gstSlabPercent ?? this.gstSlabPercent,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt,
      batches: batches ?? this.batches,
      isService: isService ?? this.isService,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      reorderLevel: identical(reorderLevel, _unset)
          ? this.reorderLevel
          : reorderLevel as double?,
      reorderQuantity: identical(reorderQuantity, _unset)
          ? this.reorderQuantity
          : reorderQuantity as double?,
      preferredSupplierId: identical(preferredSupplierId, _unset)
          ? this.preferredSupplierId
          : preferredSupplierId as String?,
      costPrice: costPrice ?? this.costPrice,
      defaultDiscountPercent:
          defaultDiscountPercent ?? this.defaultDiscountPercent,
      imageUrl: identical(imageUrl, _unset) ? this.imageUrl : imageUrl as String?,
      trackSerialNumbers: trackSerialNumbers ?? this.trackSerialNumbers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'category': category,
      'unit': unit,
      'customUomLabel': customUomLabel,
      'minQuantity': minQuantity,
      'quantityStep': quantityStep,
      'hsnCode': hsnCode,
      'gstRate': gstRate,
      'gstInclusivePrice': gstInclusivePrice,
      'gstSlabPercent': gstSlabPercent,
      'lowStockThreshold': lowStockThreshold,
      'createdAt': createdAt.toIso8601String(),
      'batches': batches.map((b) => b.toJson()).toList(),
      'isService': isService,
      'durationMinutes': durationMinutes,
      'reorderLevel': reorderLevel,
      'reorderQuantity': reorderQuantity,
      'preferredSupplierId': preferredSupplierId,
      'costPrice': costPrice,
      'defaultDiscountPercent': defaultDiscountPercent,
      'imageUrl': imageUrl,
      'trackSerialNumbers': trackSerialNumbers,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final batchJson = json['batches'] as List<dynamic>? ?? const [];
    return Product(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      barcode: JsonHelpers.nullableString(json['barcode']),
      sellingPrice: JsonHelpers.asDouble(json['sellingPrice']),
      stockQuantity: JsonHelpers.asInt(json['stockQuantity']),
      category: json['category'] as String?,
      unit: json['unit'] as String? ?? 'pcs',
      customUomLabel: JsonHelpers.nullableString(json['customUomLabel']),
      minQuantity: JsonHelpers.asDouble(json['minQuantity'], fallback: 1.0),
      quantityStep: JsonHelpers.asDouble(json['quantityStep'], fallback: 1.0),
      hsnCode: JsonHelpers.nullableString(json['hsnCode']),
      gstRate: JsonHelpers.asDouble(json['gstRate']),
      gstInclusivePrice: json['gstInclusivePrice'] as bool? ?? false,
      gstSlabPercent: JsonHelpers.asInt(json['gstSlabPercent']),
      lowStockThreshold: JsonHelpers.asInt(json['lowStockThreshold'], fallback: 10),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      batches: batchJson
          .whereType<Map<String, dynamic>>()
          .map(ProductBatch.fromJson)
          .toList(),
      isService: json['isService'] as bool? ?? false,
      durationMinutes: JsonHelpers.nullableInt(json['durationMinutes']),
      reorderLevel: JsonHelpers.nullableDouble(json['reorderLevel']),
      reorderQuantity: JsonHelpers.nullableDouble(json['reorderQuantity']),
      preferredSupplierId: JsonHelpers.nullableString(json['preferredSupplierId']),
      costPrice: JsonHelpers.asDouble(json['costPrice']),
      defaultDiscountPercent: JsonHelpers.asDouble(json['defaultDiscountPercent']),
      imageUrl: JsonHelpers.nullableString(json['imageUrl']),
      trackSerialNumbers: json['trackSerialNumbers'] as bool? ?? false,
    );
  }
}
