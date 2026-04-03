import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/business_config.dart';
import 'package:billing_app/models/cash_book_entry.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/customer_payment_entry.dart';
import 'package:billing_app/models/expense.dart';
import 'package:billing_app/models/expense_category.dart';
import 'package:billing_app/models/line_item.dart';
import 'package:billing_app/models/persisted_app_state.dart';
import 'package:billing_app/models/app_user.dart';
import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/product_batch.dart';
import 'package:billing_app/models/payment_info.dart';
import 'package:billing_app/models/user_role.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/cash_book_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/expense_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/services/bill_number_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PersistedAppState serialization', () {
    test('round-trips config, product, customer and bill data', () {
      final customer = Customer(
        id: 'cust-1',
        name: 'Ravi',
        phone: '9876543210',
        outstandingBalance: 250,
      );

      final product = Product(
        id: 'prod-1',
        name: 'Paracetamol',
        sellingPrice: 25,
        stockQuantity: 20,
        gstSlabPercent: 5,
        batches: [
          ProductBatch(
            id: 'batch-1',
            productId: 'prod-1',
            batchNumber: 'B001',
            expiryDate: DateTime(2027, 1, 1),
            stockQuantity: 20,
          ),
        ],
      );

      final bill = Bill(
        id: 'bill-1',
        billNumber: '2025-26/INV-001',
        lineItems: [
          LineItem(product: product, quantity: 2, batch: product.batches.first),
        ],
        subtotal: 50,
        discount: 5,
        grandTotal: 45,
        paymentMode: PaymentMode.credit,
        amountReceived: 0,
        creditAmount: 45,
        customer: customer,
        timestamp: DateTime(2026, 1, 15, 10, 30),
        diagnosis: 'Fever',
        visitNotes: 'Rest advised',
      );

      final state = PersistedAppState(
        schemaVersion: 1,
        businessConfig: const BusinessConfig(
          businessName: 'Test Store',
          phone: '9998887777',
          setupCompleted: true,
          businessType: BusinessType.pharmacy,
          gstEnabled: true,
          gstin: '29ABCDE1234F1Z5',
          billPrefix: 'INV',
        ),
        products: [product],
        customers: [customer],
        bills: [bill],
        expenses: [
          Expense(
            id: 'exp-1',
            amount: 350,
            category: ExpenseCategory.transport,
            description: 'Delivery fuel',
            paymentMode: ExpensePaymentMode.upi,
            date: DateTime(2026, 1, 14),
          ),
        ],
        customerPaymentEntries: [
          CustomerPaymentEntry(
            id: 'pay-1',
            customerId: 'cust-1',
            amount: 100,
            paymentMode: SettlementPaymentMode.cash,
            recordedAt: DateTime(2026, 1, 16),
          ),
        ],
        cashBookDays: [
          CashBookDay(
            date: DateTime(2026, 1, 16),
            openingBalance: 1000,
            cashSales: 500,
            cashReceived: 100,
            cashExpenses: 200,
            closingBalance: 1400,
            isClosed: true,
          ),
        ],
        users: [
          AppUser(
            id: 'usr-1',
            name: 'Owner',
            phone: '9876543210',
            pinHash: 'hash',
            role: UserRole.owner,
            avatarColor: '#0F766E',
          ),
        ],
        currentUserId: 'usr-1',
        singleUserMode: false,
        requirePinOnOpen: true,
        autoLockMinutes: 10,
      );

      final restored = PersistedAppState.fromJson(state.toJson());

      expect(restored.businessConfig.businessName, 'Test Store');
      expect(restored.businessConfig.businessType, BusinessType.pharmacy);
      expect(restored.products.single.name, 'Paracetamol');
      expect(restored.products.single.batches.single.batchNumber, 'B001');
      expect(restored.customers.single.name, 'Ravi');
      expect(restored.bills.single.billNumber, '2025-26/INV-001');
      expect(restored.bills.single.customer?.phone, '9876543210');
      expect(restored.bills.single.lineItems.single.batch?.id, 'batch-1');
      expect(restored.bills.single.diagnosis, 'Fever');
      expect(restored.expenses.single.description, 'Delivery fuel');
      expect(restored.expenses.single.paymentMode, ExpensePaymentMode.upi);
      expect(restored.customerPaymentEntries.single.amount, 100);
      expect(restored.cashBookDays.single.closingBalance, 1400);
      expect(restored.users.single.name, 'Owner');
      expect(restored.currentUserId, 'usr-1');
      expect(restored.singleUserMode, isFalse);
      expect(restored.requirePinOnOpen, isTrue);
      expect(restored.autoLockMinutes, 10);
    });
  });

  group('BillNumberService hydration', () {
    test('continues sequence from current FY max bill number', () {
      final service = BillNumberService();
      final fy = service.currentFinancialYear;

      service.hydrateFromExistingBills([
        '$fy/INV-003',
        '$fy/INV-009',
        '$fy/CUSTOM-015',
        '2020-21/INV-999',
      ]);

      final next = service.generateBillNumber();
      expect(next, '$fy/INV-016');
    });
  });

  group('Provider persistence callbacks', () {
    test(
      'product/customer/bill providers trigger onChanged on state mutation',
      () {
        var productWrites = 0;
        var customerWrites = 0;
        var billWrites = 0;
        var expenseWrites = 0;
        var cashBookWrites = 0;

        final productProvider = ProductProvider(
          onChanged: () => productWrites++,
        );
        final customerProvider = CustomerProvider(
          onChanged: () => customerWrites++,
        );
        final billProvider = BillProvider(onChanged: () => billWrites++);
        final expenseProvider = ExpenseProvider(
          onChanged: () => expenseWrites++,
        );
        final cashBookProvider = CashBookProvider(
          billProvider: billProvider,
          expenseProvider: expenseProvider,
          customerProvider: customerProvider,
          onChanged: () => cashBookWrites++,
        );

        final product = Product(
          id: 'prod-2',
          name: 'Soap',
          sellingPrice: 30,
          stockQuantity: 10,
        );
        productProvider.addProduct(product);
        expect(productWrites, 1);

        final customer = customerProvider.addCustomer(name: 'Anu');
        expect(customerWrites, 1);

        billProvider.addItemToBill(product);
        billProvider.completeBill(
          paymentInfo: PaymentInfo(
            mode: PaymentMode.credit,
            creditAmount: 30,
            customer: customer,
          ),
          gstEnabled: false,
          productProvider: productProvider,
          customerProvider: customerProvider,
        );

        expect(billWrites, 1);
        expect(productWrites, 2);
        expect(customerWrites, 2);

        expenseProvider.addExpense(
          Expense(amount: 10, category: ExpenseCategory.miscellaneous),
        );
        expect(expenseWrites, 1);

        cashBookProvider.setOpeningBalance(DateTime.now(), 500);
        expect(cashBookWrites, greaterThan(0));
      },
    );
  });
}
