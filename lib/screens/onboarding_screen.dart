import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';

const _onboardingKey = 'onboarding_complete';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  /// Returns true if the user has already completed onboarding.
  static Future<bool> isComplete() async {
    try {
      const storage = FlutterSecureStorage();
      final value = await storage.read(key: _onboardingKey);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<void> markComplete() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _onboardingKey, value: 'true');
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.receipt_long,
      title: 'Welcome to BillReady',
      subtitle: 'The fast billing app built for Indian small businesses.',
    ),
    _OnboardingPage(
      icon: Icons.inventory_2_outlined,
      title: 'Manage Inventory',
      subtitle: 'Track stock levels, set reorder alerts, and never run out.',
    ),
    _OnboardingPage(
      icon: Icons.people_outline,
      title: 'Know Your Customers',
      subtitle: 'Track credit, collect payments, and manage customer accounts.',
    ),
    _OnboardingPage(
      icon: Icons.bar_chart,
      title: 'GST-Ready Reports',
      subtitle: 'GSTR-1 export, day summaries, and cash book — all in one place.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await OnboardingScreen.markComplete();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(AppStrings.skip, style: AppTypography.label.copyWith(color: AppColors.muted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _pages[i],
              ),
            ),
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i ? AppColors.primary : AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: AppSpacing.large),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
                      ),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: isLast
                        ? _finish
                        : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
                    ),
                    child: Text(isLast ? AppStrings.getStarted : AppStrings.next),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            title,
            style: AppTypography.heading.copyWith(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            subtitle,
            style: AppTypography.body.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
