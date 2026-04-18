import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary   = Color(0xFF0D9488); // teal-600
  static const Color primaryDark = Color(0xFF0F766E); // teal-700

  // Surfaces
  static const Color surface   = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF1F5F9); // slate-100

  // Text
  static const Color onSurface = Color(0xFF0F172A); // slate-900
  static const Color muted     = Color(0xFF64748B); // slate-500

  // Semantic
  static const Color error   = Color(0xFFDC2626); // red-600
  static const Color success = Color(0xFF059669); // emerald-600
  static const Color warning = Color(0xFFD97706); // amber-600
  static const Color info    = Color(0xFF2563EB); // blue-600

  // Sidebar (desktop)
  static const Color sidebarBg       = Color(0xFF1E293B); // slate-800
  static const Color sidebarSelected = Color(0xFF0D9488); // teal-600
  static const Color sidebarText     = Color(0xFFCBD5E1); // slate-300
  static const Color sidebarTextSelected = Color(0xFFFFFFFF);

  // Derived opacities
  static Color primaryLight([double opacity = 0.10]) =>
      primary.withValues(alpha: opacity);
  static Color mutedLight([double opacity = 0.15]) =>
      muted.withValues(alpha: opacity);
  static Color errorLight([double opacity = 0.10]) =>
      error.withValues(alpha: opacity);
}
