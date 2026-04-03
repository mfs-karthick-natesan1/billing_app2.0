import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/customer.dart';
import '../providers/business_config_provider.dart';
import '../providers/customer_provider.dart';

class CustomerListSheet extends StatefulWidget {
  const CustomerListSheet({super.key});

  static Future<Customer?> show(BuildContext context) {
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: context.read<CustomerProvider>()),
          ChangeNotifierProvider.value(
            value: context.read<BusinessConfigProvider>(),
          ),
        ],
        child: const CustomerListSheet(),
      ),
    );
  }

  @override
  State<CustomerListSheet> createState() => _CustomerListSheetState();
}

class _CustomerListSheetState extends State<CustomerListSheet> {
  String _query = '';
  bool _showNewCustomerForm = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalNotesController = TextEditingController();
  final _discountController = TextEditingController();
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _nameError;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _allergiesController.dispose();
    _medicalNotesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final isClinic = context.watch<BusinessConfigProvider>().isClinic;
    final customers = _query.isEmpty
        ? customerProvider.customers
        : customerProvider.searchCustomers(_query);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Row(
                  children: [
                    Text('Select Customer', style: AppTypography.heading),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(
                        () => _showNewCustomerForm = !_showNewCustomerForm,
                      ),
                      icon: Icon(
                        _showNewCustomerForm ? Icons.close : Icons.add,
                        size: 18,
                      ),
                      label: Text(_showNewCustomerForm ? 'Cancel' : 'New'),
                    ),
                  ],
                ),
              ),
              if (!_showNewCustomerForm)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.medium,
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.small),
              Expanded(
                child: _showNewCustomerForm
                    ? ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.medium,
                        ),
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Customer Name *',
                              errorText: _nameError,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadius,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.small),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone (optional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadius,
                                ),
                              ),
                            ),
                          ),
                          if (isClinic) ...[
                            const SizedBox(height: AppSpacing.small),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _ageController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: AppStrings.ageLabel,
                                      hintText: AppStrings.ageHint,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.cardRadius,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.small),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedGender,
                                    decoration: InputDecoration(
                                      labelText: AppStrings.genderLabel,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.cardRadius,
                                        ),
                                      ),
                                    ),
                                    items: _genders
                                        .map(
                                          (g) => DropdownMenuItem(
                                            value: g,
                                            child: Text(g),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedGender = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.small),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedBloodGroup,
                              decoration: InputDecoration(
                                labelText: AppStrings.bloodGroupLabel,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius,
                                  ),
                                ),
                              ),
                              items: _bloodGroups
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedBloodGroup = v),
                            ),
                            const SizedBox(height: AppSpacing.small),
                            TextField(
                              controller: _allergiesController,
                              decoration: InputDecoration(
                                labelText: AppStrings.allergiesLabel,
                                hintText: AppStrings.allergiesHint,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.small),
                            TextField(
                              controller: _medicalNotesController,
                              decoration: InputDecoration(
                                labelText: AppStrings.medicalNotesLabel,
                                hintText: AppStrings.medicalNotesHint,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.cardRadius,
                                  ),
                                ),
                              ),
                              maxLines: 2,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.small),
                          TextField(
                            controller: _discountController,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,1}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: AppStrings.defaultDiscountLabel,
                              hintText: AppStrings.defaultDiscountHint,
                              suffixText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadius,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.small),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addNewCustomer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Add & Select'),
                            ),
                          ),
                        ],
                      )
                    : customers.isEmpty
                    ? Center(
                        child: Text(
                          'No customers found',
                          style: AppTypography.label,
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          return ListTile(
                            title: Text(
                              customer.name,
                              style: AppTypography.body,
                            ),
                            subtitle: _buildCustomerSubtitle(
                              customer,
                              isClinic,
                            ),
                            trailing: customer.outstandingBalance > 0
                                ? Text(
                                    Formatters.currency(
                                      customer.outstandingBalance,
                                    ),
                                    style: AppTypography.label.copyWith(
                                      color: AppColors.error,
                                    ),
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, customer),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addNewCustomer() {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _nameError = 'Must be at least 2 characters');
      return;
    }
    final phone = _phoneController.text.trim();
    final ageText = _ageController.text.trim();
    final allergies = _allergiesController.text.trim();
    final medicalNotes = _medicalNotesController.text.trim();

    final discountText = _discountController.text.trim();
    final discountPercent = double.tryParse(discountText) ?? 0;

    final customerProvider = context.read<CustomerProvider>();
    final customer = customerProvider.addCustomer(
      name: name,
      phone: phone.isNotEmpty ? phone : null,
      age: ageText.isNotEmpty ? int.tryParse(ageText) : null,
      gender: _selectedGender,
      bloodGroup: _selectedBloodGroup,
      allergies: allergies.isNotEmpty ? allergies : null,
      medicalNotes: medicalNotes.isNotEmpty ? medicalNotes : null,
      defaultDiscountPercent: discountPercent,
    );
    Navigator.pop(context, customer);
  }

  Widget? _buildCustomerSubtitle(Customer customer, bool isClinic) {
    final parts = <String>[];
    if (customer.phone != null) parts.add(customer.phone!);
    if (isClinic) {
      if (customer.age != null) parts.add('${customer.age}y');
      if (customer.gender != null) parts.add(customer.gender!);
    }
    if (customer.defaultDiscountPercent > 0) {
      parts.add(
        '${customer.defaultDiscountPercent.toStringAsFixed(customer.defaultDiscountPercent == customer.defaultDiscountPercent.roundToDouble() ? 0 : 1)}% disc.',
      );
    }
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '), style: AppTypography.label);
  }
}
