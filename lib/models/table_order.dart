import 'package:uuid/uuid.dart';
import 'line_item.dart';

enum TableOrderStatus { active, billed, cancelled }

class TableOrder {
  final String id;
  final String tableLabel;
  final String? customerName;
  final List<LineItem> items;
  final TableOrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  TableOrder({
    String? id,
    required this.tableLabel,
    this.customerName,
    List<LineItem>? items,
    this.status = TableOrderStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       items = items ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);

  TableOrder copyWith({
    String? tableLabel,
    String? customerName,
    List<LineItem>? items,
    TableOrderStatus? status,
    DateTime? updatedAt,
  }) {
    return TableOrder(
      id: id,
      tableLabel: tableLabel ?? this.tableLabel,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableLabel': tableLabel,
      'customerName': customerName,
      'items': items.map((i) => i.toJson()).toList(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TableOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return TableOrder(
      id: json['id'] as String?,
      tableLabel: json['tableLabel'] as String? ?? '',
      customerName: json['customerName'] as String?,
      items: rawItems
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => LineItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      status: _statusFromString(json['status'] as String?),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  static TableOrderStatus _statusFromString(String? value) {
    for (final s in TableOrderStatus.values) {
      if (s.name == value) return s;
    }
    return TableOrderStatus.active;
  }
}
