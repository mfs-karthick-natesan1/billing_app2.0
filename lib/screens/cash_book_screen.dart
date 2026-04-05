import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/cash_book_entry.dart';
import '../providers/cash_book_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/cash_book_entry_sheet.dart';
import '../widgets/cash_book_monthly_sheet.dart';
import '../widgets/confirm_dialog.dart';

class CashBookScreen extends StatefulWidget {
  final bool showBack;

  const CashBookScreen({super.key, this.showBack = false});

  @override
  State<CashBookScreen> createState() => _CashBookScreenState();
}

class _CashBookScreenState extends State<CashBookScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashBookProvider>();
    final day = provider.getCashBookDay(_selectedDate);
    final pendingCount = provider.pendingDaysCount();

    if (_notesController.text != (day.notes ?? '')) {
      _notesController.text = day.notes ?? '';
      _notesController.selection = TextSelection.collapsed(
        offset: _notesController.text.length,
      );
    }

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.cashBookTitle,
        showBack: widget.showBack,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: AppStrings.monthlyView,
            onPressed: () {
              CashBookMonthlySheet.show(
                context,
                month: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateHeader(
              selectedDate: _selectedDate,
              onPrevious: () => setState(
                () => _selectedDate = _selectedDate.subtract(
                  const Duration(days: 1),
                ),
              ),
              onNext: () => setState(
                () =>
                    _selectedDate = _selectedDate.add(const Duration(days: 1)),
              ),
              onPickDate: _pickDate,
            ),
            if (pendingCount > 0) ...[
              const SizedBox(height: AppSpacing.small),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Text(
                  '${AppStrings.pendingDaysWarning}: $pendingCount ${AppStrings.pendingDaysCountSuffix}',
                  style: AppTypography.label.copyWith(color: AppColors.error),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.medium),
            _BalanceCard(
              label: AppStrings.openingBalance,
              value: day.openingBalance,
              actionLabel: day.isClosed ? null : AppStrings.setOpeningBalance,
              onActionTap: day.isClosed
                  ? null
                  : () => _setOpeningBalance(day.openingBalance),
            ),
            const SizedBox(height: AppSpacing.medium),
            _SectionCard(
              title: AppStrings.cashSales,
              rows: [
                _AutoRow(label: AppStrings.cashSales, value: day.cashSales),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _SectionCard(
              title: AppStrings.cashReceived,
              rows: [
                _AutoRow(
                  label: AppStrings.cashReceived,
                  value: day.cashReceived,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _SectionCard(
              title: AppStrings.otherCashIn,
              rows: [
                ...day.otherCashIn.map(
                  (entry) => _ManualRow(
                    entry: entry,
                    readOnly: day.isClosed,
                    onEdit: () => CashBookEntrySheet.show(
                      context,
                      date: _selectedDate,
                      type: CashEntryType.cashIn,
                      existingEntry: entry,
                    ),
                    onDelete: () => _deleteManualEntry(entry.id),
                  ),
                ),
                if (!day.isClosed)
                  _ActionRow(
                    label: AppStrings.addCashIn,
                    onTap: () => CashBookEntrySheet.show(
                      context,
                      date: _selectedDate,
                      type: CashEntryType.cashIn,
                    ),
                  ),
              ],
              emptyLabel: AppStrings.addCashIn,
            ),
            const SizedBox(height: AppSpacing.small),
            _SectionCard(
              title: AppStrings.cashExpenses,
              rows: [
                _AutoRow(
                  label: AppStrings.cashExpenses,
                  value: day.cashExpenses,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _SectionCard(
              title: AppStrings.supplierPayments,
              rows: [
                _EditableAmountRow(
                  label: AppStrings.supplierPayments,
                  value: day.cashPaidToSuppliers,
                  readOnly: day.isClosed,
                  onEdit: () => _setSupplierPayments(day.cashPaidToSuppliers),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _SectionCard(
              title: AppStrings.otherCashOut,
              rows: [
                ...day.otherCashOut.map(
                  (entry) => _ManualRow(
                    entry: entry,
                    readOnly: day.isClosed,
                    onEdit: () => CashBookEntrySheet.show(
                      context,
                      date: _selectedDate,
                      type: CashEntryType.cashOut,
                      existingEntry: entry,
                    ),
                    onDelete: () => _deleteManualEntry(entry.id),
                  ),
                ),
                if (!day.isClosed)
                  _ActionRow(
                    label: AppStrings.addCashOut,
                    onTap: () => CashBookEntrySheet.show(
                      context,
                      date: _selectedDate,
                      type: CashEntryType.cashOut,
                    ),
                  ),
              ],
              emptyLabel: AppStrings.addCashOut,
            ),
            const SizedBox(height: AppSpacing.medium),
            _BalanceCard(
              label: AppStrings.closingBalance,
              value: day.closingBalance,
              emphasize: true,
            ),
            const SizedBox(height: AppSpacing.medium),
            _PhysicalCountRow(
              physicalCount: day.physicalCashCount,
              closingBalance: day.closingBalance,
              readOnly: day.isClosed,
              onRecord: () => _setPhysicalCashCount(day.physicalCashCount),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(AppStrings.dayNotes, style: AppTypography.label),
            const SizedBox(height: 4),
            TextField(
              controller: _notesController,
              enabled: !day.isClosed,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: AppStrings.optionalNotesHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
              ),
              onChanged: (value) => context
                  .read<CashBookProvider>()
                  .setDayNotes(_selectedDate, value),
            ),
            const SizedBox(height: AppSpacing.large),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: day.isClosed ? _reopenDay : _closeDay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: day.isClosed
                      ? AppColors.muted
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  day.isClosed ? AppStrings.reopenDay : AppStrings.closeDay,
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (day.isClosed) ...[
              const SizedBox(height: 6),
              Center(
                child: Text(
                  AppStrings.dayClosedBadge,
                  style: AppTypography.label.copyWith(color: AppColors.success),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  Future<void> _setOpeningBalance(double current) async {
    final result = await _promptAmount(
      title: AppStrings.setOpeningBalance,
      initial: current,
    );
    if (result == null || !mounted) return;
    context.read<CashBookProvider>().setOpeningBalance(_selectedDate, result);
    AppSnackbar.success(context, AppStrings.openingBalanceUpdated);
  }

  Future<void> _setSupplierPayments(double current) async {
    final result = await _promptAmount(
      title: AppStrings.supplierPayments,
      initial: current,
    );
    if (result == null || !mounted) return;
    context.read<CashBookProvider>().updateSupplierPayments(
      _selectedDate,
      result,
    );
  }

  Future<double?> _promptAmount({
    required String title,
    required double initial,
  }) async {
    final controller = TextEditingController(
      text: initial == initial.roundToDouble()
          ? initial.toStringAsFixed(0)
          : initial.toStringAsFixed(2),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title, style: AppTypography.heading),
              content: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  prefixText: '${AppStrings.rsPrefix} ',
                  errorText: error,
                ),
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(AppStrings.cancel),
                ),
                TextButton(
                  onPressed: () {
                    final parsed = double.tryParse(controller.text.trim());
                    if (parsed == null || parsed < 0) {
                      setState(() => error = AppStrings.amountRequired);
                      return;
                    }
                    Navigator.pop(ctx, parsed);
                  },
                  child: const Text(AppStrings.confirm),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return value;
  }

  Future<void> _deleteManualEntry(String entryId) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.deleteCashEntry,
      message: AppStrings.deleteCashEntryConfirm,
      confirmLabel: AppStrings.deleteCashEntry,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    context.read<CashBookProvider>().deleteManualEntry(_selectedDate, entryId);
    AppSnackbar.success(context, AppStrings.cashEntryDeleted);
  }

  Future<void> _closeDay() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: AppStrings.closeDayConfirmTitle,
      message: AppStrings.closeDayConfirmDesc,
      confirmLabel: AppStrings.closeDay,
    );
    if (!confirmed || !mounted) return;
    context.read<CashBookProvider>().closeDay(_selectedDate);
    AppSnackbar.success(context, AppStrings.dayClosedSuccess);
  }

  void _reopenDay() {
    final success = context.read<CashBookProvider>().reopenDay(_selectedDate);
    if (!success) {
      AppSnackbar.error(context, AppStrings.cannotReopenDay);
      return;
    }
    AppSnackbar.success(context, AppStrings.dayReopenedSuccess);
  }

  Future<void> _setPhysicalCashCount(double? current) async {
    final result = await _promptAmount(
      title: AppStrings.physicalCashCount,
      initial: current ?? 0,
    );
    if (result == null || !mounted) return;
    context.read<CashBookProvider>().setPhysicalCashCount(_selectedDate, result);
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  const _DateHeader({
    required this.selectedDate,
    required this.onPrevious,
    required this.onNext,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: InkWell(
            onTap: onPickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: AppColors.muted.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                Formatters.date(selectedDate),
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _BalanceCard({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = value < 0;
    final color = emphasize
        ? (isNegative ? AppColors.error : AppColors.success)
        : AppColors.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.label),
                const SizedBox(height: 4),
                Text(
                  Formatters.currency(value),
                  style: AppTypography.currency.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            TextButton(onPressed: onActionTap, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  final String? emptyLabel;

  const _SectionCard({
    required this.title,
    required this.rows,
    this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.small),
          if (rows.isEmpty && emptyLabel != null)
            Text(emptyLabel!, style: AppTypography.label)
          else
            ...rows,
        ],
      ),
    );
  }
}

class _AutoRow extends StatelessWidget {
  final String label;
  final double value;

  const _AutoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.label)),
        Text(Formatters.currency(value), style: AppTypography.body),
      ],
    );
  }
}

class _EditableAmountRow extends StatelessWidget {
  final String label;
  final double value;
  final bool readOnly;
  final VoidCallback onEdit;

  const _EditableAmountRow({
    required this.label,
    required this.value,
    required this.readOnly,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.label)),
        Text(Formatters.currency(value), style: AppTypography.body),
        if (!readOnly)
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
      ],
    );
  }
}

class _ManualRow extends StatelessWidget {
  final CashBookManualEntry entry;
  final bool readOnly;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ManualRow({
    required this.entry,
    required this.readOnly,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            entry.description,
            style: AppTypography.label.copyWith(color: AppColors.onSurface),
          ),
        ),
        Text(Formatters.currency(entry.amount), style: AppTypography.label),
        if (!readOnly) ...[
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 16),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add, size: 16),
        label: Text(label),
      ),
    );
  }
}

class _PhysicalCountRow extends StatelessWidget {
  final double? physicalCount;
  final double closingBalance;
  final bool readOnly;
  final VoidCallback onRecord;

  const _PhysicalCountRow({
    required this.physicalCount,
    required this.closingBalance,
    required this.readOnly,
    required this.onRecord,
  });

  @override
  Widget build(BuildContext context) {
    final discrepancy =
        physicalCount == null ? null : physicalCount! - closingBalance;
    final discColor = discrepancy == null
        ? AppColors.muted
        : discrepancy.abs() < 0.01
        ? AppColors.success
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.physicalCashCount,
                style: AppTypography.label,
              ),
              if (!readOnly)
                TextButton(
                  onPressed: onRecord,
                  child: Text(AppStrings.recordPhysicalCount),
                ),
            ],
          ),
          if (physicalCount != null) ...[
            Text(
              Formatters.currency(physicalCount!),
              style: AppTypography.currency,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  discrepancy != null && discrepancy.abs() < 0.01
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  size: 14,
                  color: discColor,
                ),
                const SizedBox(width: 4),
                Text(
                  discrepancy == null || discrepancy.abs() < 0.01
                      ? AppStrings.noDiscrepancy
                      : '${AppStrings.cashDiscrepancy}: ${Formatters.currency(discrepancy)}',
                  style: AppTypography.label.copyWith(color: discColor),
                ),
              ],
            ),
          ] else
            Text(
              'Not recorded yet',
              style: AppTypography.label.copyWith(color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}
