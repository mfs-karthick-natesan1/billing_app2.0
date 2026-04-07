import '../../models/supplier.dart';

/// Abstract supplier persistence contract. See [BillRepository] for the
/// rationale (Sprint 3 #24 slice 2).
abstract class SupplierRepository {
  Future<List<Supplier>> loadAll();
  Future<void> saveAll(List<Supplier> suppliers);
  Future<void> delete(String id);
}
