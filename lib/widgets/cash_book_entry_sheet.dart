import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/cash_book_entry.dart';
import '../providers/cash_book_provider.dart';
import 'app_snackbar.dart';

class CashBookEntrySheet extends StatefulWidget {
  final DateTime date;
  final CashEntryType type;
  final CashBookManualEntry? existingEntry;

  const CashBookEntrySheet({
    super.key,
    required this.date,
    required this.type,
    this.existingEntry,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required CashEntryType type,
    CashBookManualEntry? existingEntry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CashBookProvider>(),
        child: CashBookEntrySheet(
          date: date,
          type: type,
          existingEntry: existingEntry,
        ),
      ),
    );
  }

  @override
  State<CashBookEntrySheet> createState() => _CashBookEntrySheetState();
}

class _CashBookEntrySheetState extends State<CashBookEntrySheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  String? _amountError;
  String? _descriptionError;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: _isEditing ? _formatAmount(widget.existingEntry!.amount) : '',
    );
    _descriptionController = TextEditingController(
      text: _isEditing ? widget.existingEntry!.description : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.medium,
        right: AppSpacing.medium,
        top: AppSpacing.medium,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          Text(
            _isEditing ? AppStrings.editCashEntry : AppStrings.addCashEntry,
            style: AppTypography.heading,
          ),
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: AppStrings.amountLabel,
              prefixText: '${AppStrings.rsPrefix} ',
              errorText: _amountError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            onChanged: (_) => setState(() => _amountError = null),
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: AppStrings.entryDescription,
              hintText: AppStrings.entryDescriptionHint,
              errorText: _descriptionError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            onChanged: (_) => setState(() => _descriptionError = null),
          ),
          const SizedBox(height: AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _isEditing ? AppStrings.saveChanges : AppStrings.save,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(_amountController.text.trim());
    final description = _descriptionController.text.trim();

    var hasError = false;
    if (amount == null || amount <= 0) {
      _amountError = AppStrings.amountRequired;
      hasError = true;
    }
    if (description.isEmpty) {
      _descriptionError = AppStrings.entryDescriptionRequired;
      hasError = true;
    }
    if (hasError) {
      setState(() {});
      return;
    }
    final safeAmount = amount!;

    final provider = context.read<CashBookProvider>();
    if (_isEditing) {
      final updated = widget.existingEntry!.copyWith(
        amount: safeAmount,
        description: description,
        type: widget.type,
      );
      provider.updateManualEntry(widget.date, updated);
      Navigator.pop(context);
      AppSnackbar.success(context, AppStrings.cashEntryUpdated);
      return;
    }

    provider.addManualEntry(
      widget.date,
      CashBookManualEntry(
        amount: safeAmount,
        description: description,
        type: widget.type,
      ),
    );
    Navigator.pop(context);
    AppSnackbar.success(context, AppStrings.cashEntrySaved);
  }

  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(2);
    if (formatted.endsWith('.00')) return amount.toStringAsFixed(0);
    return formatted;
  }
}
