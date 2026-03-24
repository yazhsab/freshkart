import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/routes.dart';
import '../../auth/auth_provider.dart';
import '../providers/admin_nav_provider.dart';

class AdminTopbar extends ConsumerWidget {
  const AdminTopbar({super.key, this.onMenuTap, this.showMenuButton = false});

  final VoidCallback? onMenuTap;
  final bool showMenuButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRoute = ref.watch(adminNavProvider);
    final title = pageTitles[activeRoute] ?? 'Dashboard';
    final unread = ref.watch(unreadNotificationCountProvider);
    final authState = ref.watch(authProvider);
    final profile = authState.value;
    final adminName = profile?.displayName ?? 'Admin';
    final width = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.48),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            if (showMenuButton) ...[
              IconButton(
                icon: const Icon(Icons.menu_rounded, size: 22),
                onPressed: onMenuTap,
                splashRadius: 20,
                tooltip: 'Menu',
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleFor(title),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (width >= 920) ...[
              const SizedBox(width: 16),
              const _SearchBar(),
              const SizedBox(width: 16),
            ],
            _NotificationBell(
              count: unread,
              onTap: () => context.go(kAdminNotifications),
            ),
            const SizedBox(width: 12),
            _AdminDropdown(
              adminName: adminName,
              onLogout: () => ref.read(authProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleFor(String title) {
    switch (title) {
      case 'Dashboard':
        return 'Live control center for grocery and service operations';
      case 'Analytics':
        return 'Track performance with cleaner signals and sharper visual hierarchy';
      default:
        return 'Manage the platform with a more focused operational workspace';
    }
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: TextField(
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search orders, vendors, workers...',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          filled: true,
          fillColor: AppColors.surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Badge(
            isLabelVisible: count > 0,
            label: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
            backgroundColor: AppColors.error,
            child: const Icon(
              Icons.notifications_outlined,
              size: 22,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDropdown extends StatelessWidget {
  const _AdminDropdown({required this.adminName, required this.onLogout});

  final String adminName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (value) {
        switch (value) {
          case 'settings':
            context.go(kAdminConfig);
            break;
          case 'logout':
            onLogout();
            break;
          default:
            break;
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'settings',
          child: _DropdownRow(icon: Icons.settings_outlined, label: 'Settings'),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: _DropdownRow(icon: Icons.logout_rounded, label: 'Log out'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.secondary, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                adminName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DropdownRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
