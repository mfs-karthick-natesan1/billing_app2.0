import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';
import '../../constants/formatters.dart';
import '../../models/business_config.dart';
import '../../models/line_item.dart';
import '../../models/product.dart';
import '../../models/table_order.dart';
import '../../providers/bill_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/table_order_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/kot_widget.dart';

class TakeOrderScreen extends StatefulWidget {
  const TakeOrderScreen({super.key});

  @override
  State<TakeOrderScreen> createState() => _TakeOrderScreenState();
}

class _TakeOrderScreenState extends State<TakeOrderScreen> {
  late String _tableLabel;
  late String _orderId;
  bool _initialized = false;
  String? _selectedCategory;
  final Map<String, GlobalKey> _categoryKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _tableLabel = args?['tableLabel'] as String? ?? 'T1';
      _orderId = args?['orderId'] as String? ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tableOrderProvider = context.watch<TableOrderProvider>();
    final productProvider = context.watch<ProductProvider>();
    final billProvider = context.watch<BillProvider>();

    TableOrder? order;
    try {
      order = tableOrderProvider.orders.firstWhere((o) => o.id == _orderId);
    } catch (_) {
      order = null;
    }

    if (order == null) {
      return Scaffold(
        appBar: AppTopBar(
          title: '${AppStrings.tableLabel} $_tableLabel',
          showBack: true,
        ),
        body: const Center(child: Text('Order not found')),
      );
    }

    final allProducts = productProvider.products;

    // Collect unique categories preserving insertion order
    final categories = <String>[];
    for (final p in allProducts) {
      final cat = p.category ?? 'No Category';
      if (!categories.contains(cat)) categories.add(cat);
    }

    // Group products by category
    final Map<String, List<Product>> byCategory = {};
    for (final cat in categories) {
      byCategory[cat] =
          allProducts.where((p) => (p.category ?? 'No Category') == cat).toList();
    }

    // Initialise GlobalKeys for scroll-to-section
    for (final cat in categories) {
      _categoryKeys.putIfAbsent(cat, () => GlobalKey());
    }

