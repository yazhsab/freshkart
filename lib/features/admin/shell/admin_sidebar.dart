import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/routes.dart';
import '../../auth/auth_provider.dart';
import '../providers/admin_nav_provider.dart';
import 'admin_nav_item.dart';

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({
    super.key,
    this.collapsed = false,
    required this.onNavigate,
  });

  final bool collapsed;
  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRoute = ref.watch(adminNavProvider);
    final authState = ref.watch(authProvider);
    final profile = authState.value;

    return Container(
      width: collapsed ? 88 : 292,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sidebar, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          right: BorderSide(
            color: AppColors.sidebarStroke.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _SidebarHeader(collapsed: collapsed),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NavGroup(
                      label: 'Overview',
                      collapsed: collapsed,
                      items: [
                        _item(
                          Icons.dashboard_rounded,
                          'Dashboard',
                          kAdminDashboard,
                        ),
                        _item(
                          Icons.bar_chart_rounded,
                          'Analytics',
                          kAdminAnalytics,
                        ),
                        _item(
                          Icons.insights_rounded,
                          'Enhanced Analytics',
                          kAdminEnhancedAnalytics,
                        ),
                        _item(
                          Icons.people_rounded,
                          'Customers',
                          kAdminCustomers,
                        ),
                      ],
                      activeRoute: activeRoute,
                      onNavigate: onNavigate,
                    ),
                    _NavGroup(
                      label: 'Grocery',
                      collapsed: collapsed,
                      items: [
                        _item(Icons.store_rounded, 'Vendors', kAdminVendors),
                        _item(
                          Icons.receipt_long_rounded,
                          'Orders',
                          kAdminOrders,
                        ),
                        _item(
                          Icons.inventory_2_rounded,
                          'Products',
                          kAdminProducts,
                        ),
                        _item(
                          Icons.delivery_dining_rounded,
                          'Delivery Agents',
                          kAdminAgents,
                        ),
                        _item(
                          Icons.account_balance_wallet_rounded,
                          'Vendor Payouts',
                          kAdminVendorPayouts,
                        ),
                      ],
                      activeRoute: activeRoute,
                      onNavigate: onNavigate,
                    ),
                    _NavGroup(
                      label: 'Services',
                      collapsed: collapsed,
                      items: [
                        _item(
                          Icons.engineering_rounded,
                          'Workers',
                          kAdminWorkers,
                        ),
                        _item(
                          Icons.calendar_month_rounded,
                          'Bookings',
                          kAdminBookings,
                        ),
                        _item(
                          Icons.home_repair_service_rounded,
                          'Service Catalog',
                          kAdminServiceCatalog,
                        ),
                        _item(
                          Icons.payments_rounded,
                          'Worker Payouts',
                          kAdminWorkerPayouts,
                        ),
                      ],
                      activeRoute: activeRoute,
                      onNavigate: onNavigate,
                    ),
                    _NavGroup(
                      label: 'Growth',
                      collapsed: collapsed,
                      items: [
                        _item(
                          Icons.local_offer_rounded,
                          'Coupons',
                          kAdminCoupons,
                        ),
                        _item(
                          Icons.account_balance_wallet_rounded,
                          'Wallets',
                          kAdminWallets,
                        ),
                        _item(
                          Icons.card_giftcard_rounded,
                          'Referrals',
                          kAdminReferrals,
                        ),
                        _item(Icons.stars_rounded, 'Loyalty', kAdminLoyalty),
                      ],
                      activeRoute: activeRoute,
                      onNavigate: onNavigate,
                    ),
                    _NavGroup(
                      label: 'Platform',
                      collapsed: collapsed,
                      items: [
                        _item(Icons.map_rounded, 'Zones', kAdminZones),
                        _item(
                          Icons.campaign_rounded,
                          'Notifications',
                          kAdminNotifications,
                        ),
                        _item(Icons.star_rounded, 'Reviews', kAdminReviews),
                        _item(Icons.settings_rounded, 'Config', kAdminConfig),
                      ],
                      activeRoute: activeRoute,
                      onNavigate: onNavigate,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                collapsed ? 10 : 16,
                0,
                collapsed ? 10 : 16,
                16,
              ),
              child: _SidebarFooter(
                collapsed: collapsed,
                displayName: profile?.displayName ?? 'Admin User',
                initials: profile?.initials ?? 'A',
                onLogout: () => ref.read(authProvider.notifier).signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _NavDef _item(IconData icon, String label, String route) {
    return _NavDef(icon: icon, label: label, route: route);
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool collapsed;

  const _SidebarHeader({required this.collapsed});

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.eco_rounded, color: Colors.white, size: 28),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FreshKart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Operations cockpit',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Live control center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavGroup extends StatelessWidget {
  final String label;
  final bool collapsed;
  final List<_NavDef> items;
  final String activeRoute;
  final ValueChanged<String> onNavigate;

  const _NavGroup({
    required this.label,
    required this.collapsed,
    required this.items,
    required this.activeRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          )
        else
          const SizedBox(height: 10),
        ...items.map(
          (item) => AdminNavItem(
            icon: item.icon,
            label: item.label,
            route: item.route,
            isActive: activeRoute == item.route,
            collapsed: collapsed,
            onTap: () => onNavigate(item.route),
          ),
        ),
      ],
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final bool collapsed;
  final String displayName;
  final String initials;
  final VoidCallback onLogout;

  const _SidebarFooter({
    required this.collapsed,
    required this.displayName,
    required this.initials,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(collapsed ? 10 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: collapsed
          ? Column(
              children: [
                _AdminAvatar(initials: initials),
                const SizedBox(height: 10),
                _LogoutButton(onLogout: onLogout),
              ],
            )
          : Row(
              children: [
                _AdminAvatar(initials: initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'CONTROL',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _LogoutButton(onLogout: onLogout),
              ],
            ),
    );
  }
}

class _AdminAvatar extends StatelessWidget {
  final String initials;

  const _AdminAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onLogout,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

class _NavDef {
  final IconData icon;
  final String label;
  final String route;

  const _NavDef({required this.icon, required this.label, required this.route});
}
