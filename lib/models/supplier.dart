import 'package:uuid/uuid.dart';
import '../core/utils/json_helpers.dart';

class Supplier {
  final String id;
  final String name;
  final String? phone;
  final String? gstin;
  final String? address;
  final List<String> productCategories;
  final double outstandingPayable;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  Supplier({
    String? id,
    required this.name,
    this.phone,
    this.gstin,
    this.address,
    this.productCategories = const [],
    this.outstandingPayable = 0,
    this.notes,
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Supplier copyWith({
    String? name,
    String? phone,
    String? gstin,
    String? address,
    List<String>? productCategories,
    double? outstandingPayable,
    String? notes,
    bool? isActive,
  }) {
    return Supplier(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      productCategories: productCategories ?? this.productCategories,
      outstandingPayable: outstandingPayable ?? this.outstandingPayable,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Supplier && other.id == id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'gstin': gstin,
      'address': address,
      'productCategories': productCategories,
      'outstandingPayable': outstandingPayable,
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Supplier(id: $id, name: $name, payable: $outstandingPayable)';

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      gstin: json['gstin'] as String?,
      address: json['address'] as String?,
      productCategories: (json['productCategories'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      outstandingPayable: JsonHelpers.asDouble(json['outstandingPayable']),
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}
