import '../../models/product.dart';
import '../../models/supplier.dart';
import '../repositories/product_repository.dart';
import '../repositories/supplier_repository.dart';

/// Sprint 3 #23 slice 5 — drains cross-provider side effects for
/// `PurchaseProvider.addPurchase`: stock increments (ProductRepository)
/// and, for credit purchases, supplier payable increments
/// (SupplierRepository). Mirrors the `CompleteBillUseCase`
/// fallback-path pattern so the persistence of peer snapshots lives in
/// one place instead of being scattered across `persist: true` calls
/// inside ProductProvider / SupplierProvider.
///
/// Unlike `CompleteBillUseCase` there is no server-side atomic RPC for
/// purchases; the use case only persists snapshots, it does not attempt
/// any remote transaction.
class CreatePurchaseUseCase {
  CreatePurchaseUseCase({
    ProductRepository? productRepository,
    SupplierRepository? supplierRepository,
  })  : _productRepository = productRepository,
        _supplierRepository = supplierRepository;

  final ProductRepository? _productRepository;
  final SupplierRepository? _supplierRepository;

  /// Writes the supplied product and supplier snapshots through the
  /// repository layer. Callers should have already applied the
  /// in-memory mutations with `persist: false` on the relevant
  /// providers before invoking this method so that the cache and the
  /// remote end up consistent.
  Future<void> persistSideEffects({
    List<Product> updatedProducts = const [],
    Supplier? updatedSupplier,
  }) async {
    final productRepo = _productRepository;
    if (productRepo != null && updatedProducts.isNotEmpty) {
      await productRepo.saveAll(updatedProducts);
    }
    final supplierRepo = _supplierRepository;
    if (supplierRepo != null && updatedSupplier != null) {
      await supplierRepo.saveAll([updatedSupplier]);
    }
  }
}
