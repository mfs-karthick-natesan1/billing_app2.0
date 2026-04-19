import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/customer_payment_entry.dart';
import '../providers/customer_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';

/// Sprint 4 #50 — lists every cheque still awaiting clearance and lets
/// the cashier either mark it cleared (funds received) or mark it
/// bounced (which reverses the optimistic balance reduction applied at
/// record time). The underlying state machine is enforced by
/// [CustomerProvider.clearCheque] / [CustomerProvider.bounceCheque];
/// this screen is the UI surface for those transitions.
class PendingChequesScreen extends StatelessWidget {
  const PendingChequesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerProvider = context.watch<CustomerProvider>();
    final cheques = customerProvider.pendingCheques;

    return Scaffold(
      appBar: const AppTopBar(title: 'Pending Cheques', showBack: true),
      body: cheques.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No pending cheques',
              description:
                  'Cheques you record will appear here until you mark them cleared or bounced.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.medium),
              itemCount: cheques.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.small),
              itemBuilder: (context, index) {
                final cheque = cheques[index];
                final customer = customerProvider.findById(cheque.customerId);
                return _PendingChequeCard(
                  cheque: cheque,
                  customerName: customer?.name ?? 'Unknown customer',
                );
              },
            ),
    );
  }
}

class _PendingChequeCard extends StatelessWidget {
  final CustomerPaymentEntry cheque;
  final String customerName;

  const _PendingChequeCard({
    required this.cheque,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final chequeDate = cheque.chequeDate;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: AppColors.muted.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  customerName,
                  style: AppTypography.heading.copyWith(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                Formatters.currency(cheque.amount),
                style: AppTypography.currency.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _DetailRow(
            label: 'Cheque #',
            value: cheque.chequeNumber ?? '—',
          ),
          if (cheque.chequeBank != null && cheque.chequeBank!.isNotEmpty)
            _DetailRow(label: 'Bank', value: cheque.chequeBank!),
          if (chequeDate != null)
            _DetailRow(
              label: 'Cheque date',
              value: Formatters.date(chequeDate),
            ),
          _DetailRow(
            label: 'Recorded',
            value: Formatters.date(cheque.recordedAt),
          ),
          if (cheque.notes != null && cheque.notes!.isNotEmpty)
            _DetailRow(label: 'Notes', value: cheque.notes!),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _bounce(context),
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Bounce'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _clear(context),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Mark Cleared'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.buttonRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clear(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Mark cheque cleared?',
      message:
          'The funds have been credited to your account for cheque ${cheque.chequeNumber ?? ''}.',
      confirmLabel: 'Mark cleared',
    );
    if (!confirmed || !context.mounted) return;
    final ok = context.read<CustomerProvider>().clearCheque(cheque.id);
    if (ok) {
      AppSnackbar.success(context, 'Cheque marked cleared');
    }
  }

  Future<void> _bounce(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Mark cheque bounced?',
      message:
          'The customer balance for $customerName will be restored by ${Formatters.currency(cheque.amount)}.',
      confirmLabel: 'Mark bounced',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = context.read<CustomerProvider>().bounceCheque(cheque.id);
    if (ok) {
      AppSnackbar.success(context, 'Cheque marked bounced');
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTypography.label.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.label,
            ),
          ),
        ],
      ),
    );
  }
}
