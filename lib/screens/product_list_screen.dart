import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../providers/business_config_provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../services/search_service.dart';
import '../widgets/app_fab.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../widgets/product_card.dart';
import '../widgets/stock_adjustment_sheet.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/skeleton_loader.dart';

enum _ProductSort { nameAsc, nameDesc, priceAsc, priceDesc, stockAsc, stockDesc }

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  ProductFilter _filter = ProductFilter.all;
  String _searchQuery = '';
  _ProductSort _sort = _ProductSort.nameAsc;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _applySortProducts(List<Product> products) {
    final sorted = products.toList();
    switch (_sort) {
      case _ProductSort.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case _ProductSort.nameDesc:
        sorted.sort((a, b) => b.name.compareTo(a.name));
      case _ProductSort.priceAsc:
        sorted.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
      case _ProductSort.priceDesc:
        sorted.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
      case _ProductSort.stockAsc:
        sorted.sort((a, b) => a.stockQuantity.compareTo(b.stockQuantity));
      case _ProductSort.stockDesc:
        sorted.sort((a, b) => b.stockQuantity.compareTo(a.stockQuantity));
    }
    return sorted;
  }

  void _showProductOptions(
    BuildContext context,
    dynamic product,
    dynamic productProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tune),
              title: Text('Adjust Stock', style: AppTypography.body),
              onTap: () {
                Navigator.pop(ctx);
                StockAdjustmentSheet.show(context, product);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                AppStrings.deleteProduct,
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Delete ${product.name}?',
                  message: AppStrings.deleteConfirm,
                  confirmLabel: AppStrings.deleteProduct,
                  isDestructive: true,
                );
                if (confirm && context.mounted) {
                  productProvider.deleteProduct(product.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final configProvider = context.watch<BusinessConfigProvider>();
    final isPharmacy = configProvider.isPharmacy;
    final isSalon = configProvider.isSalon;
    final filtered = _applySortProducts(
      productProvider.getFilteredProducts(
        searchQuery: _searchQuery,
        filter: _filter,
      ),
    );

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.productsTitle,
        actions: [
          PopupMenuButton<_ProductSort>(
            icon: Icon(Icons.sort, color: AppColors.onSurface),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _ProductSort.nameAsc, child: Text('Name: A–Z')),
              PopupMenuItem(value: _ProductSort.nameDesc, child: Text('Name: Z–A')),
              PopupMenuItem(value: _ProductSort.priceDesc, child: Text('Price: high to low')),
              PopupMenuItem(value: _ProductSort.priceAsc, child: Text('Price: low to high')),
              PopupMenuItem(value: _ProductSort.stockDesc, child: Text('Stock: high to low')),
              PopupMenuItem(value: _ProductSort.stockAsc, child: Text('Stock: low to high')),
            ],
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppColors.onSurface),
            onSelected: (value) {
              if (value == 'csv') {
                Navigator.pushNamed(context, '/csv-import');
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'csv',
                child: Text(
                  AppStrings.importProductsCsv,
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: AppFab(
        heroTag: 'fab-product',
        onPressed: () => Navigator.pushNamed(context, '/add-product'),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: AppStrings.searchProducts,
                hintStyle: AppTypography.body.copyWith(color: AppColors.muted),
                prefixIcon: Icon(Icons.search, color: AppColors.muted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.muted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(
                    color: AppColors.muted.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  borderSide: BorderSide(
                    color: AppColors.muted.withValues(alpha: 0.2),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // Filter chips
          FilterChips(
            selected: _filter,
            allCount: productProvider.totalCount,
            lowStockCount: productProvider.lowStockCount,
            outOfStockCount: productProvider.outOfStockCount,
            expiringSoonCount: productProvider.expiringSoonCount,
            showExpiringSoon: isPharmacy,
            serviceCount: productProvider.serviceCount,
            showServices: isSalon,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: AppSpacing.small),
          // Product list
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => productProvider.syncFromDb(),
              child: productProvider.isLoading
                ? const SkeletonList()
                : productProvider.products.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      EmptyState(
                        icon: Icons.inventory_2,
                        title: AppStrings.noProductsYet,
                        description: AppStrings.noProductsDesc,
                        ctaLabel: AppStrings.addProduct,
                        onCtaTap: () =>
                            Navigator.pushNamed(context, '/add-product'),
                      ),
                    ],
                  )
                : filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      EmptyState(
                        icon: Icons.search_off,
                        title: AppStrings.noSearchResults,
                        description: AppStrings.noSearchResultsDesc,
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                      vertical: AppSpacing.small,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.small),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return Dismissible(
                        key: ValueKey(product.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 28),
                        ),
                        confirmDismiss: (_) async {
                          return await ConfirmDialog.show(
                            context,
                            title: 'Delete ${product.name}?',
                            message: AppStrings.deleteConfirm,
                            confirmLabel: AppStrings.deleteProduct,
                            isDestructive: true,
                          );
                        },
                        onDismissed: (_) {
                          final deleted = product;
                          context.read<ProductProvider>().deleteProduct(deleted.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppStrings.deleteProduct),
                              action: SnackBarAction(
                                label: AppStrings.undo,
                                onPressed: () {
                                  context.read<ProductProvider>().addProduct(deleted);
                                },
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        },
                        child: ProductCard(
                          product: product,
                          showBatchInfo: isPharmacy,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/add-product',
                            arguments: product,
                          ),
                          onLongPress: product.isService
                              ? null
                              : () => _showProductOptions(
                                    context,
                                    product,
                                    productProvider,
                                  ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
