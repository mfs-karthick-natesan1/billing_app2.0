import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_strings.dart';
import '../providers/business_config_provider.dart';
import '../providers/user_provider.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  /// Optional override for whether a valid session exists.
  /// Used in tests to bypass Supabase initialization.
  final bool Function()? sessionChecker;

  /// Optional override for whether onboarding has been completed.
  /// Used in tests to bypass FlutterSecureStorage.
  final Future<bool> Function()? onboardingChecker;

  const SplashScreen({super.key, this.sessionChecker, this.onboardingChecker});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(kIsWeb ? Duration.zero : const Duration(seconds: 2));
    if (!mounted) return;
    // Always require Supabase authentication (web and mobile)
    final hasSession = widget.sessionChecker?.call()
        ?? (Supabase.instance.client.auth.currentSession != null);
    if (!hasSession) {
      // On web, FlutterSecureStorage doesn't persist reliably — always go to login.
      // On mobile, show onboarding for first-time visitors.
      final onboardingDone = kIsWeb ||
          (widget.onboardingChecker?.call() != null
              ? await widget.onboardingChecker!.call()
              : await OnboardingScreen.isComplete());
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        onboardingDone ? '/auth-login' : '/onboarding',
      );
      return;
    }
    // Check local user login before setup
    final userProvider = Provider.of<UserProvider?>(context, listen: false);
    if (userProvider?.shouldShowLoginScreen == true) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    final isSetup = context.read<BusinessConfigProvider>().isSetupCompleted;
    if (!isSetup) {
      // Logged-in but setup not complete — go directly to setup (skip onboarding)
      Navigator.pushReplacementNamed(context, '/setup');
      return;
    }
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              AppStrings.splashTitle,
              style: AppTypography.heading.copyWith(
                fontSize: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.splashSubtitle,
              style: AppTypography.body.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
