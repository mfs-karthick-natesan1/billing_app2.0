enum SubscriptionTier { free, trial, pro, proMax, enterprise }

/// Default limits per tier — used as fallback when the DB row has no overrides.
/// Admin can override per-business by setting max_bills_per_month /
/// max_products / max_users directly in the Supabase subscriptions row.
const tierLimits = {
  SubscriptionTier.free:       _TierDefaults(bills: 50,  products: 50,  users: 1),
  SubscriptionTier.trial:      _TierDefaults(bills: -1,  products: -1,  users: 10),
  SubscriptionTier.pro:        _TierDefaults(bills: 500, products: 500, users: 3),
  SubscriptionTier.proMax:     _TierDefaults(bills: -1,  products: -1,  users: 10),
  SubscriptionTier.enterprise: _TierDefaults(bills: -1,  products: -1,  users: -1),
};

class _TierDefaults {
  final int bills;
  final int products;
  final int users;
  const _TierDefaults({required this.bills, required this.products, required this.users});
}

class SubscriptionLimits {
  final int maxBillsPerMonth; // -1 = unlimited
  final int maxProducts;      // -1 = unlimited
  final int maxUsers;         // -1 = unlimited

  const SubscriptionLimits({
    required this.maxBillsPerMonth,
    required this.maxProducts,
    required this.maxUsers,
  });
}

class Subscription {
  final String businessId;
  final SubscriptionTier tier;
  final int billsThisMonth;
  final DateTime? trialEndsAt;
  final DateTime? expiresAt;

  /// Per-business limit overrides — set from Supabase row.
  /// Falls back to [tierLimits] defaults when null.
  final int? _maxBillsOverride;
  final int? _maxProductsOverride;
  final int? _maxUsersOverride;

  const Subscription({
    required this.businessId,
    this.tier = SubscriptionTier.trial,
    this.billsThisMonth = 0,
    this.trialEndsAt,
    this.expiresAt,
    int? maxBillsOverride,
    int? maxProductsOverride,
    int? maxUsersOverride,
  })  : _maxBillsOverride = maxBillsOverride,
        _maxProductsOverride = maxProductsOverride,
        _maxUsersOverride = maxUsersOverride;

  // ── Tier resolution ──────────────────────────────────────────────────────────

  bool get isTrialActive =>
      tier == SubscriptionTier.trial &&
      trialEndsAt != null &&
      trialEndsAt!.isAfter(DateTime.now());

  bool get isTrialExpired =>
      tier == SubscriptionTier.trial &&
      (trialEndsAt == null || trialEndsAt!.isBefore(DateTime.now()));

  bool get isPaidExpired =>
      tier != SubscriptionTier.trial &&
      tier != SubscriptionTier.free &&
      expiresAt != null &&
      expiresAt!.isBefore(DateTime.now());

  /// Effective tier after expiry checks.
  SubscriptionTier get effectiveTier {
    if (isTrialExpired) return SubscriptionTier.free;
    if (isPaidExpired) return SubscriptionTier.free;
    return tier;
  }

  int? get daysLeftInTrial {
    if (!isTrialActive) return null;
    return trialEndsAt!.difference(DateTime.now()).inDays;
  }

  // ── Limits (DB override → tier default) ─────────────────────────────────────

  SubscriptionLimits get limits {
    final defaults = tierLimits[effectiveTier] ?? tierLimits[SubscriptionTier.free]!;
    return SubscriptionLimits(
      maxBillsPerMonth: _maxBillsOverride ?? defaults.bills,
      maxProducts:      _maxProductsOverride ?? defaults.products,
      maxUsers:         _maxUsersOverride ?? defaults.users,
    );
  }

  // ── Gates ────────────────────────────────────────────────────────────────────

  bool get canAddBill {
    final max = limits.maxBillsPerMonth;
    return max == -1 || billsThisMonth < max;
  }

  bool canAddProduct(int currentProductCount) {
    final max = limits.maxProducts;
    return max == -1 || currentProductCount < max;
  }

  bool canAddUser(int currentUserCount) {
    final max = limits.maxUsers;
    return max == -1 || currentUserCount < max;
  }

  // ── Deserialisation ──────────────────────────────────────────────────────────

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      businessId: json['business_id'] as String? ?? '',
      tier: _tierFrom(json['tier'] as String?),
      billsThisMonth: (json['bills_this_month'] as num?)?.toInt() ?? 0,
      trialEndsAt: json['trial_ends_at'] != null
          ? DateTime.tryParse(json['trial_ends_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      // Optional per-business overrides set by admin in Supabase
      maxBillsOverride:    (json['max_bills_per_month'] as num?)?.toInt(),
      maxProductsOverride: (json['max_products'] as num?)?.toInt(),
      maxUsersOverride:    (json['max_users'] as num?)?.toInt(),
    );
  }

  static SubscriptionTier _tierFrom(String? value) {
    for (final t in SubscriptionTier.values) {
      if (t.name == value) return t;
    }
    return SubscriptionTier.trial;
  }
}
