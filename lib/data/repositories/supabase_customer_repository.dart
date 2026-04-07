import '../../domain/repositories/customer_repository.dart';
import '../../models/customer.dart';
import '../../models/customer_payment_entry.dart';
import '../../services/db_service.dart';

class SupabaseCustomerRepository implements CustomerRepository {
  SupabaseCustomerRepository(this._db);

  final DbService _db;

  @override
  Future<List<Customer>> loadAll() => _db.loadCustomers();

  @override
  Future<void> saveAll(List<Customer> customers) =>
      _db.saveCustomers(customers);

  @override
  Future<void> delete(String id) => _db.deleteRecord('customers', id);

  @override
  Future<void> savePaymentEntries(List<CustomerPaymentEntry> entries) =>
      _db.saveCustomerPaymentEntries(entries);
}
