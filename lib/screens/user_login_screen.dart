import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/pin_entry_widget.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  AppUser? _selectedUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = context.read<UserProvider>();
    if (userProvider.singleUserMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      });
      return;
    }

    if (_selectedUser == null && userProvider.activeUsers.length == 1) {
      _selectedUser = userProvider.activeUsers.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final users = userProvider.activeUsers;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.userLoginTitle, style: AppTypography.heading),
      ),
      body: SafeArea(
        child: users.isEmpty
            ? _EmptyUsersState(onContinue: _continueSingleUser)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.selectUser,
                      style: AppTypography.heading.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: users
                          .map(
                            (user) => _UserAvatarChip(
                              user: user,
                              selected: _selectedUser?.id == user.id,
                              onTap: () => setState(() => _selectedUser = user),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    if (_selectedUser != null)
                      PinEntryWidget(
                        key: ValueKey(_selectedUser!.id),
                        helperText:
                            '${AppStrings.enterPinFor} ${_selectedUser!.name}',
                        onCompleted: (pin) async {
                          final success = context
                              .read<UserProvider>()
                              .switchUser(_selectedUser!.id, pin);
                          if (!success) return false;
                          if (!mounted) return true;
                          context.read<NavigationProvider>().setTab(0);
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/home',
                            (_) => false,
                          );
                          return true;
                        },
                      )
                    else
                      Text(
                        AppStrings.tapAUserToContinue,
                        style: AppTypography.label,
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      AppStrings.forgotPinHelp,
                      style: AppTypography.label.copyWith(
                        color: AppColors.muted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    TextButton.icon(
                      onPressed: _continueSingleUser,
                      icon: const Icon(Icons.lock_open),
                      label: const Text(AppStrings.backToApp),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _continueSingleUser() {
    final userProvider = context.read<UserProvider>();
    if (userProvider.singleUserMode) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      return;
    }
    AppSnackbar.error(context, AppStrings.loginRequired);
  }
}

class _UserAvatarChip extends StatelessWidget {
  final AppUser user;
  final bool selected;
  final VoidCallback onTap;

  const _UserAvatarChip({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(user.avatarColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: Container(
        width: 112,
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.muted.withValues(alpha: 0.25),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color,
              child: Text(
                user.initials,
                style: AppTypography.body.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label,
            ),
            Text(
              user.role.shortLabel,
              style: AppTypography.label.copyWith(
                fontSize: 11,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '').toUpperCase();
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFF0F766E);
  }
}

class _EmptyUsersState extends StatelessWidget {
  final VoidCallback onContinue;

  const _EmptyUsersState({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_off, size: 48, color: AppColors.muted),
            const SizedBox(height: AppSpacing.small),
            Text(
              AppStrings.noUsersConfigured,
              style: AppTypography.heading.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.singleUserModeActive,
              style: AppTypography.label,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.medium),
            ElevatedButton(
              onPressed: onContinue,
              child: const Text(AppStrings.backToApp),
            ),
          ],
        ),
      ),
    );
  }
}
