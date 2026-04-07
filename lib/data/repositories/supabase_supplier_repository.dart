import '../../domain/repositories/supplier_repository.dart';
import '../../models/supplier.dart';
import '../../services/db_service.dart';

class SupabaseSupplierRepository implements SupplierRepository {
  SupabaseSupplierRepository(this._db);

  final DbService _db;

  @override
  Future<List<Supplier>> loadAll() => _db.loadSuppliers();

  @override
  Future<void> saveAll(List<Supplier> suppliers) =>
      _db.saveSuppliers(suppliers);

  @override
  Future<void> delete(String id) => _db.deleteRecord('suppliers', id);
}