    // Default selection
    if (_selectedCategory == null && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    final currentOrder = order;

    return Scaffold(
      appBar: AppTopBar(
        title: '${AppStrings.tableLabel} $_tableLabel — ${AppStrings.tableOrder}',
        showBack: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Category sidebar ──────────────────────────────────────
                Container(
                  width: 90,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                      right: BorderSide(
                        color: AppColors.muted.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final selected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          _scrollToCategory(cat);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            cat,
                            style: AppTypography.label.copyWith(
                              color:
                                  selected ? AppColors.primary : AppColors.muted,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Product grid ──────────────────────────────────────────
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      for (final cat in categories) ...[
                        // Category header
                        SliverToBoxAdapter(
                          key: _categoryKeys[cat],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            color: AppColors.primary.withValues(alpha: 0.06),
                            child: Text(
                              cat,
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Product cards
                        SliverPadding(
                          padding: const EdgeInsets.all(8),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              childAspectRatio: 0.72,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, idx) {
                                final product = byCategory[cat]![idx];
                                LineItem? existingItem;
                                try {
                                  existingItem = currentOrder.items.firstWhere(
                                    (i) => i.product.id == product.id,
                                  );
                                } catch (_) {
                                  existingItem = null;
                                }
                                final qty = existingItem?.quantity ?? 0;
                                return _ProductCard(
                                  product: product,
                                  qty: qty,
                                  onTap: () {
                                    if (qty == 0) {
                                      tableOrderProvider.addItemToOrder(
                                        _orderId,
                                        LineItem(product: product, quantity: 1),
                                      );
                                    } else {
                                      tableOrderProvider.updateItemQuantity(
                                        _orderId,
                                        product.id,
                                        qty + 1,
                                      );
                                    }
                                  },
                                  onRemove: qty > 0
                                      ? () =>
                                          tableOrderProvider.removeItemFromOrder(
                                            _orderId,
                                            product.id,
                                          )
                                      : null,
                                );
                              },
                              childCount: byCategory[cat]!.length,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom footer ─────────────────────────────────────────────
          _OrderFooter(
            order: currentOrder,
            onSendToKitchen: currentOrder.items.isEmpty
                ? null
                : () => _sendToKitchen(context, currentOrder),
            onBillTable: currentOrder.items.isEmpty
                ? null
                : () => _billTable(
                      context,
                      currentOrder,
                      tableOrderProvider,
                      billProvider,
                    ),
          ),
        ],
      ),
    );
  }

  void _scrollToCategory(String cat) {
    final key = _categoryKeys[cat];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _sendToKitchen(BuildContext context, TableOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => KotWidget(order: order),
    );
    AppSnackbar.success(context, AppStrings.orderSent);
  }

  void _billTable(
    BuildContext context,
    TableOrder order,
    TableOrderProvider tableOrderProvider,
    BillProvider billProvider,
  ) {
    billProvider.clearActiveBill();
    for (final item in order.items) {
      billProvider.addItemToBill(
        item.product,
        businessType: BusinessType.restaurant,
      );
      final items = billProvider.activeLineItems;
      final idx = items.indexWhere((i) => i.product.id == item.product.id);
      if (idx >= 0) {
        billProvider.updateQuantity(idx, item.quantity);
      }
    }
    tableOrderProvider.markAsBilled(order.id);
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/payment',
      (route) => route.settings.name == '/home',
    );
  }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final double qty;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _ProductCard({
    required this.product,
    required this.qty,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final hasQty = qty > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasQty
                ? AppColors.success
                : AppColors.muted.withValues(alpha: 0.2),
            width: hasQty ? 2 : 1,
          ),
          color: hasQty
              ? AppColors.success.withValues(alpha: 0.04)
              : Colors.white,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product image
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(7)),
                    child: _buildImage(product.imageUrl),
                  ),
                ),
                // Product name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    product.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                // Qty pill + price pill
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
                  child: Row(
                    children: [
                      _Pill(
                        label: qty % 1 == 0
                            ? qty.toInt().toString()
                            : qty.toStringAsFixed(1),
                        borderColor: hasQty
                            ? AppColors.success
                            : AppColors.muted.withValues(alpha: 0.4),
                        textColor:
                            hasQty ? AppColors.success : AppColors.muted,
                      ),
                      const Spacer(),
                      _Pill(
                        label: Formatters.currency(product.sellingPrice),
                        borderColor: AppColors.muted.withValues(alpha: 0.3),
                        textColor: AppColors.onSurface,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Delete icon (visible only when qty > 0)
            if (onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    Widget placeholder = Container(
      color: AppColors.muted.withValues(alpha: 0.08),
      child: const Icon(Icons.restaurant, color: AppColors.muted, size: 28),
    );
    if (url == null || url.isEmpty) return placeholder;
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => placeholder,
      );
    }
    return Image.file(
      File(url),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => placeholder,
    );
  }
}

// ─── Small pill label ─────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color borderColor;
  final Color textColor;

  const _Pill({
    required this.label,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(fontSize: 9, color: textColor),
      ),
    );
  }
}

// ─── Bottom footer ────────────────────────────────────────────────────────────

class _OrderFooter extends StatelessWidget {
  final TableOrder order;
  final VoidCallback? onSendToKitchen;
  final VoidCallback? onBillTable;

  const _OrderFooter({
    required this.order,
    this.onSendToKitchen,
    this.onBillTable,
  });

  @override
  Widget build(BuildContext context) {
    final totalItems =
        order.items.fold(0.0, (sum, item) => sum + item.quantity);
    final itemsLabel = totalItems % 1 == 0
        ? totalItems.toInt().toString()
        : totalItems.toStringAsFixed(1);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.muted.withValues(alpha: 0.15)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Total: ${Formatters.currency(order.total)}',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Items ($itemsLabel)',
                  style:
                      AppTypography.label.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSendToKitchen,
                    icon: const Icon(Icons.kitchen, size: 18),
                    label: const Text(AppStrings.sendToKitchen),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onBillTable,
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text(AppStrings.billThisTable),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
