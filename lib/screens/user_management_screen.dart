import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_strings.dart';
import '../constants/app_typography.dart';
import '../models/app_user.dart';
import '../models/user_role.dart';
import '../providers/user_provider.dart';
import '../widgets/add_edit_user_sheet.dart';
import '../widgets/app_fab.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    if (userProvider.singleUserMode) {
      return Scaffold(
        appBar: const AppTopBar(
          title: AppStrings.usersAccessTitle,
          showBack: true,
        ),
        body: _EnableUserManagementCard(
          onTap: () => AddEditUserSheet.show(context, ownerSetup: true),
        ),
      );
    }

    if (!userProvider.isOwner) {
      return Scaffold(
        appBar: const AppTopBar(
          title: AppStrings.usersAccessTitle,
          showBack: true,
        ),
        body: const EmptyState(
          icon: Icons.lock_outline,
          title: AppStrings.accessDenied,
          description: AppStrings.ownerOnlyAction,
        ),
      );
    }

    final users = userProvider.allUsers;

    return Scaffold(
      appBar: const AppTopBar(
        title: AppStrings.usersAccessTitle,
        showBack: true,
      ),
      floatingActionButton: AppFab(
        onPressed: () => AddEditUserSheet.show(context),
      ),
      body: users.isEmpty
          ? const EmptyState(
              icon: Icons.group,
              title: AppStrings.noUsersConfigured,
              description: AppStrings.addFirstUserHint,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.medium),
              itemCount: users.length,
              separatorBuilder: (_, index) =>
                  const SizedBox(height: AppSpacing.small),
              itemBuilder: (context, index) {
                final user = users[index];
                return _UserTile(user: user);
              },
            ),
    );
  }
}

class _EnableUserManagementCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EnableUserManagementCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.enableUserManagement,
                style: AppTypography.heading.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                AppStrings.enableUserManagementDesc,
                style: AppTypography.body,
              ),
              const SizedBox(height: AppSpacing.medium),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  child: const Text(AppStrings.createOwnerAccount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AppUser user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<UserProvider>();
    final avatarColor = _parseColor(user.avatarColor);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.muted.withValues(alpha: 0.2)),
      ),
      child: ListTile(
        onTap: () => AddEditUserSheet.show(context, existingUser: user),
        leading: CircleAvatar(
          backgroundColor: avatarColor,
          child: Text(
            user.initials,
            style: AppTypography.label.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.name,
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${user.role.label} • ${user.phone}',
          style: AppTypography.label,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoleBadge(role: user.role),
            const SizedBox(width: AppSpacing.small),
            if (user.role != UserRole.owner)
              IconButton(
                tooltip: user.isActive
                    ? AppStrings.deactivateUser
                    : AppStrings.reactivateUser,
                icon: Icon(
                  user.isActive
                      ? Icons.person_off_outlined
                      : Icons.person_add_alt_1_outlined,
                  color: user.isActive ? AppColors.error : AppColors.success,
                ),
                onPressed: () => _toggleActive(context, provider, user),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppStrings.primaryUser,
                  style: AppTypography.label.copyWith(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    UserProvider provider,
    AppUser user,
  ) async {
    final actionLabel = user.isActive
        ? AppStrings.deactivateUser
        : AppStrings.reactivateUser;
    final confirmed = await ConfirmDialog.show(
      context,
      title: actionLabel,
      message: user.isActive
          ? AppStrings.deactivateUserConfirm
          : AppStrings.reactivateUserConfirm,
      confirmLabel: actionLabel,
      isDestructive: user.isActive,
    );
    if (!confirmed || !context.mounted) return;

    final success = user.isActive
        ? provider.deactivateUser(user.id)
        : provider.reactivateUser(user.id);

    if (!context.mounted) return;
    if (success) {
      AppSnackbar.success(context, AppStrings.userSaved);
    } else {
      AppSnackbar.error(context, AppStrings.userSaveFailed);
    }
  }

  Color _parseColor(String hex) {
    final value = hex.replaceAll('#', '').toUpperCase();
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.tryParse(normalized, radix: 16) ?? 0xFF0F766E);
  }
}

class _RoleBadge extends StatelessWidget {
  final UserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.muted.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.shortLabel,
        style: AppTypography.label.copyWith(fontSize: 11),
      ),
    );
  }
}
