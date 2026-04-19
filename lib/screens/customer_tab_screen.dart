import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/customer.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/customer_provider.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/customer_detail_sheet.dart';
import '../widgets/empty_state.dart';

enum _CustomerSort { nameAsc, nameDesc, balanceDesc, balanceAsc }

class CustomerTabScreen extends StatefulWidget {
  const CustomerTabScreen({super.key});

  @override
  State<CustomerTabScreen> createState() => _CustomerTabScreenState();
}

class _CustomerTabScreenState extends State<CustomerTabScreen> {
  String _query = '';
  _CustomerSort _sort = _CustomerSort.nameAsc;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _applySortCustomers(List<Customer> customers) {
    final sorted = customers.toList();
    switch (_sort) {
      case _CustomerSort.nameAsc:
        sorted.sort((a, b) => a.name.compareTo(b.name));
      case _CustomerSort.nameDesc:
        sorted.sort((a, b) => b.name.compareTo(a.name));
      case _CustomerSort.balanceDesc:
        sorted.sort((a, b) => b.outstandingBalance.compareTo(a.outstandingBalance));
      case _CustomerSort.balanceAsc:
        sorted.sort((a, b) => a.outstandingBalance.compareTo(b.outstandingBalance));
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final billProvider = context.watch<BillProvider>();
    final isClinic = context.watch<BusinessConfigProvider>().isClinic;
    var customers = _query.isEmpty
        ? customerProvider.customers.toList()
        : customerProvider.searchCustomers(_query);
    customers = _applySortCustomers(customers);

    final pendingChequeCount = customerProvider.pendingCheques.length;

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.customersTitle,
        actions: [
          IconButton(
            tooltip: 'Pending cheques',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.receipt_long_outlined),
                if (pendingChequeCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$pendingChequeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () =>
                Navigator.pushNamed(context, '/pending-cheques'),
          ),
          PopupMenuButton<_CustomerSort>(
            icon: const Icon(Icons.sort),
            initialValue: _sort,
            onSelected: (s) => setState(() => _sort = s),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _CustomerSort.nameAsc, child: Text('Name: A–Z')),
              PopupMenuItem(value: _CustomerSort.nameDesc, child: Text('Name: Z–A')),
              PopupMenuItem(value: _CustomerSort.balanceDesc, child: Text('Balance: high to low')),
              PopupMenuItem(value: _CustomerSort.balanceAsc, child: Text('Balance: low to high')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => customerProvider.syncFromDb(),
        child: customerProvider.customers.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                EmptyState(
                  icon: Icons.people,
                  title: AppStrings.noCustomersYet,
                  description: AppStrings.noCustomersDesc,
                ),
              ],
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.muted,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.muted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.muted.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                        borderSide: BorderSide(
                          color: AppColors.muted.withValues(alpha: 0.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final visitCount = billProvider.bills
                          .where((b) => b.customer?.id == customer.id)
                          .length;
                      return ListTile(
                        title: Text(
                          customer.name,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            if (customer.phone != null) ...[
                              Text(customer.phone!, style: AppTypography.label),
                              const SizedBox(width: AppSpacing.small),
                            ],
                            if (isClinic && customer.age != null) ...[
                              Text(
                                '${customer.age}y',
                                style: AppTypography.label.copyWith(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            if (isClinic && customer.gender != null) ...[
                              Text(
                                customer.gender!,
                                style: AppTypography.label.copyWith(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.small),
                            ],
                            Text(
                              '$visitCount ${visitCount == 1 ? 'visit' : 'visits'}',
                              style: AppTypography.label.copyWith(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                        trailing: customer.outstandingBalance > 0
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Formatters.currency(
                                      customer.outstandingBalance,
                                    ),
                                    style: AppTypography.currency.copyWith(
                                      color: AppColors.error,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'due',
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'No dues',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                        onTap: () =>
                            CustomerDetailSheet.show(context, customer),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
