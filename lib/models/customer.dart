import 'package:uuid/uuid.dart';
import '../core/utils/json_helpers.dart';

class CustomerVehicle {
  final String id;
  final String reg;
  final String? make;
  final String? model;
  final String? lastKmReading;

  CustomerVehicle({
    String? id,
    required this.reg,
    this.make,
    this.model,
    this.lastKmReading,
  }) : id = id ?? const Uuid().v4();

  CustomerVehicle copyWith({
    String? reg,
    String? make,
    String? model,
    String? lastKmReading,
  }) {
    return CustomerVehicle(
      id: id,
      reg: reg ?? this.reg,
      make: make ?? this.make,
      model: model ?? this.model,
      lastKmReading: lastKmReading ?? this.lastKmReading,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'reg': reg,
    'make': make,
    'model': model,
    'lastKmReading': lastKmReading,
  };

  factory CustomerVehicle.fromJson(Map<String, dynamic> json) =>
      CustomerVehicle(
        id: json['id'] as String?,
        reg: json['reg'] as String? ?? '',
        make: json['make'] as String?,
        model: json['model'] as String?,
        lastKmReading: json['lastKmReading'] as String?,
      );
}

class Customer {
  final String id;
  final String name;
  final String? phone;
  final double outstandingBalance;
  final double advanceBalance;
  final DateTime createdAt;
  final int? age;
  final String? gender;
  final String? bloodGroup;
  final String? gstin;
  final String? allergies;
  final String? medicalNotes;
  final double defaultDiscountPercent;
  final List<CustomerVehicle> vehicles;
  final DateTime? lastCreditDate;

  Customer({
    String? id,
    required this.name,
    this.phone,
    this.outstandingBalance = 0,
    this.advanceBalance = 0,
    DateTime? createdAt,
    this.age,
    this.gender,
    this.gstin,
    this.bloodGroup,
    this.allergies,
    this.medicalNotes,
    this.defaultDiscountPercent = 0,
    List<CustomerVehicle>? vehicles,
    this.lastCreditDate,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       vehicles = vehicles ?? const [];

  Customer copyWith({
    String? name,
    String? phone,
    double? outstandingBalance,
    double? advanceBalance,
    int? age,
    String? gender,
    String? gstin,
    String? bloodGroup,
    String? allergies,
    String? medicalNotes,
    double? defaultDiscountPercent,
    List<CustomerVehicle>? vehicles,
    DateTime? lastCreditDate,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      advanceBalance: advanceBalance ?? this.advanceBalance,
      createdAt: createdAt,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      gstin: gstin ?? this.gstin,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      defaultDiscountPercent:
          defaultDiscountPercent ?? this.defaultDiscountPercent,
      vehicles: vehicles ?? this.vehicles,
      lastCreditDate: lastCreditDate ?? this.lastCreditDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Customer && other.id == id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'outstandingBalance': outstandingBalance,
      'advanceBalance': advanceBalance,
      'createdAt': createdAt.toIso8601String(),
      'age': age,
      'gender': gender,
      'gstin': gstin,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'medicalNotes': medicalNotes,
      'defaultDiscountPercent': defaultDiscountPercent,
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      if (lastCreditDate != null) 'lastCreditDate': lastCreditDate!.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Customer(id: $id, name: $name, balance: $outstandingBalance)';

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      outstandingBalance: JsonHelpers.asDouble(json['outstandingBalance']),
      advanceBalance: JsonHelpers.asDouble(json['advanceBalance']),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      age: JsonHelpers.nullableInt(json['age']),
      gender: json['gender'] as String?,
      gstin: json['gstin'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      allergies: json['allergies'] as String?,
      medicalNotes: json['medicalNotes'] as String?,
      defaultDiscountPercent: JsonHelpers.asDouble(json['defaultDiscountPercent']),
      vehicles: _vehicleList(json['vehicles']),
      lastCreditDate: DateTime.tryParse(json['lastCreditDate'] as String? ?? ''),
    );
  }

  static List<CustomerVehicle> _vehicleList(dynamic value) {
    final list = value as List<dynamic>? ?? const [];
    return list
        .whereType<Map>()
        .map((m) => CustomerVehicle.fromJson(m.cast<String, dynamic>()))
        .toList();
  }
}
