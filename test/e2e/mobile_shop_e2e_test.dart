import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/serial_number.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/serial_number_provider.dart';
import 'helpers/test_fixtures.dart';

void main() {
  group('Mobile Shop — Serial Number Lifecycle', () {
    late SerialNumberProvider serialProvider;

    setUp(() {
      serialProvider = SerialNumberProvider();
      serialProvider.init([], () {});
    });

    test('addFromPurchase creates serial numbers with inStock status', () {
      serialProvider.addFromPurchase(
        numbers: ['IMEI001', 'IMEI002'],
        productId: 'p1',
        productName: 'Samsung',
        purchaseEntryId: 'pur1',
      );

      expect(serialProvider.all.length, equals(2));
      expect(
        serialProvider.all.every((s) => s.status == SerialNumberStatus.inStock),
        isTrue,
      );
    });

    test('assignToBill changes status to sold', () {
      serialProvider.addFromPurchase(
        numbers: ['IMEI001'],
        productId: 'p1',
        productName: 'Samsung',
        purchaseEntryId: 'pur1',
      );

      final serialId = serialProvider.all.first.id;
      serialProvider.assignToBill([serialId], 'bill-1');

      expect(serialProvider.all.first.status, equals(SerialNumberStatus.sold));
      expect(serialProvider.all.first.billId, equals('bill-1'));
    });

    test('returnFromBill changes status to returned', () {
      serialProvider.addFromPurchase(
        numbers: ['IMEI001'],
        productId: 'p1',
        productName: 'Samsung',
        purchaseEntryId: 'pur1',
      );

      final serialId = serialProvider.all.first.id;
      serialProvider.assignToBill([serialId], 'bill-1');
      expect(serialProvider.all.first.status, equals(SerialNumberStatus.sold));

      serialProvider.returnFromBill('bill-1');
      expect(serialProvider.all.first.status, equals(SerialNumberStatus.returned));
    });

    test('duplicate serial number detection', () {
      serialProvider.addFromPurchase(
        numbers: ['IMEI001'],
        productId: 'p1',
        productName: 'Samsung',
        purchaseEntryId: 'pur1',
      );

      expect(serialProvider.isNumberDuplicate('p1', 'IMEI001'), isTrue);
      expect(serialProvider.isNumberDuplicate('p1', 'imei001'), isTrue); // case insensitive
      expect(serialProvider.isNumberDuplicate('p1', 'IMEI999'), isFalse);
      expect(serialProvider.isNumberDuplicate('p2', 'IMEI001'), isFalse); // different product
    });

    test('availableFor returns only inStock serials', () {
      serialProvider.addFromPurchase(
        numbers: ['IMEI001', 'IMEI002', 'IMEI003'],
        productId: 'p1',
        productName: 'Samsung',
        purchaseEntryId: 'pur1',
      );

      // Sell one
      final firstId = serialProvider.all.first.id;
      serialProvider.assignToBill([firstId], 'bill-1');

      final available = serialProvider.availableFor('p1');
      expect(available.length, equals(2));
      expect(
        available.every((s) => s.status == SerialNumberStatus.inStock),
        isTrue,
      );
    });
  });

  group('Mobile Shop — Full Lifecycle', () {
    late SerialNumberProvider serialProvider;
    late ProductProvider productProvider;
    late BillProvider billProvider;
    late CustomerProvider customerProvider;

    setUp(() {
      serialProvider = SerialNumberProvider();
      serialProvider.init([], () {});
      productProvider = ProductProvider();
      billProvider = BillProvider();
      customerProvider = CustomerProvider();
    });

    test('purchase phones → sell with serial → return', () {
      final phone = mobileShopPhone(id: 'phone-1', stockQuantity: 5);
      productProvider.addProduct(phone);

      // Add serial numbers from purchase
      serialProvider.addFromPurchase(
        numbers: ['IMEI-A1', 'IMEI-A2'],
        productId: 'phone-1',
        productName: 'Samsung Galaxy M34',
        purchaseEntryId: 'pur-1',
      );

      expect(serialProvider.all.length, equals(2));
      expect(serialProvider.availableFor('phone-1').length, equals(2));

      // Create a bill and sell one phone
      billProvider.addItemToBill(phone);
      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Assign serial to bill
      final serialId = serialProvider.all.first.id;
      serialProvider.assignToBill([serialId], bill.id);

      expect(serialProvider.all.first.status, equals(SerialNumberStatus.sold));
      expect(serialProvider.availableFor('phone-1').length, equals(1));

      // Return the phone
      serialProvider.returnFromBill(bill.id);
      expect(serialProvider.all.first.status, equals(SerialNumberStatus.returned));
    });

    test('device info stored on bill (IMEI as vehicleReg, brand as vehicleMake)', () {
      final phone = mobileShopPhone(stockQuantity: 5);
      productProvider.addProduct(phone);

      billProvider.setVehicleInfo(
        vehicleReg: '358123456789012',
        vehicleMake: 'Samsung',
        vehicleModel: 'Black 128GB',
      );
      billProvider.addItemToBill(phone);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(bill.vehicleReg, equals('358123456789012'));
      expect(bill.vehicleMake, equals('Samsung'));
      expect(bill.vehicleModel, equals('Black 128GB'));
    });
  });
}
