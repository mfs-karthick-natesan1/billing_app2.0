import 'package:flutter_test/flutter_test.dart';
import 'package:billing_app/models/job_card.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/job_card_provider.dart';
import 'helpers/test_fixtures.dart';

void main() {
  group('Workshop — Job Card Lifecycle', () {
    late JobCardProvider jobCardProvider;

    setUp(() {
      jobCardProvider = JobCardProvider();
    });

    test('create job card → update status through full lifecycle', () {
      final jc = jobCardProvider.createJobCard(
        vehicleReg: 'TN01AB1234',
        customerName: 'Raj',
        problemDescription: 'Oil leak',
      );

      expect(jobCardProvider.jobCards.length, equals(1));
      expect(jobCardProvider.jobCards.first.status, equals(JobStatus.received));

      // Move to inProgress
      jobCardProvider.updateStatus(jc.id, JobStatus.inProgress);
      expect(jobCardProvider.jobCards.first.status, equals(JobStatus.inProgress));

      // Move to readyForPickup (completed equivalent)
      jobCardProvider.updateStatus(jc.id, JobStatus.readyForPickup);
      expect(jobCardProvider.jobCards.first.status, equals(JobStatus.readyForPickup));

      // Move to delivered
      jobCardProvider.updateStatus(jc.id, JobStatus.delivered);
      expect(jobCardProvider.jobCards.first.status, equals(JobStatus.delivered));
    });

    test('job card stores vehicle info (reg, make, model, km)', () {
      final jc = jobCardProvider.createJobCard(
        vehicleReg: 'TN01AB1234',
        vehicleMake: 'Honda',
        vehicleModel: 'CB Shine',
        kmReading: '15000',
        customerName: 'Raj',
        customerPhone: '9876543210',
        problemDescription: 'Oil leak',
      );

      expect(jc.vehicleReg, equals('TN01AB1234'));
      expect(jc.vehicleMake, equals('Honda'));
      expect(jc.vehicleModel, equals('CB Shine'));
      expect(jc.kmReading, equals('15000'));
      expect(jc.customerName, equals('Raj'));
      expect(jc.customerPhone, equals('9876543210'));
    });

    test('job number auto-increments (JOB-0001, JOB-0002)', () {
      final jc1 = jobCardProvider.createJobCard(
        vehicleReg: 'TN01AB1234',
        customerName: 'Raj',
        problemDescription: 'Oil leak',
      );
      final jc2 = jobCardProvider.createJobCard(
        vehicleReg: 'TN02CD5678',
        customerName: 'Anand',
        problemDescription: 'Brake issue',
      );

      expect(jc1.jobNumber, equals('JOB-0001'));
      expect(jc2.jobNumber, equals('JOB-0002'));
    });
  });

  group('Workshop — Vehicle Bill', () {
    late BillProvider billProvider;
    late ProductProvider productProvider;
    late CustomerProvider customerProvider;

    setUp(() {
      billProvider = BillProvider();
      productProvider = ProductProvider();
      customerProvider = CustomerProvider();
    });

    test('bill with vehicle info → stored on bill', () {
      final part = workshopPart(stockQuantity: 40);
      productProvider.addProduct(part);

      billProvider.setVehicleInfo(
        vehicleReg: 'TN01AB1234',
        vehicleMake: 'Honda',
        vehicleModel: 'CB Shine',
        kmReading: '15000',
      );
      billProvider.addItemToBill(part);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      expect(bill.vehicleReg, equals('TN01AB1234'));
      expect(bill.vehicleMake, equals('Honda'));
      expect(bill.vehicleModel, equals('CB Shine'));
      expect(bill.kmReading, equals('15000'));
    });

    test('parts decrement stock, labor does not', () {
      final part = workshopPart(id: 'ws-part-1', stockQuantity: 40);
      final labor = workshopLabor(id: 'ws-labor-1');
      productProvider.addProduct(part);
      productProvider.addProduct(labor);

      billProvider.addItemToBill(part);
      billProvider.addItemToBill(labor);

      billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Part stock decremented by 1 (default qty)
      final updatedPart = productProvider.products.firstWhere((p) => p.id == 'ws-part-1');
      expect(updatedPart.stockQuantity, equals(39));

      // Labor (service) stock unchanged — services don't track stock
      final updatedLabor = productProvider.products.firstWhere((p) => p.id == 'ws-labor-1');
      expect(updatedLabor.isService, isTrue);
      // Services have stockQuantity=0 and it should remain 0
      expect(updatedLabor.stockQuantity, equals(0));
    });

    test('GST on parts and labor both 18%', () {
      final part = workshopPart(sellingPrice: 1000, stockQuantity: 40);
      final labor = workshopLabor(sellingPrice: 800);
      productProvider.addProduct(part);
      productProvider.addProduct(labor);

      billProvider.addItemToBill(part);
      billProvider.addItemToBill(labor);

      final bill = billProvider.completeBill(
        paymentInfo: cashPayment(),
        gstEnabled: true,
        productProvider: productProvider,
        customerProvider: customerProvider,
      );

      // Both at 18% GST, exclusive
      // Part taxable=1000, Labor taxable=800, total taxable=1800
      // CGST = 9% of 1800 = 162, SGST = 162
      // Grand total = 1800 + 162 + 162 = 2124
      expect(bill.cgst, closeTo(162.0, 0.02));
      expect(bill.sgst, closeTo(162.0, 0.02));
      expect(bill.grandTotal, closeTo(2124.0, 0.02));
    });
  });
}
