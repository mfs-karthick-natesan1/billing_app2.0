import 'package:flutter/foundation.dart';
import '../constants/app_strings.dart';
import '../models/business_config.dart';
import '../models/expense_category.dart';
import '../providers/customer_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/product_provider.dart';

// flutter_local_notifications and timezone are mobile-only
// All notification logic is skipped on web (kIsWeb).
// ignore: avoid_conditional_import
import '_notification_mobile.dart'
    if (dart.library.html) '_notification_stub.dart' as notif_impl;

class NotificationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    await notif_impl.initializePlugin();
    _initialized = true;
  }

  static Future<void> scheduleDailyChecks({
    required BusinessConfig config,
    required ProductProvider productProvider,
    required CustomerProvider customerProvider,
    required ExpenseProvider expenseProvider,
  }) async {
    if (kIsWeb || !_initialized) return;
    await notif_impl.cancelAll();

    if (config.notifLowStock) {
      await checkLowStock(productProvider);
    }
    if (config.notifExpiry && config.businessType == BusinessType.pharmacy) {
      await checkExpiryAlerts(productProvider);
    }
    if (config.notifCreditDue) {
      await checkCreditDue(customerProvider, config.notifCreditDueDays);
    }
    if (config.notifRecurringExpense) {
      await checkRecurringExpenses(expenseProvider);
    }
    if (config.notifEodReminder) {
      await scheduleEodReminder(config.notifEodHour, config.notifEodMinute);
    }
  }

  static Future<void> checkLowStock(ProductProvider productProvider) async {
    if (kIsWeb || !_initialized) return;
    final lowStockProducts = productProvider.productsNeedingReorder;
    for (var i = 0; i < lowStockProducts.length && i < 50; i++) {
      final product = lowStockProducts[i];
      await notif_impl.showNotification(
        id: 1000 + i,
        title: AppStrings.notifLowStockTitle,
        body:
            '${product.name} ${AppStrings.notifLowStockBody} \u2014 only ${product.stockQuantity} left',
        payload: '/reorder',
      );
    }
  }

  static Future<void> checkExpiryAlerts(
    ProductProvider productProvider,
  ) async {
    if (kIsWeb || !_initialized) return;
    int index = 0;
    final now = DateTime.now();
    for (final product in productProvider.products) {
      for (final batch in product.batches) {
        if (batch.isExpired) continue;
        final daysUntilExpiry = batch.expiryDate.difference(now).inDays;
        if (daysUntilExpiry <= 30) {
          final daysLabel = daysUntilExpiry <= 0
              ? 'has expired'
              : '${AppStrings.notifExpiryBody} $daysUntilExpiry ${AppStrings.notifDays}';
          await notif_impl.showNotification(
            id: 2000 + index,
            title: AppStrings.notifExpiryTitle,
            body: '${product.name} (${batch.batchNumber}) $daysLabel',
            payload: '/add-product',
          );
          index++;
          if (index >= 50) return;
        }
      }
    }
  }

  static Future<void> checkCreditDue(
    CustomerProvider customerProvider,
    int thresholdDays,
  ) async {
    if (kIsWeb || !_initialized) return;
    final now = DateTime.now();
    int index = 0;
    for (final customer in customerProvider.customers) {
      if (customer.outstandingBalance <= 0) continue;
      final daysSince = now.difference(customer.createdAt).inDays;
      if (daysSince >= thresholdDays) {
        await notif_impl.showNotification(
          id: 3000 + index,
          title: AppStrings.notifCreditDueTitle,
          body:
              '${customer.name} \u2014 Rs. ${customer.outstandingBalance.toStringAsFixed(0)} ${AppStrings.notifCreditBody} $daysSince ${AppStrings.notifDays}',
          payload: '/home',
        );
        index++;
        if (index >= 50) return;
      }
    }
  }

  static Future<void> checkRecurringExpenses(
    ExpenseProvider expenseProvider,
  ) async {
    if (kIsWeb || !_initialized) return;
    final recurring = expenseProvider.getRecurringExpenses();
    final now = DateTime.now();
    int index = 0;
    for (final expense in recurring) {
      final nextDue = _nextDueDate(expense.date, expense.recurringFrequency);
      if (nextDue != null) {
        final daysUntil = nextDue.difference(now).inDays;
        if (daysUntil >= 0 && daysUntil <= 2) {
          final desc =
              expense.customCategoryName ??
              expense.description ??
              expense.category.label;
          await notif_impl.showNotification(
            id: 4000 + index,
            title: AppStrings.notifRecurringTitle,
            body:
                '$desc \u2014 Rs. ${expense.amount.toStringAsFixed(0)} ${AppStrings.notifRecurringBody}',
            payload: '/expenses',
          );
          index++;
          if (index >= 20) return;
        }
      }
    }
  }

  static Future<void> scheduleEodReminder(int hour, int minute) async {
    if (kIsWeb || !_initialized) return;
    await notif_impl.scheduleEodReminder(
      hour: hour,
      minute: minute,
      title: AppStrings.notifEodTitle,
      body: AppStrings.notifEodBody,
      notificationId: 5000,
    );
  }

  /// Shows a local notification when the trial is about to expire.
  /// Call this on app open after the subscription has loaded.
  /// Only fires when [daysLeft] is 7, 3, or 1 to avoid spamming.
  static Future<void> checkTrialExpiry({required int daysLeft}) async {
    if (kIsWeb || !_initialized) return;
    if (daysLeft != 7 && daysLeft != 3 && daysLeft != 1) return;

    final dayLabel = daysLeft == 1 ? 'tomorrow' : 'in $daysLeft days';
    await notif_impl.showNotification(
      id: 6000,
      title: 'Your free trial expires $dayLabel',
      body: 'Upgrade to Pro, Pro Max or Enterprise to keep using BillReady without interruption.',
      payload: '/subscription',
    );
  }

  static Future<void> cancelAll() async {
    if (kIsWeb || !_initialized) return;
    await notif_impl.cancelAll();
  }

  static DateTime? _nextDueDate(DateTime baseDate, dynamic frequency) {
    final now = DateTime.now();
    var next = baseDate;
    for (var i = 0; i < 1000; i++) {
      if (next.isAfter(now)) return next;
      final freqName = frequency?.toString().split('.').last ?? '';
      switch (freqName) {
        case 'daily':
          next = next.add(const Duration(days: 1));
        case 'weekly':
          next = next.add(const Duration(days: 7));
        case 'monthly':
          next = DateTime(next.year, next.month + 1, next.day);
        case 'yearly':
          next = DateTime(next.year + 1, next.month, next.day);
        default:
          return null;
      }
    }
    return null;
  }
}
