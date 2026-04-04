import 'package:flutter/foundation.dart';
import '../models/line_item.dart';
import '../models/table_order.dart';
import '../services/db_service.dart';

class TableOrderProvider extends ChangeNotifier {
  final List<TableOrder> _orders = [];
  final VoidCallback? _onChanged;

  DbService? dbService;

  TableOrderProvider({
    List<TableOrder>? initialOrders,
    VoidCallback? onChanged,
  }) : _onChanged = onChanged {
    if (initialOrders != null) {
      _orders.addAll(initialOrders);
    }
  }

  List<TableOrder> get orders => List.unmodifiable(_orders);

  List<TableOrder> get activeOrders =>
      _orders.where((o) => o.status == TableOrderStatus.active).toList();

  TableOrder? getActiveOrder(String tableLabel) {
    try {
      return _orders.firstWhere(
        (o) =>
            o.tableLabel == tableLabel && o.status == TableOrderStatus.active,
      );
    } catch (_) {
      return null;
    }
  }

  TableOrder createOrder(String tableLabel, {String? customerName}) {
    final order = TableOrder(
      tableLabel: tableLabel,
      customerName: customerName,
    );
    _orders.add(order);
    dbService?.saveTableOrders([order]);
    _persistAndNotify();
    return order;
  }

  void addItemToOrder(String orderId, LineItem item) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final order = _orders[idx];
    final existingIdx = order.items.indexWhere(
      (i) => i.product.id == item.product.id,
    );
    final updatedItems = List<LineItem>.from(order.items);
    if (existingIdx >= 0) {
      updatedItems[existingIdx] = updatedItems[existingIdx].copyWith(
        quantity: updatedItems[existingIdx].quantity + item.quantity,
      );
    } else {
      updatedItems.add(item);
    }
    _orders[idx] = order.copyWith(items: updatedItems);
    dbService?.saveTableOrders([_orders[idx]]);
    _persistAndNotify();
  }

  void removeItemFromOrder(String orderId, String productId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final order = _orders[idx];
    final updatedItems = order.items
        .where((i) => i.product.id != productId)
        .toList();
    _orders[idx] = order.copyWith(items: updatedItems);
    dbService?.saveTableOrders([_orders[idx]]);
    _persistAndNotify();
  }

  void updateItemQuantity(String orderId, String productId, double quantity) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    final order = _orders[idx];
    final updatedItems = List<LineItem>.from(order.items);
    final itemIdx = updatedItems.indexWhere((i) => i.product.id == productId);
    if (itemIdx == -1) return;
    if (quantity <= 0) {
      updatedItems.removeAt(itemIdx);
    } else {
      updatedItems[itemIdx] = updatedItems[itemIdx].copyWith(quantity: quantity);
    }
    _orders[idx] = order.copyWith(items: updatedItems);
    dbService?.saveTableOrders([_orders[idx]]);
    _persistAndNotify();
  }

  void markAsBilled(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    _orders[idx] = _orders[idx].copyWith(status: TableOrderStatus.billed);
    dbService?.saveTableOrders([_orders[idx]]);
    _persistAndNotify();
  }

  void cancelOrder(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;
    _orders[idx] = _orders[idx].copyWith(status: TableOrderStatus.cancelled);
    dbService?.saveTableOrders([_orders[idx]]);
    _persistAndNotify();
  }

  void clearAllData() {
    _orders.clear();
    _persistAndNotify();
  }

  void _persistAndNotify() {
    _onChanged?.call();
    notifyListeners();
  }
}
