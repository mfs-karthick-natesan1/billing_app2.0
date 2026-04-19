import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_strings.dart';
import '../models/user_role.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;

  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider?>(context, listen: true);
    final showUserMenu = userProvider != null && !userProvider.singleUserMode;
    final mergedActions = <Widget>[...?actions];
    if (showUserMenu) {
      mergedActions.add(_UserMenuButton(userProvider: userProvider));
    }

    Widget? leading;
    if (!showBack) {
      final navProvider =
          Provider.of<NavigationProvider?>(context, listen: false);
      if (navProvider != null) {
        leading = IconButton(
          icon: const Icon(Icons.menu),
          onPressed: navProvider.openDrawer,
          tooltip: AppStrings.menu,
        );
      }
    }

    return AppBar(
      title: Text(title, style: AppTypography.heading),
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      automaticallyImplyLeading: showBack,
      leading: leading,
      iconTheme: IconThemeData(color: AppColors.onSurface),
      actions: mergedActions.isEmpty ? null : mergedActions,
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  final UserProvider userProvider;

  const _UserMenuButton({required this.userProvider});

  @override
  Widget build(BuildContext context) {
    final user = userProvider.currentUser;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: AppStrings.userMenu,
      onSelected: (value) {
        if (value == 'switch') {
          userProvider.logout();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        } else if (value == 'lock') {
          userProvider.lockApp();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        } else if (value == 'logout') {
          userProvider.logout();
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          enabled: false,
          value: 'header',
          child: Text(
            '${user.name} • ${user.role.label}',
            style: AppTypography.label,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'switch',
          child: Text(AppStrings.switchUser),
        ),
        const PopupMenuItem<String>(
          value: 'lock',
          child: Text(AppStrings.lockApp),
        ),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Text(AppStrings.logoutAction),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: _parseColor(user.avatarColor),
          child: Text(
            user.initials,
            style: AppTypography.label.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
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
