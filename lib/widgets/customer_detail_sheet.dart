import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../constants/uom_constants.dart';
import '../models/bill.dart';
import '../models/business_config.dart';
import '../models/customer.dart';
import '../models/customer_payment_entry.dart';
import '../models/payment_info.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/customer_provider.dart';
import 'app_snackbar.dart';
import 'bill_detail_sheet.dart';
import 'confirm_dialog.dart';
import 'edit_customer_sheet.dart';
import 'record_payment_sheet.dart';

class CustomerDetailSheet extends StatefulWidget {
  final Customer customer;

  const CustomerDetailSheet({super.key, required this.customer});

  static Future<void> show(BuildContext context, Customer customer) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<BillProvider>()),
          ChangeNotifierProvider.value(value: context.read<CustomerProvider>()),
          ChangeNotifierProvider.value(
            value: context.read<BusinessConfigProvider>(),
          ),
        ],
        child: CustomerDetailSheet(customer: customer),
      ),
    );
  }

  @override
  State<CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

enum _CustomerTab { allVisits, credit, payments, ledger, vehicles }

class _CustomerDetailSheetState extends State<CustomerDetailSheet> {
  _CustomerTab _activeTab = _CustomerTab.allVisits;

  @override
  Widget build(BuildContext context) {
    final billProvider = context.watch<BillProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final businessType = context.watch<BusinessConfigProvider>().businessType;

    final allBills =
        billProvider.bills
            .where((b) => b.customer?.id == widget.customer.id)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final creditBills = allBills
        .where((b) => b.paymentMode == PaymentMode.credit)
        .toList();

    final paymentHistory =
        customerProvider.getPaymentHistory(widget.customer.id);

    final displayedBills = _activeTab == _CustomerTab.credit
        ? creditBills
        : allBills;

    final totalSpent = allBills.fold(0.0, (sum, b) => sum + b.grandTotal);

    // Salon: find favourite service
    String? favouriteService;
    if (businessType == BusinessType.salon && allBills.isNotEmpty) {
      favouriteService = _findFavouriteService(allBills);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customer.name,
                              style: AppTypography.heading,
                            ),
                            if (widget.customer.phone != null)
                              Text(
                                widget.customer.phone!,
                                style: AppTypography.label,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        color: AppColors.primary,
                        tooltip: AppStrings.editCustomer,
                        onPressed: () {
                          Navigator.pop(context);
                          EditCustomerSheet.show(context, widget.customer);
                        },
                      ),
                      if (widget.customer.outstandingBalance == 0)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: AppColors.error,
                          tooltip: AppStrings.deleteCustomer,
                          onPressed: () => _confirmDelete(context),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.small),
                  // Outstanding balance
                  // Clinic patient info
                  if (businessType == BusinessType.clinic) ...[
                    const SizedBox(height: AppSpacing.small),
                    Row(
                      children: [
                        if (widget.customer.age != null)
                          _PatientInfoChip(label: '${widget.customer.age}y'),
                        if (widget.customer.gender != null)
                          _PatientInfoChip(label: widget.customer.gender!),
                        if (widget.customer.bloodGroup != null)
                          _PatientInfoChip(label: widget.customer.bloodGroup!),
                      ],
                    ),
                    if (widget.customer.allergies != null &&
                        widget.customer.allergies!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${AppStrings.allergiesLabel}: ${widget.customer.allergies}',
                          style: AppTypography.label.copyWith(
                            fontSize: 11,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.small),
                  ],
                  Row(
                    children: [
                      Text('Outstanding: ', style: AppTypography.label),
                      Text(
                        Formatters.currency(widget.customer.outstandingBalance),
                        style: AppTypography.currency.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  if (widget.customer.outstandingBalance > 0) ...[
                    const SizedBox(height: AppSpacing.small),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          RecordPaymentSheet.show(context, widget.customer);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Record Payment'),
                      ),
                    ),
                  ],
                  // Advance balance section
                  if (context.read<BusinessConfigProvider>().enableAdvancePayment) ...[
                    const SizedBox(height: AppSpacing.small),
                    Row(
                      children: [
                        Text('Advance: ', style: AppTypography.label),
                        Text(
                          Formatters.currency(widget.customer.advanceBalance),
                          style: AppTypography.currency.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showReceiveAdvanceSheet(context),
                        icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                        label: const Text('Receive Advance'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: BorderSide(color: AppColors.success.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Summary stats
            _buildSummaryStats(
              totalVisits: allBills.length,
              totalSpent: totalSpent,
              lastVisit: allBills.isNotEmpty ? allBills.first.timestamp : null,
              businessType: businessType,
              favouriteService: favouriteService,
            ),
            const SizedBox(height: AppSpacing.small),
            const Divider(height: 1),
            // Tab chips
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TabChip(
                      label: '${AppStrings.allVisits} (${allBills.length})',
                      selected: _activeTab == _CustomerTab.allVisits,
                      onTap: () => setState(
                        () => _activeTab = _CustomerTab.allVisits,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    _TabChip(
                      label: '${AppStrings.credit} (${creditBills.length})',
                      selected: _activeTab == _CustomerTab.credit,
                      onTap: () => setState(
                        () => _activeTab = _CustomerTab.credit,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    _TabChip(
                      label:
                          '${AppStrings.paymentHistory} (${paymentHistory.length})',
                      selected: _activeTab == _CustomerTab.payments,
                      onTap: () => setState(
                        () => _activeTab = _CustomerTab.payments,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    _TabChip(
                      label: AppStrings.customerLedger,
                      selected: _activeTab == _CustomerTab.ledger,
                      onTap: () => setState(
                        () => _activeTab = _CustomerTab.ledger,
                      ),
                    ),
                    if (businessType == BusinessType.workshop) ...[
                      const SizedBox(width: AppSpacing.small),
                      _TabChip(
                        label: 'Vehicles (${widget.customer.vehicles.length})',
                        selected: _activeTab == _CustomerTab.vehicles,
                        onTap: () => setState(
                          () => _activeTab = _CustomerTab.vehicles,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: _activeTab == _CustomerTab.payments
                  ? _buildPaymentHistoryList(
                      paymentHistory,
                      scrollController,
                    )
                  : _activeTab == _CustomerTab.ledger
                      ? _buildLedgerView(
                          allBills,
                          paymentHistory,
                          scrollController,
                        )
                      : _activeTab == _CustomerTab.vehicles
                          ? _buildVehiclesTab(allBills, scrollController)
                          : displayedBills.isEmpty
                              ? Center(
                                  child: Text(
                                    _activeTab == _CustomerTab.credit
                                        ? 'No credit bills'
                                        : AppStrings.noVisits,
                                    style: AppTypography.label,
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.medium,
                                  ),
                                  itemCount: displayedBills.length,
                                  itemBuilder: (context, index) {
                                    return _buildVisitCard(
                                      displayedBills[index],
                                      businessType,
                                    );
                                  },
                                ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehiclesTab(List<Bill> allBills, ScrollController scrollController) {
    final customer = widget.customer;
    if (customer.vehicles.isEmpty) {
      return const Center(
        child: Text('No vehicles recorded yet', style: TextStyle(color: AppColors.muted)),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: customer.vehicles.length,
      itemBuilder: (context, i) {
        final v = customer.vehicles[i];
        final vehicleBills = allBills
            .where((b) =>
                b.vehicleReg != null &&
                b.vehicleReg!.toLowerCase() == v.reg.toLowerCase())
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: AppSpacing.small),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            side: BorderSide(color: AppColors.mutedLight(0.4)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: const Icon(Icons.two_wheeler, color: AppColors.primary),
              title: Text(
                v.reg,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                [if (v.make != null) v.make!, if (v.model != null) v.model!]
                    .join(' · '),
                style: AppTypography.label,
              ),
              trailing: v.lastKmReading != null
                  ? Text(
                      '${v.lastKmReading} km',
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
              children: vehicleBills.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.medium),
                        child: Text('No service history', style: TextStyle(color: AppColors.muted)),
                      ),
                    ]
                  : vehicleBills.map((bill) {
                      final fmt = DateFormat('d MMM y');
                      final itemSummary = bill.lineItems
                          .map((li) => li.product.name)
                          .take(3)
                          .join(', ');
                      final more = bill.lineItems.length > 3
                          ? ' +${bill.lineItems.length - 3} more'
                          : '';
                      return ListTile(
                        dense: true,
                        onTap: () => BillDetailSheet.show(context, bill),
                        leading: const Icon(Icons.build_outlined, size: 18, color: AppColors.muted),
                        title: Text(
                          '$itemSummary$more',
                          style: AppTypography.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Text(fmt.format(bill.timestamp), style: AppTypography.label),
                            if (bill.kmReading != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${bill.kmReading} km',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Text(
                          Formatters.currency(bill.grandTotal),
                          style: AppTypography.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryStats({
    required int totalVisits,
    required double totalSpent,
    required DateTime? lastVisit,
    required BusinessType businessType,
    String? favouriteService,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      child: Row(
        children: [
          _StatItem(label: AppStrings.totalVisits, value: '$totalVisits'),
          _StatItem(
            label: AppStrings.totalSpent,
            value: Formatters.currency(totalSpent),
          ),
          _StatItem(
            label: AppStrings.lastVisit,
            value: lastVisit != null
                ? DateFormat('dd MMM').format(lastVisit)
                : '—',
          ),
          if (businessType == BusinessType.salon && favouriteService != null)
            _StatItem(
              label: AppStrings.favouriteService,
              value: favouriteService,
            ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(Bill bill, BusinessType businessType) {
    final isCreditBill = bill.paymentMode == PaymentMode.credit;

    return GestureDetector(
      onTap: () => BillDetailSheet.show(context, bill),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.small),
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bill header: number, date, amount
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.billNumber,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.date(bill.timestamp)}  ${Formatters.time(bill.timestamp)}',
                        style: AppTypography.label.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(bill.grandTotal),
                      style: AppTypography.currency.copyWith(fontSize: 14),
                    ),
                    if (isCreditBill)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppStrings.credit,
                          style: AppTypography.label.copyWith(
                            fontSize: 10,
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            // Business-type-specific items
            _buildItemDetails(bill, businessType),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetails(Bill bill, BusinessType businessType) {
    switch (businessType) {
      case BusinessType.salon:
        return _buildSalonVisitDetails(bill);
      case BusinessType.pharmacy:
        return _buildPharmacyVisitDetails(bill);
      case BusinessType.clinic:
        return _buildClinicVisitDetails(bill);
      case BusinessType.jewellery:
      case BusinessType.general:
      case BusinessType.restaurant:
      case BusinessType.workshop:
      case BusinessType.mobileShop:
        return _buildGeneralVisitDetails(bill);
    }
  }

  Widget _buildClinicVisitDetails(Bill bill) {
    final services = bill.lineItems.where((i) => i.product.isService).toList();
    final products = bill.lineItems.where((i) => !i.product.isService).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bill.diagnosis != null && bill.diagnosis!.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${AppStrings.diagnosisLabel}: ${bill.diagnosis}',
                  style: AppTypography.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
        if (bill.visitNotes != null && bill.visitNotes!.isNotEmpty) ...[
          Text(
            bill.visitNotes!,
            style: AppTypography.label.copyWith(
              fontSize: 11,
              color: AppColors.muted,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        if (services.isNotEmpty) ...[
          ...services
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: AppTypography.label.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Formatters.currency(item.subtotal),
                        style: AppTypography.label.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          if (services.length > 3)
            Text(
              '+${services.length - 3} more services',
              style: AppTypography.label.copyWith(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
        ],
        if (products.isNotEmpty) ...[
          if (services.isNotEmpty) const SizedBox(height: 2),
          ...products
              .take(2)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: AppTypography.label.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x${UomConstants.formatQty(item.quantity)}',
                        style: AppTypography.label.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        Formatters.currency(item.subtotal),
                        style: AppTypography.label.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          if (products.length > 2)
            Text(
              '+${products.length - 2} more products',
              style: AppTypography.label.copyWith(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildGeneralVisitDetails(Bill bill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...bill.lineItems
            .take(3)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        style: AppTypography.label.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'x${UomConstants.formatQty(item.quantity)}',
                      style: AppTypography.label.copyWith(fontSize: 12),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      Formatters.currency(item.subtotal),
                      style: AppTypography.label.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        if (bill.lineItems.length > 3)
          Text(
            '+${bill.lineItems.length - 3} more items',
            style: AppTypography.label.copyWith(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
      ],
    );
  }

  Widget _buildPharmacyVisitDetails(Bill bill) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...bill.lineItems
            .take(3)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: AppTypography.label.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.batch != null)
                            Text(
                              'Batch: ${item.batch!.batchNumber} | Exp: ${DateFormat('MMM yyyy').format(item.batch!.expiryDate)}',
                              style: AppTypography.label.copyWith(
                                fontSize: 10,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'x${UomConstants.formatQty(item.quantity)}',
                      style: AppTypography.label.copyWith(fontSize: 12),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      Formatters.currency(item.subtotal),
                      style: AppTypography.label.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        if (bill.lineItems.length > 3)
          Text(
            '+${bill.lineItems.length - 3} more items',
            style: AppTypography.label.copyWith(
              fontSize: 11,
              color: AppColors.muted,
            ),
          ),
      ],
    );
  }

  Widget _buildSalonVisitDetails(Bill bill) {
    final services = bill.lineItems.where((i) => i.product.isService).toList();
    final products = bill.lineItems.where((i) => !i.product.isService).toList();
    final totalDuration = services.fold<int>(
      0,
      (sum, i) => sum + ((i.product.durationMinutes ?? 0) * i.quantity).toInt(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (services.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.content_cut, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                AppStrings.servicesAvailed,
                style: AppTypography.label.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (totalDuration > 0) ...[
                const Spacer(),
                Text(
                  '$totalDuration min total',
                  style: AppTypography.label.copyWith(
                    fontSize: 11,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          ...services
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: AppTypography.label.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.product.durationMinutes != null)
                        Text(
                          '${item.product.durationMinutes} min',
                          style: AppTypography.label.copyWith(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        Formatters.currency(item.subtotal),
                        style: AppTypography.label.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          if (services.length > 3)
            Text(
              '+${services.length - 3} more services',
              style: AppTypography.label.copyWith(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
        ],
        if (products.isNotEmpty) ...[
          if (services.isNotEmpty) const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 12,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                AppStrings.productsLabel,
                style: AppTypography.label.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ...products
              .take(2)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: AppTypography.label.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'x${UomConstants.formatQty(item.quantity)}',
                        style: AppTypography.label.copyWith(fontSize: 12),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        Formatters.currency(item.subtotal),
                        style: AppTypography.label.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          if (products.length > 2)
            Text(
              '+${products.length - 2} more products',
              style: AppTypography.label.copyWith(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPaymentHistoryList(
    List<CustomerPaymentEntry> payments,
    ScrollController scrollController,
  ) {
    if (payments.isEmpty) {
      return Center(
        child: Text(AppStrings.noPaymentsYet, style: AppTypography.label),
      );
    }

    // Compute running balance: start from current outstanding,
    // work backwards through payments (sorted newest first)
    var runningBalance = widget.customer.outstandingBalance;
    final rows = <_PaymentRow>[];
    for (final p in payments) {
      rows.add(_PaymentRow(entry: p, balanceAfter: runningBalance));
      runningBalance += p.amount; // reverse: before this payment
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final p = row.entry;
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.small),
          padding: const EdgeInsets.all(AppSpacing.small),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: AppColors.muted.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.payments, size: 16, color: AppColors.success),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      Formatters.currency(p.amount),
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                  Text(
                    '${Formatters.date(p.recordedAt)}  ${Formatters.time(p.recordedAt)}',
                    style: AppTypography.label.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      p.paymentMode.label,
                      style: AppTypography.label.copyWith(fontSize: 10),
                    ),
                  ),
                  if (p.billReference != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.muted.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${AppStrings.againstBill}: ${p.billReference}',
                        style: AppTypography.label.copyWith(fontSize: 10),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${AppStrings.runningBalance}: ${Formatters.currency(row.balanceAfter)}',
                    style: AppTypography.label.copyWith(fontSize: 11),
                  ),
                ],
              ),
              if (p.notes != null && p.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  p.notes!,
                  style: AppTypography.label.copyWith(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerView(
    List<Bill> allBills,
    List<CustomerPaymentEntry> payments,
    ScrollController scrollController,
  ) {
    // Merge bills and payments into a chronological ledger
    final entries = <_LedgerEntry>[];

    for (final bill in allBills) {
      if (bill.paymentMode == PaymentMode.credit) {
        entries.add(_LedgerEntry(
          date: bill.timestamp,
          type: _LedgerType.bill,
          description: bill.billNumber,
          debit: bill.creditAmount > 0 ? bill.creditAmount : bill.grandTotal,
          credit: 0,
        ));
      }
    }

    for (final p in payments) {
      entries.add(_LedgerEntry(
        date: p.recordedAt,
        type: _LedgerType.payment,
        description: p.billReference != null
            ? '${AppStrings.paymentEntry} (${p.billReference})'
            : AppStrings.paymentEntry,
        debit: 0,
        credit: p.amount,
      ));
    }

    // Sort chronologically (oldest first)
    entries.sort((a, b) => a.date.compareTo(b.date));

    if (entries.isEmpty) {
      return Center(
        child: Text(AppStrings.noVisits, style: AppTypography.label),
      );
    }

    // Calculate running balance
    var balance = 0.0;
    for (final entry in entries) {
      balance += entry.debit - entry.credit;
      entry.balance = balance;
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.muted.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text('Date', style: AppTypography.label),
              ),
              Expanded(
                child: Text('Details', style: AppTypography.label),
              ),
              SizedBox(
                width: 65,
                child: Text(
                  'Debit',
                  style: AppTypography.label,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 65,
                child: Text(
                  'Credit',
                  style: AppTypography.label,
                  textAlign: TextAlign.right,
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  AppStrings.runningBalance,
                  style: AppTypography.label,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...entries.map((entry) {
          final isBill = entry.type == _LedgerType.bill;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.muted.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  child: Text(
                    Formatters.date(entry.date),
                    style: AppTypography.label.copyWith(fontSize: 11),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isBill ? Icons.receipt : Icons.payments,
                        size: 12,
                        color: isBill ? AppColors.error : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          entry.description,
                          style: AppTypography.body.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: Text(
                    entry.debit > 0 ? Formatters.currency(entry.debit) : '',
                    style: AppTypography.body.copyWith(
                      fontSize: 11,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 65,
                  child: Text(
                    entry.credit > 0 ? Formatters.currency(entry.credit) : '',
                    style: AppTypography.body.copyWith(
                      fontSize: 11,
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    Formatters.currency(entry.balance),
                    style: AppTypography.body.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: AppSpacing.medium),
      ],
    );
  }

  String? _findFavouriteService(List<Bill> bills) {
    final serviceCounts = <String, int>{};
    for (final bill in bills) {
      for (final item in bill.lineItems) {
        if (item.product.isService) {
          serviceCounts[item.product.name] =
              (serviceCounts[item.product.name] ?? 0) + item.quantity.toInt();
        }
      }
    }
    if (serviceCounts.isEmpty) return null;
    final sorted = serviceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deleteCustomer,
      message: AppStrings.deleteCustomerConfirm,
      confirmLabel: AppStrings.deleteCustomer,
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<CustomerProvider>().deleteCustomer(widget.customer.id);
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.customerDeleted);
    }
  }

  Future<void> _showReceiveAdvanceSheet(BuildContext context) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.medium,
            right: AppSpacing.medium,
            top: AppSpacing.medium,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.large,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Receive Advance — ${widget.customer.name}',
                  style: AppTypography.heading,
                ),
                const SizedBox(height: 4),
                Text(
                  'Current balance: ${Formatters.currency(widget.customer.advanceBalance)}',
                  style: AppTypography.label.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.large),
                TextFormField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Advance Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final amount = double.tryParse(v ?? '');
                    if (amount == null || amount <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.large),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
                      ),
                    ),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final amount = double.parse(ctrl.text);
                      ctx.read<CustomerProvider>().addAdvance(
                        widget.customer.id,
                        amount,
                      );
                      Navigator.pop(ctx);
                      AppSnackbar.success(
                        context,
                        'Advance of ${Formatters.currency(amount)} recorded',
                      );
                    },
                    child: const Text('Record Advance'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    ctrl.dispose();
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.label.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _PatientInfoChip extends StatelessWidget {
  final String label;

  const _PatientInfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          fontSize: 11,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _PaymentRow {
  final CustomerPaymentEntry entry;
  final double balanceAfter;
  const _PaymentRow({required this.entry, required this.balanceAfter});
}

enum _LedgerType { bill, payment }

class _LedgerEntry {
  final DateTime date;
  final _LedgerType type;
  final String description;
  final double debit;
  final double credit;
  double balance = 0;

  _LedgerEntry({
    required this.date,
    required this.type,
    required this.description,
    required this.debit,
    required this.credit,
  });
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight(0.10) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: selected ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
