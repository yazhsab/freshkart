import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart/core/constants/routes.dart';
import 'package:freshkart/core/supabase/client.dart';
import 'package:freshkart/features/admin/analytics/analytics_screen.dart';
import 'package:freshkart/features/admin/bookings/bookings_screen.dart';
import 'package:freshkart/features/admin/config/config_screen.dart';
import 'package:freshkart/features/admin/customers/customers_screen.dart';
import 'package:freshkart/features/admin/dashboard/dashboard_screen.dart';
import 'package:freshkart/features/admin/delivery_agents/agents_screen.dart';
import 'package:freshkart/features/admin/notifications/notifications_screen.dart';
import 'package:freshkart/features/admin/orders/orders_screen.dart';
import 'package:freshkart/features/admin/reviews/reviews_screen.dart';
import 'package:freshkart/features/admin/service_catalog/service_catalog_screen.dart';
import 'package:freshkart/features/admin/shell/admin_shell.dart';
import 'package:freshkart/features/admin/vendor_payouts/vendor_payouts_screen.dart';
import 'package:freshkart/features/admin/vendors/vendors_screen.dart';
import 'package:freshkart/features/admin/worker_payouts/worker_payouts_screen.dart';
import 'package:freshkart/features/admin/workers/workers_screen.dart';
import 'package:freshkart/features/admin/zones/zones_screen.dart';
import 'package:freshkart/features/admin/coupons/coupons_screen.dart';
import 'package:freshkart/features/admin/wallets/wallets_screen.dart';
import 'package:freshkart/features/admin/referrals/referrals_screen.dart';
import 'package:freshkart/features/admin/loyalty/loyalty_screen.dart';
import 'package:freshkart/features/admin/analytics/enhanced_analytics_screen.dart';
import 'package:freshkart/features/auth/auth_provider.dart';
import 'package:freshkart/features/auth/login_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = ref.watch(authRefreshNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final location = state.uri.path;
      final isLoggedIn = session != null;
      final isLoginRoute = location == kLogin;
      final isAdminRoute = location.startsWith('/admin');

      if (!isLoggedIn) {
        return isLoginRoute ? null : kLogin;
      }

      if (location == '/' || isLoginRoute) {
        return kAdminDashboard;
      }

      if (!isAdminRoute) {
        return kAdminDashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (_, __) => kAdminDashboard,
      ),
      GoRoute(
        path: kLogin,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginScreen()),
      ),
      ShellRoute(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: kAdminDashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: kAdminAnalytics,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AnalyticsScreen()),
          ),
          GoRoute(
            path: kAdminCustomers,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CustomersScreen()),
          ),
          GoRoute(
            path: kAdminVendors,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VendorsScreen()),
          ),
          GoRoute(
            path: kAdminOrders,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: OrdersScreen()),
          ),
          GoRoute(
            path: kAdminProducts,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _AdminPlaceholderPage(
                title: 'Products',
                message:
                    'Product-level admin management is not wired in this app yet.',
              ),
            ),
          ),
          GoRoute(
            path: kAdminAgents,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AgentsScreen()),
          ),
          GoRoute(
            path: kAdminVendorPayouts,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VendorPayoutsScreen()),
          ),
          GoRoute(
            path: kAdminWorkers,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WorkersScreen()),
          ),
          GoRoute(
            path: kAdminBookings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BookingsScreen()),
          ),
          GoRoute(
            path: kAdminServiceCatalog,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ServiceCatalogScreen()),
          ),
          GoRoute(
            path: kAdminWorkerPayouts,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WorkerPayoutsScreen()),
          ),
          GoRoute(
            path: kAdminZones,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ZonesScreen()),
          ),
          GoRoute(
            path: kAdminNotifications,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: kAdminReviews,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReviewsScreen()),
          ),
          GoRoute(
            path: kAdminConfig,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ConfigScreen()),
          ),
          GoRoute(
            path: kAdminCoupons,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CouponsScreen()),
          ),
          GoRoute(
            path: kAdminWallets,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WalletsScreen()),
          ),
          GoRoute(
            path: kAdminReferrals,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReferralsScreen()),
          ),
          GoRoute(
            path: kAdminLoyalty,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: LoyaltyScreen()),
          ),
          GoRoute(
            path: kAdminEnhancedAnalytics,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: EnhancedAnalyticsScreen()),
          ),
        ],
      ),
    ],
  );
});

class _AdminPlaceholderPage extends StatelessWidget {
  const _AdminPlaceholderPage({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 40),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
