import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;
  static void setBrightness(Brightness b) => _brightness = b;
  static bool get isDark => _brightness == Brightness.dark;

  // ── Brand ─────────────────────────────────────────────────────────────────
  static Color get primary => isDark
      ? const Color(0xFF2DD4BF)   // teal-300 – readable on dark
      : const Color(0xFF0D9488);  // teal-600

  static Color get primaryDark => isDark
      ? const Color(0xFF14B8A6)   // teal-400
      : const Color(0xFF0F766E);  // teal-700

  // ── Surfaces ──────────────────────────────────────────────────────────────
  static Color get surface => isDark
      ? const Color(0xFF1E293B)   // slate-800
      : const Color(0xFFFFFFFF);

  static Color get background => isDark
      ? const Color(0xFF0F172A)   // slate-900
      : const Color(0xFFF1F5F9);  // slate-100

  static Color get surfaceContainer => isDark
      ? const Color(0xFF1E293B)   // slate-800
      : const Color(0xFFFFFFFF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static Color get onSurface => isDark
      ? const Color(0xFFE2E8F0)   // slate-200
      : const Color(0xFF0F172A);  // slate-900

  static Color get muted => isDark
      ? const Color(0xFF94A3B8)   // slate-400
      : const Color(0xFF64748B);  // slate-500

  // ── Semantic ──────────────────────────────────────────────────────────────
  static Color get error => isDark
      ? const Color(0xFFF87171)   // red-400
      : const Color(0xFFDC2626);  // red-600

  static Color get success => isDark
      ? const Color(0xFF34D399)   // emerald-400
      : const Color(0xFF059669);  // emerald-600

  static const Color warning = Color(0xFFD97706); // amber-600

  static Color get info => isDark
      ? const Color(0xFF60A5FA)   // blue-400
      : const Color(0xFF2563EB);  // blue-600

  // ── Sidebar (desktop) ─────────────────────────────────────────────────────
  static const Color sidebarBg            = Color(0xFF1E293B); // slate-800
  static const Color sidebarSelected      = Color(0xFF0D9488); // teal-600
  static const Color sidebarText          = Color(0xFFCBD5E1); // slate-300
  static const Color sidebarTextSelected  = Color(0xFFFFFFFF);

  // ── Derived opacities ─────────────────────────────────────────────────────
  static Color primaryLight([double opacity = 0.10]) =>
      primary.withValues(alpha: opacity);
  static Color mutedLight([double opacity = 0.15]) =>
      muted.withValues(alpha: opacity);
  static Color errorLight([double opacity = 0.10]) =>
      error.withValues(alpha: opacity);
}
