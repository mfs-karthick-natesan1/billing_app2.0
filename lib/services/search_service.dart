import '../models/product.dart';

class SearchService {
  SearchService._();

  static List<Product> searchProducts(
    List<Product> products,
    String query, {
    int limit = 5,
  }) {
    if (query.length < 1) return [];
    final lowerQuery = query.toLowerCase();
    return products
        .where(
          (p) =>
              p.name.toLowerCase().contains(lowerQuery) ||
              (p.barcode?.toLowerCase().contains(lowerQuery) ?? false),
        )
        .take(limit)
        .toList();
  }

  static List<Product> filterProducts(
    List<Product> products, {
    String? searchQuery,
    ProductFilter filter = ProductFilter.all,
  }) {
    var result = products.toList();

    if (searchQuery != null && searchQuery.length >= 1) {
      final lowerQuery = searchQuery.toLowerCase();
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(lowerQuery) ||
                (p.barcode?.toLowerCase().contains(lowerQuery) ?? false),
          )
          .toList();
    }

    switch (filter) {
      case ProductFilter.all:
        break;
      case ProductFilter.lowStock:
        result = result.where((p) => p.isLowStock).toList();
      case ProductFilter.outOfStock:
        result = result.where((p) => p.isOutOfStock).toList();
      case ProductFilter.expiringSoon:
        result = result
            .where((p) => p.batches.any((b) => b.isExpiringSoon))
            .toList();
      case ProductFilter.services:
        result = result.where((p) => p.isService).toList();
    }

    return result;
  }
}

enum ProductFilter { all, lowStock, outOfStock, expiringSoon, services }
