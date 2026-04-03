import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0B8B68);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1A1C1E);
  static const Color muted = Color(0xFF6B7280);
  static const Color error = Color(0xFFC73B2F);
  static const Color success = Color(0xFF0F6B52);
  static const Color warning = Color(0xFFD97706);

  // Derived opacities
  static Color primaryLight([double opacity = 0.10]) =>
      primary.withValues(alpha: opacity);
  static Color mutedLight([double opacity = 0.15]) =>
      muted.withValues(alpha: opacity);
  static Color errorLight([double opacity = 0.10]) =>
      error.withValues(alpha: opacity);
}
