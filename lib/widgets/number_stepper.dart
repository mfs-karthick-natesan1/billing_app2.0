import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';
import '../constants/uom_constants.dart';

class NumberStepper extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final double step;
  final ValueChanged<double> onChanged;

  const NumberStepper({
    super.key,
    required this.value,
    this.minValue = 1,
    this.maxValue = 9999,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isAtMin = value <= minValue;

    return SizedBox(
      width: 128,
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepButton(
            icon: Icons.remove,
            enabled: !isAtMin,
            onTap: isAtMin
                ? null
                : () {
                    final newVal = value - step;
                    if (newVal >= minValue) onChanged(newVal);
                  },
          ),
          GestureDetector(
            onTap: () => _showEditDialog(context),
            child: Container(
              constraints: const BoxConstraints(minWidth: 32),
              alignment: Alignment.center,
              child: Text(
                UomConstants.formatQty(value),
                style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            enabled: value < maxValue,
            onTap: value >= maxValue
                ? null
                : () {
                    final newVal = value + step;
                    if (newVal <= maxValue) onChanged(newVal);
                  },
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(
      text: UomConstants.formatQty(value),
    );
    final allowDecimal = step < 1 || step != step.roundToDouble();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Quantity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          inputFormatters: [
            if (allowDecimal)
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
            else
              FilteringTextInputFormatter.digitsOnly,
          ],
          autofocus: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newVal = double.tryParse(controller.text);
              if (newVal != null && newVal >= minValue && newVal <= maxValue) {
                onChanged(newVal);
              }
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryLight(0.10)
              : AppColors.muted.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled
              ? AppColors.primary
              : AppColors.muted.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}
