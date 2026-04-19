import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_typography.dart';
import '../../constants/formatters.dart';
import '../../models/business_config.dart';
import '../../models/job_card.dart';
import '../../providers/business_config_provider.dart';
import '../../models/product.dart';
import '../../providers/bill_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/job_card_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_input.dart';
import '../../widgets/app_top_bar.dart';

class JobCardDetailScreen extends StatefulWidget {
  const JobCardDetailScreen({super.key});

  @override
  State<JobCardDetailScreen> createState() => _JobCardDetailScreenState();
}

class _JobCardDetailScreenState extends State<JobCardDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _jobId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _jobId = args?['jobId'] as String? ?? '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.watch<BusinessConfigProvider>().isMobileShop;
    final provider = context.watch<JobCardProvider>();
    JobCard? jobCard;
    try {
      jobCard = provider.jobCards.firstWhere((jc) => jc.id == _jobId);
    } catch (_) {
      jobCard = null;
    }

    if (jobCard == null) {
      return const Scaffold(body: Center(child: Text('Job card not found')));
    }

    final currentJob = jobCard;

    return Scaffold(
      appBar: AppTopBar(
        title: '${AppStrings.jobNumber}${currentJob.jobNumber}',
        showBack: true,
      ),
      body: Column(
        children: [
          // Vehicle info header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.medium),
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentJob.vehicleReg,
                        style: AppTypography.heading.copyWith(fontSize: 20),
                      ),
                    ),
                    _StatusBadge(status: currentJob.status),
                  ],
                ),
                if (currentJob.vehicleMake.isNotEmpty ||
                    currentJob.vehicleModel.isNotEmpty)
                  Text(
                    '${currentJob.vehicleMake} ${currentJob.vehicleModel}'.trim(),
                    style: AppTypography.label
                        .copyWith(color: AppColors.muted),
                  ),
                if (currentJob.kmReading.isNotEmpty)
                  Text(
                    isMobile
                        ? currentJob.kmReading
                        : 'KM: ${currentJob.kmReading}',
                    style: AppTypography.label
                        .copyWith(color: AppColors.muted),
                  ),
                const SizedBox(height: 6),
                Text(
                  '${currentJob.customerName}${currentJob.customerPhone.isNotEmpty ? ' · ${currentJob.customerPhone}' : ''}',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 4),
                Text(
                  currentJob.problemDescription,
                  style: AppTypography.label
                      .copyWith(color: AppColors.onSurface),
                ),
                if (currentJob.diagnosis != null &&
                    currentJob.diagnosis!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Diagnosis: ${currentJob.diagnosis}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Status workflow
          if (currentJob.status != JobStatus.delivered &&
              currentJob.status != JobStatus.cancelled)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small,
              ),
              child: Row(
                children: [
                  if (currentJob.status.next != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => provider.updateStatus(
                          currentJob.id,
                          currentJob.status.next!,
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          '→ ${currentJob.status.next!.label}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  if (currentJob.status == JobStatus.readyForPickup) ...[
                    const SizedBox(width: AppSpacing.small),
                    OutlinedButton.icon(
                      onPressed: () =>
                          context.read<JobCardProvider>().notifyCustomerWhatsApp(
                                currentJob,
                              ),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text(AppStrings.notifyWhatsApp),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: BorderSide(
                          color: AppColors.success.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: AppStrings.partsTab),
              Tab(text: AppStrings.labourTab),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _JobItemsList(
                  jobCard: currentJob,
                  type: JobLineItemType.part,
                  addLabel: AppStrings.addPart,
                ),
                _JobItemsList(
                  jobCard: currentJob,
                  type: JobLineItemType.labour,
                  addLabel: AppStrings.addLabour,
                ),
              ],
            ),
          ),
          // Cost footer
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.muted.withValues(alpha: 0.15)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: AppTypography.body),
                    Text(
                      Formatters.currency(currentJob.totalCost),
                      style: AppTypography.heading.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (currentJob.estimatedCost != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.estimatedCost,
                        style: AppTypography.label
                            .copyWith(color: AppColors.muted),
                      ),
                      Text(
                        Formatters.currency(currentJob.estimatedCost!),
                        style: AppTypography.label
                            .copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.small),
                if (currentJob.status != JobStatus.cancelled &&
                    currentJob.status != JobStatus.delivered)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: currentJob.items.isEmpty
                          ? null
                          : () => _generateBill(context, currentJob),
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text(AppStrings.generateBill),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _generateBill(BuildContext context, JobCard jobCard) {
    final billProvider = context.read<BillProvider>();
    final customerProvider = context.read<CustomerProvider>();

    billProvider.clearActiveBill();

    // Transfer vehicle info
    billProvider.setVehicleInfo(
      vehicleReg: jobCard.vehicleReg.isNotEmpty ? jobCard.vehicleReg : null,
      vehicleMake: jobCard.vehicleMake.isNotEmpty ? jobCard.vehicleMake : null,
      vehicleModel:
          jobCard.vehicleModel.isNotEmpty ? jobCard.vehicleModel : null,
      kmReading: jobCard.kmReading.isNotEmpty ? jobCard.kmReading : null,
    );

    // Pre-select customer if linked
    if (jobCard.customerId != null) {
      try {
        final customer = customerProvider.customers.firstWhere(
          (c) => c.id == jobCard.customerId,
        );
        billProvider.setActiveCustomer(customer);
      } catch (_) {}
    }

    // Convert each job item to a temporary Product and add to the active bill
    for (final item in jobCard.items) {
      final tempProduct = Product(
        id: item.id,
        name: item.description,
        sellingPrice: item.unitPrice,
        isService: true, // prevents stock decrement for job items
        stockQuantity: 0,
        lowStockThreshold: 0,
      );
      billProvider.addItemToBill(
        tempProduct,
        businessType: BusinessType.workshop,
      );
      // addItemToBill sets quantity to minQuantity (1); fix if different
      if (item.quantity != 1) {
        final idx = billProvider.activeLineItems.indexWhere(
          (li) => li.product.id == item.id,
        );
        if (idx != -1) billProvider.updateQuantity(idx, item.quantity);
      }
    }

    // Mark job card as delivered
    context.read<JobCardProvider>().updateStatus(
      jobCard.id,
      JobStatus.delivered,
    );

    AppSnackbar.success(context, AppStrings.jobBillConverted);

    // Go to Create Bill screen so staff can review items before payment
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/create-bill',
      (route) => route.settings.name == '/home',
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final JobStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: AppTypography.label.copyWith(color: color, fontSize: 11),
      ),
    );
  }

  Color _color(JobStatus s) {
    switch (s) {
      case JobStatus.received:
        return AppColors.muted;
      case JobStatus.diagnosed:
        return AppColors.warning;
      case JobStatus.inProgress:
        return AppColors.primary;
      case JobStatus.readyForPickup:
      case JobStatus.delivered:
        return AppColors.success;
      case JobStatus.cancelled:
        return AppColors.error;
    }
  }
}

