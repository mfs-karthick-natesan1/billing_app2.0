import '../../models/customer.dart';
import '../../models/customer_payment_entry.dart';

/// Abstract customer persistence contract.
///
/// Customer payment entries live alongside customers because every mutation
/// to a payment entry also rewrites the customer row (outstanding balance,
/// advance, etc.). Grouping them avoids leaking the coupling into the
/// provider layer.
abstract class CustomerRepository {
  Future<List<Customer>> loadAll();
  Future<void> saveAll(List<Customer> customers);
  Future<void> delete(String id);
  Future<void> savePaymentEntries(List<CustomerPaymentEntry> entries);
}
