import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../constants/formatters.dart';
import '../models/bill.dart';
import '../models/payment_info.dart';
import '../widgets/invoice_share_actions.dart';

class BillDoneScreen extends StatelessWidget {
  const BillDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bill = ModalRoute.of(context)!.settings.arguments as Bill;
    final isCredit = bill.paymentMode == PaymentMode.credit;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: AppColors.success,
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(AppStrings.billCreated, style: AppTypography.heading),
                const SizedBox(height: AppSpacing.small),
                Text(
                  bill.billNumber,
                  style: AppTypography.body.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  Formatters.currency(bill.grandTotal),
                  style: AppTypography.currency.copyWith(fontSize: 24),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(bill.paymentMode.label, style: AppTypography.label),
                if (isCredit && bill.customer != null) ...[
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'Customer: ${bill.customer!.name}',
                    style: AppTypography.label,
                  ),
                  Text(
                    '${AppStrings.creditAmount}: ${Formatters.currency(bill.creditAmount)}',
                    style: AppTypography.currency.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.large),
                InvoiceShareActions(bill: bill),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/create-bill',
                        (route) => route.settings.name == '/home',
                      );
                    },
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
                      AppStrings.newBillAction,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(
                        context,
                        (route) => route.settings.name == '/home',
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius,
                        ),
                      ),
                    ),
                    child: Text(
                      AppStrings.goHome,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
