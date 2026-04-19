import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../providers/expense_provider.dart';
import '../services/expense_icon_service.dart';
import 'app_snackbar.dart';
import 'app_text_input.dart';
import 'confirm_dialog.dart';

class AddExpenseSheet extends StatefulWidget {
  final Expense? existingExpense;

  const AddExpenseSheet({super.key, this.existingExpense});

  static Future<void> show(BuildContext context, {Expense? existingExpense}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ExpenseProvider>(),
        child: AddExpenseSheet(existingExpense: existingExpense),
      ),
    );
  }

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _vendorController;
  late final TextEditingController _customCategoryController;

  ExpenseCategory? _selectedCategory;
  String _selectedCustomIconKey = 'sell';
  DateTime _selectedDate = DateTime.now();
  ExpensePaymentMode _paymentMode = ExpensePaymentMode.cash;
  bool _isRecurring = false;
  RecurringFrequency? _recurringFrequency;
  bool _autoCreate = false;

  String? _amountError;
  String? _customCategoryError;
  String? _categoryError;

  static const List<String> _customIconKeys = [
    'sell',
    'store',
    'cleaning',
    'medical',
    'payments',
  ];

  bool get _isEditing => widget.existingExpense != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingExpense;
    _amountController = TextEditingController(
      text: existing != null ? _formatAmount(existing.amount) : '',
    );
    _descriptionController = TextEditingController(
      text: existing?.description ?? '',
    );
    _vendorController = TextEditingController(text: existing?.vendorName ?? '');
    _customCategoryController = TextEditingController(
      text: existing?.customCategoryName ?? '',
    );
    _selectedCategory = existing?.category;
    _selectedCustomIconKey = existing?.customCategoryIconKey ?? 'sell';
    _selectedDate = existing?.date ?? DateTime.now();
    _paymentMode = existing?.paymentMode ?? ExpensePaymentMode.cash;
    _isRecurring = existing?.isRecurring ?? false;
    _recurringFrequency = existing?.recurringFrequency;
    _autoCreate = existing?.autoCreate ?? false;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _vendorController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final vendorSuggestions = provider.getVendorSuggestions(
      _vendorController.text,
    );

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          color: AppColors.surface,
          padding: EdgeInsets.only(
            left: AppSpacing.medium,
            right: AppSpacing.medium,
            top: AppSpacing.medium,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppSpacing.medium,
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing
                            ? AppStrings.editExpense
                            : AppStrings.addExpense,
                        style: AppTypography.heading,
                      ),
                    ),
                    if (_isEditing)
                      IconButton(
                        onPressed: _deleteExpense,
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        tooltip: AppStrings.deleteExpense,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                AppTextInput(
                  label: AppStrings.amountLabel,
                  hint: AppStrings.amountHint,
                  prefix: '${AppStrings.rsPrefix} ',
                  controller: _amountController,
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  errorText: _amountError,
                  onChanged: (_) {
                    if (_amountError != null) {
                      setState(() => _amountError = null);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  AppStrings.categoryLabel,
                  style: AppTypography.label.copyWith(
                    color: _categoryError != null
                        ? AppColors.error
                        : AppColors.muted,
                  ),
                ),
                if (_categoryError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _categoryError!,
                    style: AppTypography.label.copyWith(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.small),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ExpenseCategory.values.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.small,
                    mainAxisSpacing: AppSpacing.small,
                    childAspectRatio: 1.2,
                  ),
                  itemBuilder: (context, index) {
                    final category = ExpenseCategory.values[index];
                    final isSelected = category == _selectedCategory;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                          _categoryError = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.small),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryLight(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cardRadius,
                          ),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.muted.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              ExpenseIconService.iconForKey(category.iconKey),
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.muted,
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.label,
                              style: AppTypography.label.copyWith(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.muted,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                if (_selectedCategory == ExpenseCategory.custom) ...[
                  const SizedBox(height: AppSpacing.medium),
                  AppTextInput(
                    label: AppStrings.customCategoryName,
                    hint: AppStrings.customCategoryHint,
                    controller: _customCategoryController,
                    required: true,
                    errorText: _customCategoryError,
                    onChanged: (_) {
                      if (_customCategoryError != null) {
                        setState(() => _customCategoryError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.small,
                    children: _customIconKeys.map((iconKey) {
                      final isSelected = iconKey == _selectedCustomIconKey;
                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedCustomIconKey = iconKey),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight(0.1)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.buttonRadius,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.muted.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            ExpenseIconService.iconForKey(iconKey),
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.muted,
                            size: 18,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.medium),
                AppTextInput(
                  label: AppStrings.descriptionLabel,
                  hint: AppStrings.descriptionHint,
                  controller: _descriptionController,
                ),
                const SizedBox(height: AppSpacing.medium),
                AppTextInput(
                  label: AppStrings.vendorNameLabel,
                  hint: AppStrings.vendorNameHint,
                  controller: _vendorController,
                  onChanged: (_) => setState(() {}),
                ),
                if (vendorSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: vendorSuggestions.take(6).map((vendor) {
                      return ActionChip(
                        label: Text(vendor, style: AppTypography.label),
                        onPressed: () =>
                            setState(() => _vendorController.text = vendor),
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.medium),
                Text(AppStrings.dateLabel, style: AppTypography.label),
                const SizedBox(height: 4),
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                      border: Border.all(
                        color: AppColors.muted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Text(
                          Formatters.date(_selectedDate),
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(AppStrings.paymentModeLabel, style: AppTypography.label),
                const SizedBox(height: AppSpacing.small),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: ExpensePaymentMode.values
                      .where((mode) => mode.applicableForExpenses)
                      .map((mode) {
                    final selected = _paymentMode == mode;
                    return InkWell(
                      onTap: () => setState(() => _paymentMode = mode),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.buttonRadius,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryLight(0.1)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.buttonRadius,
                          ),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : AppColors.muted.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          mode.label,
                          style: AppTypography.label.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.medium),
                SwitchListTile(
                  value: _isRecurring,
                  onChanged: (value) => setState(() {
                    _isRecurring = value;
                    if (!value) {
                      _recurringFrequency = null;
                      _autoCreate = false;
                    }
                  }),
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppStrings.recurringExpense,
                    style: AppTypography.body,
                  ),
                ),
                if (_isRecurring) ...[
                  const SizedBox(height: AppSpacing.small),
                  DropdownButtonFormField<RecurringFrequency>(
                    initialValue: _recurringFrequency,
                    decoration: InputDecoration(
                      labelText: AppStrings.recurringFrequencyLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: RecurringFrequency.values
                        .map(
                          (frequency) => DropdownMenuItem(
                            value: frequency,
                            child: Text(frequency.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _recurringFrequency = value),
                  ),
                  SwitchListTile(
                    value: _autoCreate,
                    onChanged: (value) =>
                        setState(() => _autoCreate = value),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      AppStrings.autoCreateExpense,
                      style: AppTypography.body,
                    ),
                    subtitle: Text(
                      _autoCreate
                          ? AppStrings.autoCreateDesc
                          : AppStrings.remindOnly,
                      style: AppTypography.label.copyWith(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_recurringFrequency != null) ...[
                    Builder(builder: (context) {
                      final preview = Expense(
                        amount: 0,
                        category: ExpenseCategory.rent,
                        date: _selectedDate,
                        isRecurring: true,
                        recurringFrequency: _recurringFrequency,
                      );
                      final nextDue = preview.nextDueDate;
                      if (nextDue == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.small,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${AppStrings.nextDueLabel}: ${Formatters.date(nextDue)}',
                              style: AppTypography.label.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
                const SizedBox(height: AppSpacing.small),
                OutlinedButton.icon(
                  onPressed: () => AppSnackbar.success(
                    context,
                    AppStrings.receiptComingSoon,
                  ),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text(AppStrings.addReceipt),
                ),
                const SizedBox(height: AppSpacing.large),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      _isEditing
                          ? AppStrings.updateExpense
                          : AppStrings.saveExpense,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _deleteExpense() async {
    final expense = widget.existingExpense;
    if (expense == null) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deleteExpense,
      message: AppStrings.deleteExpenseConfirm,
      confirmLabel: AppStrings.deleteExpense,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;

    context.read<ExpenseProvider>().deleteExpense(expense.id);
    Navigator.pop(context);
    AppSnackbar.success(context, AppStrings.expenseDeleted);
  }

  void _saveExpense() {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    final customCategoryName = _customCategoryController.text.trim();

    var hasError = false;

    if (amountText.isEmpty || amount == null || amount <= 0) {
      setState(() => _amountError = AppStrings.amountRequired);
      hasError = true;
    }

    if (_selectedCategory == null) {
      setState(() => _categoryError = AppStrings.categoryRequired);
      hasError = true;
    }

    if (_selectedCategory == ExpenseCategory.custom &&
        customCategoryName.isEmpty) {
      setState(
        () => _customCategoryError = AppStrings.customCategoryNameRequired,
      );
      hasError = true;
    }

    if (_isRecurring && _recurringFrequency == null) {
      _recurringFrequency = RecurringFrequency.monthly;
    }

    if (hasError || amount == null || _selectedCategory == null) return;

    final expense = Expense(
      amount: amount,
      category: _selectedCategory!,
      customCategoryName: _selectedCategory == ExpenseCategory.custom
          ? customCategoryName
          : null,
      customCategoryIconKey: _selectedCategory == ExpenseCategory.custom
          ? _selectedCustomIconKey
          : null,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      vendorName: _vendorController.text.trim().isEmpty
          ? null
          : _vendorController.text.trim(),
      date: _selectedDate,
      paymentMode: _paymentMode,
      isRecurring: _isRecurring,
      recurringFrequency: _isRecurring ? _recurringFrequency : null,
      autoCreate: _isRecurring ? _autoCreate : false,
    );

    final provider = context.read<ExpenseProvider>();
    if (_isEditing) {
      final existing = widget.existingExpense!;
      provider.updateExpense(
        existing.copyWith(
          amount: expense.amount,
          category: expense.category,
          customCategoryName: expense.customCategoryName,
          customCategoryIconKey: expense.customCategoryIconKey,
          description: expense.description,
          date: expense.date,
          paymentMode: expense.paymentMode,
          vendorName: expense.vendorName,
          isRecurring: expense.isRecurring,
          recurringFrequency: expense.recurringFrequency,
          clearRecurringFrequency: !expense.isRecurring,
          autoCreate: expense.autoCreate,
        ),
      );
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.expenseUpdated);
      return;
    }

    provider.addExpense(expense);
    Navigator.pop(context);
    AppSnackbar.success(context, AppStrings.expenseAdded);
  }

  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return amount.toStringAsFixed(0);
    }
    return formatted;
  }
}
