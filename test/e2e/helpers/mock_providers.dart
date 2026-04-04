import 'package:billing_app/models/product.dart';
import 'package:billing_app/models/customer.dart';
import 'package:billing_app/models/bill.dart';
import 'package:billing_app/models/sales_return.dart';
import 'package:billing_app/models/stock_adjustment.dart';
import 'package:billing_app/providers/bill_provider.dart';
import 'package:billing_app/providers/customer_provider.dart';
import 'package:billing_app/providers/product_provider.dart';
import 'package:billing_app/providers/purchase_provider.dart';
import 'package:billing_app/providers/return_provider.dart';
import 'package:billing_app/providers/supplier_provider.dart';
import 'package:billing_app/providers/quotation_provider.dart';
import 'package:billing_app/providers/table_order_provider.dart';
import 'package:billing_app/providers/job_card_provider.dart';
import 'package:billing_app/providers/serial_number_provider.dart';
import 'package:billing_app/providers/user_provider.dart';

/// Bundle of all providers wired for in-memory E2E testing (no dbService).
class E2EProviderSet {
  final ProductProvider product;
  final BillProvider bill;
  final CustomerProvider customer;
  final SupplierProvider supplier;
  final PurchaseProvider purchase;
  final ReturnProvider returns;
  final QuotationProvider quotation;
  final TableOrderProvider tableOrder;
  final JobCardProvider jobCard;
  final SerialNumberProvider serial;
  final UserProvider user;

  E2EProviderSet({
    required this.product,
    required this.bill,
    required this.customer,
    required this.supplier,
    required this.purchase,
    required this.returns,
    required this.quotation,
    required this.tableOrder,
    required this.jobCard,
    required this.serial,
    required this.user,
  });
}

/// Creates a full set of providers for E2E testing.
///
/// All providers run purely in-memory (no Supabase). Pass optional initial data
/// to pre-populate providers.
E2EProviderSet createProviderSet({
  List<Product>? products,
  List<Customer>? customers,
  List<Bill>? bills,
  List<SalesReturn>? salesReturns,
  List<StockAdjustment>? stockAdjustments,
}) {
  return E2EProviderSet(
    product: ProductProvider(
      initialProducts: products,
      initialAdjustments: stockAdjustments,
    ),
    bill: BillProvider(initialBills: bills),
    customer: CustomerProvider(initialCustomers: customers),
    supplier: SupplierProvider(),
    purchase: PurchaseProvider(),
    returns: ReturnProvider(initialReturns: salesReturns),
    quotation: QuotationProvider(),
    tableOrder: TableOrderProvider(),
    jobCard: JobCardProvider(),
    serial: SerialNumberProvider()..init([], () {}),
    user: UserProvider(),
  );
}
