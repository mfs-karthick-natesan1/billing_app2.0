import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../providers/bill_provider.dart';
import '../providers/business_config_provider.dart';
import '../providers/customer_provider.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/customer_detail_sheet.dart';
import '../widgets/empty_state.dart';

class CustomerTabScreen extends StatefulWidget {
  const CustomerTabScreen({super.key});

  @override
  State<CustomerTabScreen> createState() => _CustomerTabScreenState();
}

class _CustomerTabScreenState extends State<CustomerTabScreen> {
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final billProvider = context.watch<BillProvider>();
    final isClinic = context.watch<BusinessConfigProvider>().isClinic;
    final customers = _query.isEmpty
        ? customerProvider.customers
        : customerProvider.searchCustomers(_query);

    return Scaffold(
      appBar: const AppTopBar(title: AppStrings.customersTitle),
      body: customerProvider.customers.isEmpty
          ? const EmptyState(
              icon: Icons.people,
              title: AppStrings.noCustomersYet,
              description: AppStrings.noCustomersDesc,
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
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.muted,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
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
    );
  }
}
