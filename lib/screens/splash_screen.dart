import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_strings.dart';
import '../providers/business_config_provider.dart';
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(kIsWeb ? Duration.zero : const Duration(seconds: 2), () {
      if (!mounted) return;
      // Always require Supabase authentication (web and mobile)
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        Navigator.pushReplacementNamed(context, '/auth-login');
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
        Navigator.pushReplacementNamed(context, '/setup');
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
    });
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
