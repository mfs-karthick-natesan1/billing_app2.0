import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/table_order.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/table_order_provider.dart';
import 'helpers/test_fixtures.dart';

void main() {
  late ProductProvider productProvider;
  late BillProvider billProvider;
  late CustomerProvider customerProvider;
  late TableOrderProvider tableOrderProvider;

  setUp(() {
    productProvider = ProductProvider();
    billProvider = BillProvider();
    customerProvider = CustomerProvider();
    tableOrderProvider = TableOrderProvider();
  });

  group('Restaurant — Table Order Flow', () {
    test('create table order → add items → mark billed', () {
      final product1 = restaurantProduct(
        id: 'paneer-tikka',
        name: 'Paneer Tikka',
        sellingPrice: 220,
      );
      final product2 = restaurantProduct(
        id: 'dal-makhani',
        name: 'Dal Makhani',
        sellingPrice: 180,
      );
      productProvider.addProduct(product1);
      productProvider.addProduct(product2);

      // Create order for Table 1
      final order = tableOrderProvider.createOrder('Table 1');
      expect(order.tableLabel, 'Table 1');
      expect(order.status, TableOrderStatus.active);
      expect(order.items, isEmpty);

      // Add items
      tableOrderProvider.addItemToOrder(
        order.id,
        LineItem(product: product1, quantity: 2),
      );
      tableOrderProvider.addItemToOrder(
        order.id,
        LineItem(product: product2, quantity: 1),
      );

      // Verify items
      final updatedOrder = tableOrderProvider.orders.first;
      expect(updatedOrder.items.length, 2);
      expect(updatedOrder.items[0].product.id, 'paneer-tikka');
      expect(updatedOrder.items[0].quantity, 2);
      expect(updatedOrder.items[1].product.id, 'dal-makhani');
      expect(updatedOrder.items[1].quantity, 1);

      // Mark as billed
      tableOrderProvider.markAsBilled(order.id);
      final billedOrder = tableOrderProvider.orders.first;
      expect(billedOrder.status, TableOrderStatus.billed);
    });

    test('duplicate product in order → quantities combined', () {
      final product = restaurantProduct(
        id: 'naan',
        name: 'Butter Naan',
        sellingPrice: 50,
      );
      productProvider.addProduct(product);

      final order = tableOrderProvider.createOrder('Table 2');

      // Add same product twice
      tableOrderProvider.addItemToOrder(
        order.id,
        LineItem(product: product, quantity: 2),
      );
      tableOrderProvider.addItemToOrder(
        order.id,
        LineItem(product: product, quantity: 3),
      );

      // Should be a single item with combined quantity
      final updatedOrder = tableOrderProvider.orders.first;
      expect(updatedOrder.items.length, 1);
      expect(updatedOrder.items.first.quantity, 5); // 2 + 3
    });

    test('remove item from order', () {
      final product1 = restaurantProduct(
        id: 'biryani',
        name: 'Biryani',
        sellingPrice: 250,
      );
      final product2 = restaurantProduct(
        id: 'raita',
        name: 'Raita',
        sellingPrice: 40,
      );
      productProvider.addProduct(product1);
      productProvider.addProduct(product2);

      final order = tableOrderProvider.createOrder('Table 3');
      tableOrderProvider.addItemToOrder(
        order.id,
        LineItem(product: product1, quantity: 1),
      );
      tableOrderProvider.addItemToOrder(
        order.id,
        LineItem(product: product2, quantity: 1),
      );

      expect(tableOrderProvider.orders.first.items.length, 2);

      // Remove biryani
      tableOrderProvider.removeItemFromOrder(order.id, 'biryani');

      final updatedOrder = tableOrderProvider.orders.first;
      expect(updatedOrder.items.length, 1);
      expect(updatedOrder.items.first.product.id, 'raita');
    });

    test('table order → create bill from order items', () {
      final product1 = restaurantProduct(
        id: 'tikka-masala',
        name: 'Tikka Masala',
        sellingPrice: 260,
        gstRate: 5.0,
      );
      final product2 = restaurantProduct(
        id: 'garlic-naan',
        name: 'Garlic Naan',
        sellingPrice: 60,
        gstRate: 5.0,
      );
      productProvider.addProduct(product1);
      productProvider.addProduct(product2);

      // Create table order and add items
      final order = tableOrderProvider.createOrder('Table 4');
      tableOrderProvider.addItemToOrder(
        order.id,
        LineItem(product: product1, quantity: 2),
      );
      tableOrderProvider.addItemToOrder(
        order.id,
        LineItem(product: product2, quantity: 3),
      );

      // Get the order items and create a bill from them
      final tableOrder = tableOrderProvider.orders.first;
      for (final item in tableOrder.items) {
        billProvider.addItemToBill(item.product);
        // Update to match the table order quantity
        final idx = billProvider.activeLineItems.indexWhere(
          (li) => li.product.id == item.product.id,
        );
        billProvider.updateQuantity(idx, item.quantity);
      }

      expect(billProvider.activeLineItems.length, 2);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(amountReceived: 800),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Subtotal = (260 * 2) + (60 * 3) = 520 + 180 = 700
      expect(bill.subtotal, 700);
      expect(bill.lineItems.length, 2);

      // Mark the table order as billed
      tableOrderProvider.markAsBilled(order.id);
      expect(
        tableOrderProvider.orders.first.status,
        TableOrderStatus.billed,
      );
    });
  });

  group('Restaurant — Multi-Table', () {
    test('multiple active orders on different tables', () {
      final product = restaurantProduct(
        id: 'chai',
        name: 'Masala Chai',
        sellingPrice: 30,
      );
      productProvider.addProduct(product);

      final order1 = tableOrderProvider.createOrder('Table 1');
      final order2 = tableOrderProvider.createOrder('Table 2');
      final order3 = tableOrderProvider.createOrder('Table 3');

      tableOrderProvider.addItemToOrder(
        order1.id,
        LineItem(product: product, quantity: 2),
      );
      tableOrderProvider.addItemToOrder(
        order2.id,
        LineItem(product: product, quantity: 4),
      );
      tableOrderProvider.addItemToOrder(
        order3.id,
        LineItem(product: product, quantity: 1),
      );

      // All three should be active
      expect(tableOrderProvider.activeOrders.length, 3);

      // Mark one as billed
      tableOrderProvider.markAsBilled(order2.id);
      expect(tableOrderProvider.activeOrders.length, 2);

      // Cancel another
      tableOrderProvider.cancelOrder(order3.id);
      expect(tableOrderProvider.activeOrders.length, 1);
      expect(tableOrderProvider.activeOrders.first.tableLabel, 'Table 1');
    });

    test('getActiveOrder returns correct order per table', () {
      final product = restaurantProduct(
        id: 'lassi',
        name: 'Mango Lassi',
        sellingPrice: 60,
      );
      productProvider.addProduct(product);

      tableOrderProvider.createOrder('Table A');
      tableOrderProvider.createOrder('Table B');

      // getActiveOrder finds the right table
      final orderA = tableOrderProvider.getActiveOrder('Table A');
      final orderB = tableOrderProvider.getActiveOrder('Table B');
      final orderC = tableOrderProvider.getActiveOrder('Table C');

      expect(orderA, isNotNull);
      expect(orderA!.tableLabel, 'Table A');
      expect(orderB, isNotNull);
      expect(orderB!.tableLabel, 'Table B');
      expect(orderC, isNull); // no order for Table C

      // After marking Table A as billed, getActiveOrder should return null
      tableOrderProvider.markAsBilled(orderA.id);
      expect(tableOrderProvider.getActiveOrder('Table A'), isNull);
      expect(tableOrderProvider.getActiveOrder('Table B'), isNotNull);
    });
  });
}
