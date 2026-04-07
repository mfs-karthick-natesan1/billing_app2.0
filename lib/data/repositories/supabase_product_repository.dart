import '../../domain/repositories/product_repository.dart';
import '../../models/product.dart';
import '../../services/db_service.dart';

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this._db);

  final DbService _db;

  @override
  Future<List<Product>> loadAll() => _db.loadProducts();

  @override
  Future<void> saveAll(List<Product> products) => _db.saveProducts(products);

  @override
  Future<void> delete(String id) => _db.deleteRecord('products', id);
}
