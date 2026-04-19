import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final bool required;

  const AppDropdown({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: AppTypography.label,
            children: required
                ? [
                    TextSpan(
                      text: ' *',
                      style: AppTypography.label.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          initialValue: value,
          hint: hint != null
              ? Text(
                  hint!,
                  style: AppTypography.body.copyWith(color: AppColors.muted),
                )
              : null,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item), style: AppTypography.body),
            );
          }).toList(),
          onChanged: onChanged,
          style: AppTypography.body.copyWith(color: AppColors.onSurface),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.muted,
            size: 24,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              borderSide: BorderSide(
                color: AppColors.muted.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColors.error
                    : AppColors.muted.withValues(alpha: 0.3),
                width: errorText != null ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTypography.label.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
