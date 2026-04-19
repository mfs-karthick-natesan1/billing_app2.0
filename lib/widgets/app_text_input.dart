import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';

class AppTextInput extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final String? helperText;
  final String? prefix;
  final String? suffix;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool required;
  final bool enabled;
  final bool autoUppercase;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;

  const AppTextInput({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.helperText,
    this.prefix,
    this.suffix,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.enabled = true,
    this.autoUppercase = false,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onEditingComplete,
    this.focusNode,
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          focusNode: focusNode,
          maxLength: maxLength,
          textCapitalization: autoUppercase
              ? TextCapitalization.characters
              : TextCapitalization.none,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          style: AppTypography.body.copyWith(
            color: enabled
                ? AppColors.onSurface
                : AppColors.muted.withValues(alpha: 0.5),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: AppColors.muted),
            prefixText: prefix,
            prefixStyle: AppTypography.body.copyWith(color: AppColors.muted),
            suffixText: suffix,
            suffixStyle: AppTypography.body.copyWith(color: AppColors.muted),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: 12,
            ),
            filled: !enabled,
            fillColor: AppColors.muted.withValues(alpha: 0.08),
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
              borderSide: BorderSide(
                color: errorText != null ? AppColors.error : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              borderSide: BorderSide(color: AppColors.error, width: 2),
            ),
            suffixIcon: errorText != null
                ? const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 16,
                  )
                : null,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: AppTypography.label.copyWith(color: AppColors.error),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText!, style: AppTypography.label),
        ],
      ],
    );
  }
}
