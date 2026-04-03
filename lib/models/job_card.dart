import 'package:uuid/uuid.dart';

enum JobStatus {
  received,
  diagnosed,
  inProgress,
  readyForPickup,
  delivered,
  cancelled,
}

extension JobStatusLabel on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.received:
        return 'Received';
      case JobStatus.diagnosed:
        return 'Diagnosed';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.readyForPickup:
        return 'Ready for Pickup';
      case JobStatus.delivered:
        return 'Delivered';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  JobStatus? get next {
    switch (this) {
      case JobStatus.received:
        return JobStatus.diagnosed;
      case JobStatus.diagnosed:
        return JobStatus.inProgress;
      case JobStatus.inProgress:
        return JobStatus.readyForPickup;
      case JobStatus.readyForPickup:
        return JobStatus.delivered;
      case JobStatus.delivered:
      case JobStatus.cancelled:
        return null;
    }
  }
}

enum JobLineItemType { part, labour }

class JobLineItem {
  final String id;
  final JobLineItemType type;
  final String description;
  double quantity;
  double unitPrice;

  JobLineItem({
    String? id,
    required this.type,
    required this.description,
    this.quantity = 1,
    required this.unitPrice,
  }) : id = id ?? const Uuid().v4();

  double get total => quantity * unitPrice;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory JobLineItem.fromJson(Map<String, dynamic> json) {
    return JobLineItem(
      id: json['id'] as String?,
      type: _typeFromString(json['type'] as String?),
      description: json['description'] as String? ?? '',
      quantity: _asDouble(json['quantity'], fallback: 1),
      unitPrice: _asDouble(json['unitPrice']),
    );
  }

  static JobLineItemType _typeFromString(String? value) {
    for (final t in JobLineItemType.values) {
      if (t.name == value) return t;
    }
    return JobLineItemType.part;
  }

  static double _asDouble(dynamic v, {double fallback = 0}) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }
}

class JobCard {
  final String id;
  final String jobNumber;
  final String vehicleReg;
  final String vehicleMake;
  final String vehicleModel;
  final String kmReading;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String problemDescription;
  final String? diagnosis;
  final List<JobLineItem> items;
  final JobStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? estimatedCost;

  JobCard({
    String? id,
    required this.jobNumber,
    required this.vehicleReg,
    this.vehicleMake = '',
    this.vehicleModel = '',
    this.kmReading = '',
    this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.problemDescription,
    this.diagnosis,
    List<JobLineItem>? items,
    this.status = JobStatus.received,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.estimatedCost,
  }) : id = id ?? const Uuid().v4(),
       items = items ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get totalCost => items.fold(0, (sum, i) => sum + i.total);

  List<JobLineItem> get parts =>
      items.where((i) => i.type == JobLineItemType.part).toList();

  List<JobLineItem> get labourItems =>
      items.where((i) => i.type == JobLineItemType.labour).toList();

  JobCard copyWith({
    String? vehicleReg,
    String? vehicleMake,
    String? vehicleModel,
    String? kmReading,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? problemDescription,
    String? diagnosis,
    List<JobLineItem>? items,
    JobStatus? status,
    DateTime? updatedAt,
    double? estimatedCost,
  }) {
    return JobCard(
      id: id,
      jobNumber: jobNumber,
      vehicleReg: vehicleReg ?? this.vehicleReg,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      kmReading: kmReading ?? this.kmReading,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      problemDescription: problemDescription ?? this.problemDescription,
      diagnosis: diagnosis ?? this.diagnosis,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobNumber': jobNumber,
      'vehicleReg': vehicleReg,
      'vehicleMake': vehicleMake,
      'vehicleModel': vehicleModel,
      'kmReading': kmReading,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'problemDescription': problemDescription,
      'diagnosis': diagnosis,
      'items': items.map((i) => i.toJson()).toList(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'estimatedCost': estimatedCost,
    };
  }

  factory JobCard.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return JobCard(
      id: json['id'] as String?,
      jobNumber: json['jobNumber'] as String? ?? '',
      vehicleReg: json['vehicleReg'] as String? ?? '',
      vehicleMake: json['vehicleMake'] as String? ?? '',
      vehicleModel: json['vehicleModel'] as String? ?? '',
      kmReading: json['kmReading'] as String? ?? '',
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      problemDescription: json['problemDescription'] as String? ?? '',
      diagnosis: json['diagnosis'] as String?,
      items: rawItems
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => JobLineItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      status: _statusFromString(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      estimatedCost: json['estimatedCost'] as double?,
    );
  }

  static JobStatus _statusFromString(String? value) {
    for (final s in JobStatus.values) {
      if (s.name == value) return s;
    }
    return JobStatus.received;
  }
}