class _JobItemsList extends StatelessWidget {
  final JobCard jobCard;
  final JobLineItemType type;
  final String addLabel;

  const _JobItemsList({
    required this.jobCard,
    required this.type,
    required this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    final items =
        type == JobLineItemType.part ? jobCard.parts : jobCard.labourItems;
    final provider = context.read<JobCardProvider>();

    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No ${type.name}s added',
                    style: AppTypography.label.copyWith(color: AppColors.muted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        side: BorderSide(
                          color: AppColors.muted.withValues(alpha: 0.15),
                        ),
                      ),
                      child: ListTile(
                        title: Text(item.description, style: AppTypography.body),
                        subtitle: Text(
                          'Qty: ${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} × ${Formatters.currency(item.unitPrice)}',
                          style: AppTypography.label
                              .copyWith(color: AppColors.muted),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Formatters.currency(item.total),
                              style: AppTypography.body.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                                size: 20,
                              ),
                              onPressed: () =>
                                  provider.removeItem(jobCard.id, item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddItemSheet(context, type, provider),
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddItemSheet(
    BuildContext context,
    JobLineItemType type,
    JobCardProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddJobItemSheet(
        jobCardId: jobCard.id,
        type: type,
        provider: provider,
      ),
    );
  }
}

class _AddJobItemSheet extends StatefulWidget {
  final String jobCardId;
  final JobLineItemType type;
  final JobCardProvider provider;

  const _AddJobItemSheet({
    required this.jobCardId,
    required this.type,
    required this.provider,
  });

  @override
  State<_AddJobItemSheet> createState() => _AddJobItemSheetState();
}

class _AddJobItemSheetState extends State<_AddJobItemSheet> {
  final _descController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _searchController = TextEditingController();
  String? _descError;
  List<Product> _suggestions = [];

  @override
  void dispose() {
    _descController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (widget.type != JobLineItemType.part) return;
    final products = context.read<ProductProvider>().products;
    setState(() {
      _suggestions = query.isEmpty
          ? []
          : products
              .where((p) =>
                  p.name.toLowerCase().contains(query.toLowerCase()))
              .take(6)
              .toList();
    });
  }

  void _selectProduct(Product p) {
    _descController.text = p.name;
    _priceController.text = p.sellingPrice.toStringAsFixed(2);
    _searchController.clear();
    setState(() => _suggestions = []);
  }

  @override
  Widget build(BuildContext context) {
    final isPart = widget.type == JobLineItemType.part;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPart ? AppStrings.addPart : AppStrings.addLabour,
              style: AppTypography.heading,
            ),
            const SizedBox(height: AppSpacing.medium),
            // Product search (parts only)
            if (isPart) ...[
              AppTextInput(
                label: 'Search Product',
                hint: 'Type to search from product list...',
                controller: _searchController,
                onChanged: _onSearchChanged,
              ),
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.muted.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: _suggestions.map((p) {
                      return InkWell(
                        onTap: () => _selectProduct(p),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(p.name, style: AppTypography.body),
                              ),
                              Text(
                                Formatters.currency(p.sellingPrice),
                                style: AppTypography.label.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
              ],
            ],
            AppTextInput(
              label: AppStrings.descriptionLabel,
              hint: isPart
                  ? 'e.g. Brake pad, Engine oil'
                  : 'e.g. Labour charge, Service fee',
              required: true,
              controller: _descController,
              errorText: _descError,
              onChanged: (_) => setState(() => _descError = null),
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: AppTextInput(
                    label: AppStrings.qty,
                    hint: '1',
                    controller: _qtyController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: AppTextInput(
                    label: AppStrings.sellingPriceLabel,
                    hint: '0',
                    controller: _priceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text(AppStrings.save),
              ),
            ),
            const SizedBox(height: AppSpacing.small),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_descController.text.trim().isEmpty) {
      setState(() => _descError = 'Description is required');
      return;
    }
    final qty = double.tryParse(_qtyController.text) ?? 1;
    final price = double.tryParse(_priceController.text) ?? 0;
    widget.provider.addItem(
      widget.jobCardId,
      JobLineItem(
        type: widget.type,
        description: _descController.text.trim(),
        quantity: qty,
        unitPrice: price,
      ),
    );
    Navigator.pop(context);
  }
}
