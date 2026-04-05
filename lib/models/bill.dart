import 'package:uuid/uuid.dart';
import 'line_item.dart';
import 'customer.dart';
import 'payment_info.dart';
import '../core/utils/json_helpers.dart';

class Bill {
  final String id;
  final String billNumber;
  final List<LineItem> lineItems;
  final double subtotal;
  final double discount;
  final double billDiscountPercent;
  final double totalLineDiscount;
  final double cgst;
  final double sgst;
  final double igst;
  final double grandTotal;
  final bool isInterState;
  final PaymentMode paymentMode;
  final double amountReceived;
  final double creditAmount;
  final Customer? customer;
  final DateTime timestamp;
  final String? diagnosis;
  final String? visitNotes;
  // Workshop vehicle details
  final String? vehicleReg;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? kmReading;
  // Split payment
  final double? splitCashAmount;
  final double? splitUpiAmount;
  // Advance payment
  final double advanceUsed;

  Bill({
    String? id,
    required this.billNumber,
    required this.lineItems,
    required this.subtotal,
    this.discount = 0,
    this.billDiscountPercent = 0,
    this.totalLineDiscount = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    required this.grandTotal,
    this.isInterState = false,
    required this.paymentMode,
    this.amountReceived = 0,
    this.creditAmount = 0,
    this.customer,
    DateTime? timestamp,
    this.diagnosis,
    this.visitNotes,
    this.vehicleReg,
    this.vehicleMake,
    this.vehicleModel,
    this.kmReading,
    this.splitCashAmount,
    this.splitUpiAmount,
    this.advanceUsed = 0,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  int get itemCount => lineItems.fold(0, (sum, item) => sum + item.quantity.ceil());

  /// Total discount given (bill-level + all line-level).
  double get totalDiscount => discount + totalLineDiscount;

  Bill copyWith({
    String? id,
    String? billNumber,
    List<LineItem>? lineItems,
    double? subtotal,
    double? discount,
    double? billDiscountPercent,
    double? totalLineDiscount,
    double? cgst,
    double? sgst,
    double? igst,
    double? grandTotal,
    bool? isInterState,
    PaymentMode? paymentMode,
    double? amountReceived,
    double? creditAmount,
    Customer? customer,
    DateTime? timestamp,
    String? diagnosis,
    String? visitNotes,
    String? vehicleReg,
    String? vehicleMake,
    String? vehicleModel,
    String? kmReading,
    double? splitCashAmount,
    double? splitUpiAmount,
    double? advanceUsed,
  }) {
    return Bill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      billDiscountPercent: billDiscountPercent ?? this.billDiscountPercent,
      totalLineDiscount: totalLineDiscount ?? this.totalLineDiscount,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      grandTotal: grandTotal ?? this.grandTotal,
      isInterState: isInterState ?? this.isInterState,
      paymentMode: paymentMode ?? this.paymentMode,
      amountReceived: amountReceived ?? this.amountReceived,
      creditAmount: creditAmount ?? this.creditAmount,
      customer: customer ?? this.customer,
      timestamp: timestamp ?? this.timestamp,
      diagnosis: diagnosis ?? this.diagnosis,
      visitNotes: visitNotes ?? this.visitNotes,
      vehicleReg: vehicleReg ?? this.vehicleReg,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      kmReading: kmReading ?? this.kmReading,
      splitCashAmount: splitCashAmount ?? this.splitCashAmount,
      splitUpiAmount: splitUpiAmount ?? this.splitUpiAmount,
      advanceUsed: advanceUsed ?? this.advanceUsed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Bill && other.id == id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'billNumber': billNumber,
      'lineItems': lineItems.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'billDiscountPercent': billDiscountPercent,
      'totalLineDiscount': totalLineDiscount,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'grandTotal': grandTotal,
      'isInterState': isInterState,
      'paymentMode': paymentMode.name,
      'amountReceived': amountReceived,
      'creditAmount': creditAmount,
      'customer': customer?.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'diagnosis': diagnosis,
      'visitNotes': visitNotes,
      'vehicleReg': vehicleReg,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'kmReading': kmReading,
      'splitCashAmount': splitCashAmount,
      'splitUpiAmount': splitUpiAmount,
      'advanceUsed': advanceUsed,
    };
  }

  @override
  String toString() =>
      'Bill(billNumber: $billNumber, total: $grandTotal, mode: $paymentMode)';

  factory Bill.fromJson(Map<String, dynamic> json) {
    final lineItemJson = json['lineItems'] as List<dynamic>? ?? const [];
    return Bill(
      id: json['id'] as String?,
      billNumber: json['billNumber'] as String? ?? '',
      lineItems: lineItemJson.map(_lineItemFromJson).toList(),
      subtotal: JsonHelpers.asDouble(json['subtotal']),
      discount: JsonHelpers.asDouble(json['discount']),
      billDiscountPercent: JsonHelpers.asDouble(json['billDiscountPercent']),
      totalLineDiscount: JsonHelpers.asDouble(json['totalLineDiscount']),
      cgst: JsonHelpers.asDouble(json['cgst']),
      sgst: JsonHelpers.asDouble(json['sgst']),
      igst: JsonHelpers.asDouble(json['igst']),
      grandTotal: JsonHelpers.asDouble(json['grandTotal']),
      isInterState: json['isInterState'] as bool? ?? false,
      paymentMode: PaymentMethodX.fromString(json['paymentMode'] as String?),
      amountReceived: JsonHelpers.asDouble(json['amountReceived']),
      creditAmount: JsonHelpers.asDouble(json['creditAmount']),
      customer: _customerFromJson(json['customer']),
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? ''),
      diagnosis: json['diagnosis'] as String?,
      visitNotes: json['visitNotes'] as String?,
      vehicleReg: json['vehicleReg'] as String?,
      vehicleMake: json['vehicleMake'] as String?,
      vehicleModel: json['vehicleModel'] as String?,
      kmReading: json['kmReading'] as String?,
      splitCashAmount: json['splitCashAmount'] != null
          ? JsonHelpers.asDouble(json['splitCashAmount'])
          : null,
      splitUpiAmount: json['splitUpiAmount'] != null
          ? JsonHelpers.asDouble(json['splitUpiAmount'])
          : null,
      advanceUsed: JsonHelpers.asDouble(json['advanceUsed']),
    );
  }

  static LineItem _lineItemFromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return LineItem.fromJson(value);
    }
    if (value is Map) {
      return LineItem.fromJson(value.cast<String, dynamic>());
    }
    return LineItem.fromJson(const <String, dynamic>{});
  }

  static Customer? _customerFromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Customer.fromJson(value);
    }
    if (value is Map) {
      return Customer.fromJson(value.cast<String, dynamic>());
    }
    return null;
  }

}
