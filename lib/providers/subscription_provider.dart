import 'package:flutter/foundation.dart';
import '../models/subscription.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final String? businessId;
  Subscription? _subscription;
  bool _isLoading = true;

  SubscriptionProvider({this.businessId}) {
    if (businessId != null) _load();
  }

  Subscription? get subscription => _subscription;
  bool get isLoading => _isLoading;

  SubscriptionTier get tier =>
      _subscription?.effectiveTier ?? SubscriptionTier.trial;

  bool get isTrialActive => _subscription?.isTrialActive ?? true;
  int? get daysLeftInTrial => _subscription?.daysLeftInTrial;

  // Default: trial-tier limits (unlimited bills/products, 10 users)
  static const _trialFallback = SubscriptionLimits(
    maxBillsPerMonth: -1,
    maxProducts: -1,
    maxUsers: 10,
  );

  SubscriptionLimits get limits => _subscription?.limits ?? _trialFallback;

  int get billsThisMonth => _subscription?.billsThisMonth ?? 0;
  int get maxBillsPerMonth => limits.maxBillsPerMonth;
  int get maxProducts => limits.maxProducts;
  int get maxUsers => limits.maxUsers;

  bool get canAddBill => _subscription?.canAddBill ?? true;

  bool canAddProduct(int currentProductCount) =>
      _subscription?.canAddProduct(currentProductCount) ?? true;

  bool canAddUser(int currentUserCount) =>
      _subscription?.canAddUser(currentUserCount) ?? true;

  Future<void> reload() => _load();

  Future<void> _load() async {
    if (businessId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    try {
      final row = await SupabaseService.client
          .from('subscriptions')
          .select()
          .eq('business_id', businessId!)
          .maybeSingle();
      if (row != null) {
        final remote = Subscription.fromJson(row);
        // Keep the greater of remote and any locally-tracked increments so
        // offline bumps don't get erased by a stale server read.
        final localCount = _subscription?.billsThisMonth ?? 0;
        _subscription = remote.billsThisMonth >= localCount
            ? remote
            : remote.copyWith(billsThisMonth: localCount);
      } else if (_subscription == null) {
        // First-ever load and no row yet — treat as active trial.
        _subscription = Subscription(
          businessId: businessId!,
          tier: SubscriptionTier.trial,
          trialEndsAt: DateTime.now().add(const Duration(days: 90)),
        );
      }
    } catch (_) {
      // Offline or error — ONLY fall back to a permissive trial on the
      // very first load. Otherwise preserve the last-known subscription
      // (including any locally-bumped billsThisMonth) so a user can't
      // bypass bill limits by going offline.
      if (_subscription == null) {
        _subscription = Subscription(
          businessId: businessId ?? '',
          tier: SubscriptionTier.trial,
          trialEndsAt: DateTime.now().add(const Duration(days: 90)),
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      _scheduleTrialExpiryNotif();
    }
  }

  void _scheduleTrialExpiryNotif() {
    final daysLeft = _subscription?.daysLeftInTrial;
    if (daysLeft == null) return;
    NotificationService.checkTrialExpiry(daysLeft: daysLeft);
  }

  /// Call after each finalized bill to increment the monthly counter.
  /// Bumps the local counter synchronously BEFORE the RPC so that
  /// `canAddBill` reflects the new count immediately — preventing
  /// bypass when offline or before the server roundtrip completes.
  Future<void> incrementBillCount() async {
    // Optimistic local bump — enforces the limit even if offline.
    if (_subscription != null) {
      _subscription = _subscription!
          .copyWith(billsThisMonth: _subscription!.billsThisMonth + 1);
      notifyListeners();
    }
    if (businessId == null) return;
    try {
      await SupabaseService.client.rpc(
        'increment_bill_count',
        params: {'bid': businessId},
      );
      await _load();
    } catch (_) {
      // Best-effort; local bump already applied, so limit still enforced.
    }
  }
}
