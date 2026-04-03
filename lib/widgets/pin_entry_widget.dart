import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';

typedef PinValidator = Future<bool> Function(String pin);

class PinEntryWidget extends StatefulWidget {
  final PinValidator onCompleted;
  final String? helperText;
  final bool autofocus;

  const PinEntryWidget({
    super.key,
    required this.onCompleted,
    this.helperText,
    this.autofocus = true,
  });

  @override
  State<PinEntryWidget> createState() => _PinEntryWidgetState();
}

class _PinEntryWidgetState extends State<PinEntryWidget> {
  static const int _pinLength = 4;
  static const int _maxAttempts = 3;

  String _pin = '';
  String? _error;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  Timer? _countdownTimer;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = _remainingLockSeconds;
    final isLocked = remainingSeconds > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.enterPin,
          style: AppTypography.heading.copyWith(fontSize: 20),
        ),
        if (widget.helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            widget.helperText!,
            style: AppTypography.label,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.medium),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pinLength, (index) {
            final filled = index < _pin.length;
            return Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: filled ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: filled
                      ? AppColors.primary
                      : AppColors.muted.withValues(alpha: 0.45),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.small),
        if (_error != null)
          Text(
            _error!,
            style: AppTypography.label.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        if (isLocked)
          Text(
            '${AppStrings.tryAgainIn} $remainingSeconds ${AppStrings.secondsSuffix}',
            style: AppTypography.label.copyWith(color: AppColors.error),
          ),
        const SizedBox(height: AppSpacing.medium),
        _PinKeypad(
          enabled: !isLocked && !_isSubmitting,
          onDigitTap: _onDigitTap,
          onBackspace: _onBackspace,
        ),
      ],
    );
  }

  int get _remainingLockSeconds {
    if (_lockedUntil == null) return 0;
    final remaining = _lockedUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void _onDigitTap(String digit) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin += digit;
      _error = null;
    });

    if (_pin.length == _pinLength) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _submitPin() async {
    setState(() => _isSubmitting = true);
    final isValid = await widget.onCompleted(_pin);
    if (!mounted) return;

    if (isValid) {
      setState(() {
        _failedAttempts = 0;
        _error = null;
        _pin = '';
        _isSubmitting = false;
      });
      return;
    }

    _failedAttempts += 1;
    setState(() {
      _pin = '';
      _isSubmitting = false;
      _error = AppStrings.wrongPin;
    });

    if (_failedAttempts >= _maxAttempts) {
      _failedAttempts = 0;
      _lockForThirtySeconds();
    }
  }

  void _lockForThirtySeconds() {
    _lockedUntil = DateTime.now().add(const Duration(seconds: 30));
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final remaining = _remainingLockSeconds;
      if (remaining <= 0) {
        timer.cancel();
        setState(() {
          _lockedUntil = null;
          _error = null;
        });
      } else {
        setState(() {
          _error = AppStrings.tooManyAttempts;
        });
      }
    });
    setState(() {
      _error = AppStrings.tooManyAttempts;
    });
  }
}

class _PinKeypad extends StatelessWidget {
  final bool enabled;
  final ValueChanged<String> onDigitTap;
  final VoidCallback onBackspace;

  const _PinKeypad({
    required this.enabled,
    required this.onDigitTap,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        children: [
          _row(['1', '2', '3']),
          const SizedBox(height: 8),
          _row(['4', '5', '6']),
          const SizedBox(height: 8),
          _row(['7', '8', '9']),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72, height: 48),
              _digitButton('0'),
              _iconButton(Icons.backspace_outlined, onBackspace),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_digitButton).toList(growable: false),
    );
  }

  Widget _digitButton(String digit) {
    return _keyButton(label: digit, onTap: () => onDigitTap(digit));
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return _keyButton(icon: icon, onTap: onTap);
  }

  Widget _keyButton({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 72,
      height: 48,
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.muted.withValues(alpha: 0.25)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
        ),
        child: icon != null
            ? Icon(icon, color: AppColors.onSurface)
            : Text(label!, style: AppTypography.heading.copyWith(fontSize: 20)),
      ),
    );
  }
}
