import 'package:flutter/foundation.dart';
import '../models/business_config.dart';
import '../models/product.dart';
import '../models/product_batch.dart';
import '../models/stock_adjustment.dart';
import '../constants/sample_data.dart';
import '../domain/repositories/product_repository.dart';
import '../services/search_service.dart';
import '../services/db_service.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
  final List<StockAdjustment> _adjustments = [];
  final VoidCallback? _onChanged;

  DbService? dbService;
  // Sprint 3 #24 slice 2: prefer this repository when wired. The legacy
  // dbService field is kept as a fallback so tests / unmigrated call
  // sites keep working until slice 4 removes it.
  ProductRepository? productRepository;

  Future<void> _persist(List<Product> products) {
    final repo = productRepository;
    if (repo != null) return repo.saveAll(products);
    return dbService?.saveProducts(products) ?? Future<void>.value();
  }

  Future<void> _deleteRemote(String id) {
    final repo = productRepository;
    if (repo != null) return repo.delete(id);
    return dbService?.deleteRecord('products', id) ?? Future<void>.value();
  }

  ProductProvider({
    List<Product>? initialProducts,
    List<StockAdjustment>? initialAdjustments,
    VoidCallback? onChanged,
  }) : _onChanged = onChanged {
    if (initialProducts != null) {
      _products.addAll(initialProducts);
    }
    if (initialAdjustments != null) {
      _adjustments.addAll(initialAdjustments);
    }
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Product> get products => List.unmodifiable(_products);

  int get totalCount => _products.length;
  int get lowStockCount =>
      _products.where((p) => !p.isService && p.isLowStock).length;
  int get outOfStockCount =>
      _products.where((p) => !p.isService && p.isOutOfStock).length;
  int get expiringSoonCount =>
      _products.where((p) => p.batches.any((b) => b.isExpiringSoon)).length;
  int get serviceCount => _products.where((p) => p.isService).length;

  List<Product> get productsNeedingReorder =>
      _products.where((p) => p.needsReorder).toList();
  int get reorderRequiredCount => productsNeedingReorder.length;

  List<StockAdjustment> get adjustments => List.unmodifiable(_adjustments);

  void clearProducts() {
    _products.clear();
    _adjustments.clear();
    _onChanged?.call();
    notifyListeners();
  }

  void loadSampleData() {
    _products.clear();
    _products.addAll(SampleData.products);
    _onChanged?.call();
    notifyListeners();
  }

  void loadPharmacySampleData() {
    _products.clear();
    _products.addAll(SampleData.pharmacyProducts);
    _onChanged?.call();
    notifyListeners();
  }

  void loadSalonSampleData() {
    _products.clear();
    _products.addAll(SampleData.salonProducts);
    _onChanged?.call();
    notifyListeners();
  }

  void loadClinicSampleData() {
    _products.clear();
    _products.addAll(SampleData.clinicProducts);
    _onChanged?.call();
    notifyListeners();
  }

  void loadJewellerySampleData() {
    _products.clear();
    _products.addAll(SampleData.jewelleryProducts);
    _onChanged?.call();
    notifyListeners();
  }

  void loadRestaurantSampleData() {
    _products.clear();
    _products.addAll(SampleData.restaurantProducts);
    _onChanged?.call();
    notifyListeners();
  }

  void loadWorkshopSampleData() {
    _products.clear();
    _products.addAll(SampleData.workshopProducts);
    _onChanged?.call();
    notifyListeners();
  }

  void loadSampleDataForBusinessType(BusinessType businessType) {
    switch (businessType) {
      case BusinessType.pharmacy:
        loadPharmacySampleData();
      case BusinessType.salon:
        loadSalonSampleData();
      case BusinessType.clinic:
        loadClinicSampleData();
      case BusinessType.jewellery:
        loadJewellerySampleData();
      case BusinessType.restaurant:
        loadRestaurantSampleData();
      case BusinessType.workshop:
        loadWorkshopSampleData();
      case BusinessType.mobileShop:
      case BusinessType.general:
        loadSampleData();
    }
  }

  void addProduct(Product product) {
    _products.add(product);
    _persist([product]);
    _onChanged?.call();
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      _persist([updated]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    _deleteRemote(id);
    _onChanged?.call();
    notifyListeners();
  }

  void importProducts(List<Product> products) {
    _products.addAll(products);
    _onChanged?.call();
    notifyListeners();
  }

  // Batch CRUD
  void addBatch(String productId, ProductBatch batch) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final newBatches = [..._products[index].batches, batch];
      final updated = _products[index].copyWith(
        batches: newBatches,
        stockQuantity: newBatches.fold<int>(0, (sum, b) => sum + b.stockQuantity),
      );
      _products[index] = updated;
      _persist([updated]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  void updateBatch(String productId, ProductBatch updatedBatch) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final newBatches = _products[index].batches
          .map((b) => b.id == updatedBatch.id ? updatedBatch : b)
          .toList();
      final updated = _products[index].copyWith(
        batches: newBatches,
        stockQuantity: newBatches.fold<int>(0, (sum, b) => sum + b.stockQuantity),
      );
      _products[index] = updated;
      _persist([updated]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  void deleteBatch(String productId, String batchId) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final newBatches =
          _products[index].batches.where((b) => b.id != batchId).toList();
      final updated = _products[index].copyWith(
        batches: newBatches,
        stockQuantity: newBatches.fold<int>(0, (sum, b) => sum + b.stockQuantity),
      );
      _products[index] = updated;
      _persist([updated]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  List<Product> searchProducts(String query, {int limit = 5}) {
    return SearchService.searchProducts(_products, query, limit: limit);
  }

  List<Product> getFilteredProducts({
    String? searchQuery,
    ProductFilter filter = ProductFilter.all,
  }) {
    return SearchService.filterProducts(
      _products,
      searchQuery: searchQuery,
      filter: filter,
    );
  }

  Product? findById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? findByBarcode(String barcode) {
    final normalized = _normalizeBarcode(barcode);
    if (normalized == null) return null;
    try {
      return _products.firstWhere(
        (p) => _normalizeBarcode(p.barcode) == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  bool nameExists(String name, {String? excludeId}) {
    return _products.any(
      (p) => p.name.toLowerCase() == name.toLowerCase() && p.id != excludeId,
    );
  }

  bool barcodeExists(String barcode, {String? excludeId}) {
    final normalized = _normalizeBarcode(barcode);
    if (normalized == null) return false;
    return _products.any(
      (p) => _normalizeBarcode(p.barcode) == normalized && p.id != excludeId,
    );
  }

  /// Increments stock for the given product.
  ///
  /// When [persist] is false, only the in-memory state is updated and
  /// the DB is not written. Sprint 3 #23 slice 5: CreatePurchaseUseCase
  /// uses this to apply cache-only updates and then persist a single
  /// snapshot through ProductRepository.
  void incrementStock(
    String productId,
    double quantity, {
    bool persist = true,
  }) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final updated = _products[index].copyWith(
        stockQuantity: _products[index].stockQuantity + quantity.toInt(),
      );
      _products[index] = updated;
      if (persist) _persist([updated]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  /// Decrements stock for the given product. Throws [StateError] if
  /// the resulting stock would be negative.
  ///
  /// When [persist] is false, only the in-memory state is updated and
  /// the DB is not written. Use this after a server-side RPC has
  /// already applied the same mutation atomically — avoids a
  /// redundant client write that could race with concurrent sales.
  void decrementStock(
    String productId,
    double quantity, {
    String? batchId,
    bool persist = true,
  }) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return;

    final product = _products[index];
    final qty = quantity.toInt();
    Product updated;

    if (batchId != null) {
      final batchIndex = product.batches.indexWhere((b) => b.id == batchId);
      if (batchIndex == -1) {
        throw StateError(
          'Batch $batchId not found for product ${product.name}. '
          'Stock was not decremented.',
        );
      }
      final batch = product.batches[batchIndex];
      if (batch.stockQuantity < qty) {
        throw StateError(
          'Insufficient batch stock for ${product.name} '
          '(batch ${batch.batchNumber}): '
          'available ${batch.stockQuantity}, requested $qty',
        );
      }
      final newBatches = product.batches
          .map((b) => b.id == batchId
              ? b.copyWith(stockQuantity: b.stockQuantity - qty)
              : b)
          .toList();
      updated = product.copyWith(
        batches: newBatches,
        stockQuantity: newBatches.fold<int>(0, (sum, b) => sum + b.stockQuantity),
      );
    } else {
      if (product.stockQuantity < qty) {
        throw StateError(
          'Insufficient stock for ${product.name}: '
          'available ${product.stockQuantity}, requested $qty',
        );
      }
      updated = product.copyWith(
        stockQuantity: product.stockQuantity - qty,
      );
    }

    _products[index] = updated;
    if (persist) {
      _persist([updated]);
    }
    _onChanged?.call();
    notifyListeners();
  }

  // Stock adjustments
  void adjustStock(StockAdjustment adjustment) {
    final index = _products.indexWhere((p) => p.id == adjustment.productId);
    if (index != -1) {
      final updated = _products[index].copyWith(
        stockQuantity: adjustment.newStock.toInt(),
      );
      _products[index] = updated;
      _adjustments.add(adjustment);
      _persist([updated]);
      _onChanged?.call();
      notifyListeners();
    }
  }

  List<StockAdjustment> getAdjustments(String productId) {
    return _adjustments
        .where((a) => a.productId == productId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  void replaceAllAdjustments(List<StockAdjustment> adjustments) {
    _adjustments
      ..clear()
      ..addAll(adjustments);
    _onChanged?.call();
    notifyListeners();
  }

  String? _normalizeBarcode(String? value) {
    if (value == null) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  Future<String?> syncFromDb() async {
    if (productRepository == null && dbService == null) return null;
    _isLoading = true;
    notifyListeners();
    try {
      final products = await (productRepository != null
          ? productRepository!.loadAll()
          : dbService!.loadProducts());
      _products
        ..clear()
        ..addAll(products);
      _isLoading = false;
      notifyListeners();
      return null;
    } on Exception catch (e) {
      _isLoading = false;
      notifyListeners();
      final msg = e.toString();
      if (msg.contains('AuthException') || msg.contains('JWT')) {
        return 'Sync failed: session expired. Please log in again.';
      }
      return 'Sync failed: please check your internet connection.';
    }
  }
}
