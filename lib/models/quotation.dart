import 'package:uuid/uuid.dart';
import 'customer.dart';
import 'line_item.dart';
import '../core/utils/json_helpers.dart';

enum QuotationStatus { draft, sent, approved, rejected, expired, converted }

extension QuotationStatusX on QuotationStatus {
  String get label {
    switch (this) {
      case QuotationStatus.draft:
        return 'Draft';
      case QuotationStatus.sent:
        return 'Sent';
      case QuotationStatus.approved:
        return 'Approved';
      case QuotationStatus.rejected:
        return 'Rejected';
      case QuotationStatus.expired:
        return 'Expired';
      case QuotationStatus.converted:
        return 'Converted';
    }
  }
}

class Quotation {
  final String id;
  final String quotationNumber;
  final DateTime date;
  final DateTime validUntil;
  final String? customerId;
  final String? customerName;
  final Customer? customer;
  final List<LineItem> items;
  final String? notes;
  final QuotationStatus status;
  final String? convertedToBillId;
  final String? createdBy;
  final String? customerPhone;
  // Workshop vehicle details
  final String? vehicleReg;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? kmReading;
  final double subtotal;
  final double discount;
  final double cgst;
  final double sgst;
  final double igst;
  final double grandTotal;
  final bool isInterState;

  Quotation({
    String? id,
    required this.quotationNumber,
    DateTime? date,
    DateTime? validUntil,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customer,
    this.items = const [],
    this.notes,
    this.status = QuotationStatus.draft,
    this.convertedToBillId,
    this.createdBy,
    this.vehicleReg,
    this.vehicleMake,
    this.vehicleModel,
    this.kmReading,
    this.subtotal = 0,
    this.discount = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    this.grandTotal = 0,
    this.isInterState = false,
  }) : id = id ?? const Uuid().v4(),
       date = date ?? DateTime.now(),
       validUntil =
           validUntil ?? (date ?? DateTime.now()).add(const Duration(days: 7));

  bool get isExpired =>
      status != QuotationStatus.converted &&
      status != QuotationStatus.rejected &&
      DateTime.now().isAfter(validUntil);

  bool get canConvert => status == QuotationStatus.approved;

  Quotation copyWith({
    String? quotationNumber,
    DateTime? date,
    DateTime? validUntil,
    String? customerId,
    String? customerName,
    String? customerPhone,
    Customer? customer,
    List<LineItem>? items,
    String? notes,
    QuotationStatus? status,
    String? convertedToBillId,
    String? createdBy,
    String? vehicleReg,
    String? vehicleMake,
    String? vehicleModel,
    String? kmReading,
    double? subtotal,
    double? discount,
    double? cgst,
    double? sgst,
    double? igst,
    double? grandTotal,
    bool? isInterState,
  }) {
    return Quotation(
      id: id,
      quotationNumber: quotationNumber ?? this.quotationNumber,
      date: date ?? this.date,
      validUntil: validUntil ?? this.validUntil,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      convertedToBillId: convertedToBillId ?? this.convertedToBillId,
      createdBy: createdBy ?? this.createdBy,
      vehicleReg: vehicleReg ?? this.vehicleReg,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      kmReading: kmReading ?? this.kmReading,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
      grandTotal: grandTotal ?? this.grandTotal,
      isInterState: isInterState ?? this.isInterState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Quotation && other.id == id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quotationNumber': quotationNumber,
      'date': date.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customer': customer?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'notes': notes,
      'status': status.name,
      'convertedToBillId': convertedToBillId,
      'createdBy': createdBy,
      'vehicleReg': vehicleReg,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'kmReading': kmReading,
      'subtotal': subtotal,
      'discount': discount,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
      'grandTotal': grandTotal,
      'isInterState': isInterState,
    };
  }

  @override
  String toString() =>
      'Quotation(number: $quotationNumber, total: $grandTotal, status: ${status.label})';

  factory Quotation.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? const [];
    return Quotation(
      id: json['id'] as String?,
      quotationNumber: json['quotationNumber'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      validUntil: DateTime.tryParse(json['validUntil'] as String? ?? ''),
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customer: _customerFromJson(json['customer']),
      items: itemsJson.map(_lineItemFromJson).toList(),
      notes: json['notes'] as String?,
      status: _statusFromString(json['status'] as String?),
      convertedToBillId: json['convertedToBillId'] as String?,
      createdBy: json['createdBy'] as String?,
      vehicleReg: json['vehicleReg'] as String?,
      vehicleMake: json['vehicleMake'] as String?,
      vehicleModel: json['vehicleModel'] as String?,
      kmReading: json['kmReading'] as String?,
      subtotal: JsonHelpers.asDouble(json['subtotal']),
      discount: JsonHelpers.asDouble(json['discount']),
      cgst: JsonHelpers.asDouble(json['cgst']),
      sgst: JsonHelpers.asDouble(json['sgst']),
      igst: JsonHelpers.asDouble(json['igst']),
      grandTotal: JsonHelpers.asDouble(json['grandTotal']),
      isInterState: json['isInterState'] as bool? ?? false,
    );
  }

  static QuotationStatus _statusFromString(String? value) {
    if (value == null) return QuotationStatus.draft;
    for (final s in QuotationStatus.values) {
      if (s.name == value) return s;
    }
    return QuotationStatus.draft;
  }

  static Customer? _customerFromJson(dynamic value) {
    if (value is Map<String, dynamic>) return Customer.fromJson(value);
    if (value is Map) return Customer.fromJson(value.cast<String, dynamic>());
    return null;
  }

  static LineItem _lineItemFromJson(dynamic value) {
    if (value is Map<String, dynamic>) return LineItem.fromJson(value);
    if (value is Map) return LineItem.fromJson(value.cast<String, dynamic>());
    return LineItem.fromJson(const <String, dynamic>{});
  }

}
