import '../../models/product.dart';

/// Abstract product persistence contract. See [BillRepository] for the
/// rationale (Sprint 3 #24 slice 2).
abstract class ProductRepository {
  Future<List<Product>> loadAll();
  Future<void> saveAll(List<Product> products);
  Future<void> delete(String id);
}
