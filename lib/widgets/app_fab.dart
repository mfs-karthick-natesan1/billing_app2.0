import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class AppFab extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Object? heroTag;

  const AppFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: AppSpacing.fabElevation,
      shape: const CircleBorder(),
      child: Icon(icon, size: 24),
    );
  }
}
