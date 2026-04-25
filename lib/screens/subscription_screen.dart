import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../models/subscription.dart';
import '../providers/subscription_provider.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/web_constraint.dart';

// Update this URL to your actual upgrade/pricing page
const _upgradeUrl = 'https://billready.in/upgrade';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: const AppTopBar(title: 'Subscription'),
      body: sub.isLoading
          ? const Center(child: CircularProgressIndicator())
          : WebConstraint(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => sub.reload(),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  children: [
                    _CurrentPlanBanner(sub: sub),
                    const SizedBox(height: AppSpacing.medium),
                    _UsageCard(sub: sub),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      'Choose a Plan',
                      style: AppTypography.heading.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _PlanCard(
                      name: 'Pro',
                      price: '₹200',
                      period: '/month',
                      color: AppColors.primary,
                      current: sub.tier == SubscriptionTier.pro,
                      features: const [
                        '500 bills/month',
                        '500 products',
                        'Up to 3 users',
                        'Cloud sync',
                        'Web access',
                        'Advanced reports',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _PlanCard(
                      name: 'Pro Max',
                      price: '₹300',
                      period: '/month',
                      color: const Color(0xFF7C3AED),
                      current: sub.tier == SubscriptionTier.proMax,
                      badge: 'Most Popular',
                      features: const [
                        'Unlimited bills',
                        'Unlimited products',
                        'Up to 10 users',
                        'Cloud sync',
                        'Web access',
                        'Advanced reports',
                        'Priority support',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _PlanCard(
                      name: 'Enterprise',
                      price: '₹700',
                      period: '/month',
                      color: const Color(0xFFB45309),
                      current: sub.tier == SubscriptionTier.enterprise,
                      features: const [
                        'Unlimited bills',
                        'Unlimited products',
                        'Unlimited users',
                        'Cloud sync',
                        'Web access',
                        'Advanced reports',
                        'Priority support',
                        'Dedicated onboarding',
                      ],
                    ),
                    const SizedBox(height: AppSpacing.large),
                    if (sub.tier != SubscriptionTier.enterprise)
                      _UpgradeButton(tier: sub.tier),
                    const SizedBox(height: AppSpacing.medium),
                    Center(
                      child: Text(
                        'Payments handled securely via our website.',
                        style: AppTypography.label.copyWith(
                          color: AppColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                  ],
                ),
              ),
            ),
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  final SubscriptionProvider sub;
  const _CurrentPlanBanner({required this.sub});

  @override
  Widget build(BuildContext context) {
    final tier = sub.tier;
    final isTrialActive = sub.isTrialActive;
    final daysLeft = sub.daysLeftInTrial;

    Color bannerColor;
    String title;
    String subtitle;
    IconData icon;

    if (isTrialActive) {
      bannerColor = AppColors.primary;
      icon = Icons.stars_rounded;
      title = 'Free Trial Active';
      subtitle = daysLeft != null
          ? '$daysLeft days remaining — full Pro Max access'
          : 'Full Pro Max access';
    } else if (tier == SubscriptionTier.free) {
      bannerColor = AppColors.muted;
      icon = Icons.lock_outline;
      title = 'Free Plan';
      subtitle = 'Upgrade to unlock more bills, products & users';
    } else {
      bannerColor = _tierColor(tier);
      icon = Icons.verified;
      title = _tierLabel(tier);
      subtitle = 'Active subscription';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 32),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.label.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _tierColor(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.pro:
        return AppColors.primary;
      case SubscriptionTier.proMax:
        return const Color(0xFF7C3AED);
      case SubscriptionTier.enterprise:
        return const Color(0xFFB45309);
      default:
        return AppColors.muted;
    }
  }

  String _tierLabel(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.pro:
        return 'Pro Plan';
      case SubscriptionTier.proMax:
        return 'Pro Max Plan';
      case SubscriptionTier.enterprise:
        return 'Enterprise Plan';
      default:
        return tier.name;
    }
  }
}

class _UsageCard extends StatelessWidget {
  final SubscriptionProvider sub;
  const _UsageCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final maxBills = sub.maxBillsPerMonth;
    final usedBills = sub.billsThisMonth;
    final isUnlimited = maxBills == -1;
    final fraction = isUnlimited
        ? 0.0
        : (usedBills / maxBills).clamp(0.0, 1.0);
    final billsColor = fraction >= 0.9 ? AppColors.error : AppColors.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        side: BorderSide(color: AppColors.muted.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage This Month',
              style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bills created', style: AppTypography.label),
                Text(
                  isUnlimited ? '$usedBills / Unlimited' : '$usedBills / $maxBills',
                  style: AppTypography.label.copyWith(
                    color: fraction >= 0.9 ? AppColors.error : AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (!isUnlimited) ...[
              LinearProgressIndicator(
                value: fraction,
                color: billsColor,
                backgroundColor: billsColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                minHeight: 8,
              ),
              if (fraction >= 0.9) ...[
                const SizedBox(height: 6),
                Text(
                  'Approaching monthly limit — upgrade to continue billing.',
                  style: AppTypography.label.copyWith(color: AppColors.error),
                ),
              ],
            ] else
              Text(
                'Unlimited billing on your current plan.',
                style: AppTypography.label.copyWith(color: AppColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final Color color;
  final bool current;
  final String? badge;
  final List<String> features;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.color,
    required this.current,
    required this.features,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: current ? color.withValues(alpha: 0.05) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: current ? color : AppColors.muted.withValues(alpha: 0.2),
          width: current ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        name,
                        style: AppTypography.heading.copyWith(
                          fontSize: 16,
                          color: color,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (current)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  period,
                  style: AppTypography.label.copyWith(color: AppColors.muted),
                ),
              ],
            ),
            const Divider(height: AppSpacing.large),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 16),
                    const SizedBox(width: 8),
                    Text(f, style: AppTypography.label),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  final SubscriptionTier tier;
  const _UpgradeButton({required this.tier});

  String get _label {
    switch (tier) {
      case SubscriptionTier.free:
      case SubscriptionTier.trial:
        return 'Upgrade to Pro';
      case SubscriptionTier.pro:
        return 'Upgrade to Pro Max';
      case SubscriptionTier.proMax:
        return 'Upgrade to Enterprise';
      default:
        return 'Upgrade';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        final uri = Uri.parse(_upgradeUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      icon: const Icon(Icons.open_in_new, size: 18),
      label: Text(_label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
        ),
      ),
    );
  }
}
