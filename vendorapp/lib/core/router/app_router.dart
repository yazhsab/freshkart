import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/storage/local_storage.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/features/shared/widgets/vendor_bottom_nav.dart';

// Auth screens
import 'package:freshkart_vendor/features/splash/splash_screen.dart';
import 'package:freshkart_vendor/features/auth/screens/phone_screen.dart';
import 'package:freshkart_vendor/features/auth/screens/otp_screen.dart';
import 'package:freshkart_vendor/features/auth/screens/register_vendor_screen.dart';
import 'package:freshkart_vendor/features/auth/screens/pending_approval_screen.dart';

// Dashboard
import 'package:freshkart_vendor/features/dashboard/screens/dashboard_screen.dart';

// Inventory
import 'package:freshkart_vendor/features/inventory/screens/inventory_screen.dart';
import 'package:freshkart_vendor/features/inventory/screens/add_edit_product_screen.dart';
import 'package:freshkart_vendor/features/inventory/screens/low_stock_screen.dart';
import 'package:freshkart_vendor/features/inventory/screens/bulk_update_screen.dart';

// Earnings
import 'package:freshkart_vendor/features/earnings/screens/earnings_screen.dart';
import 'package:freshkart_vendor/features/earnings/screens/payout_history_screen.dart';
import 'package:freshkart_vendor/features/earnings/screens/transaction_detail_screen.dart';
import 'package:freshkart_vendor/features/earnings/providers/earnings_provider.dart';

// Shop
import 'package:freshkart_vendor/features/shop/screens/shop_profile_screen.dart';
import 'package:freshkart_vendor/features/shop/screens/edit_shop_screen.dart';
import 'package:freshkart_vendor/features/shop/screens/working_hours_screen.dart';
import 'package:freshkart_vendor/features/shop/screens/bank_details_screen.dart';
import 'package:freshkart_vendor/features/shop/screens/upload_docs_screen.dart';

// ---------------------------------------------------------------------------
// Navigator keys
// ---------------------------------------------------------------------------

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _dashboardNavKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _ordersNavKey = GlobalKey<NavigatorState>(debugLabel: 'orders');
final _inventoryNavKey = GlobalKey<NavigatorState>(debugLabel: 'inventory');
final _shopNavKey = GlobalKey<NavigatorState>(debugLabel: 'shop');

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey = _rootNavigatorKey;

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: _globalRedirect,
    routes: [
      // ---- Routes outside shell (no bottom nav) ----
      GoRoute(
        path: '/',
        name: 'splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/register-vendor',
        name: 'register-vendor',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterVendorScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        name: 'pending-approval',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // ---- StatefulShellRoute with 4 branches ----
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return ScaffoldWithBottomNav(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            navigatorKey: _dashboardNavKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Orders
          StatefulShellBranch(
            navigatorKey: _ordersNavKey,
            routes: [
              GoRoute(
                path: '/orders',
                name: 'orders',
                builder: (context, state) => const _PlaceholderScreen(
                  title: 'Orders',
                  icon: Icons.receipt_long_rounded,
                ),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'order-detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return _PlaceholderScreen(
                        title: 'Order #$id',
                        icon: Icons.receipt_rounded,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Inventory
          StatefulShellBranch(
            navigatorKey: _inventoryNavKey,
            routes: [
              GoRoute(
                path: '/inventory',
                name: 'inventory',
                builder: (context, state) => const InventoryScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'inventory-add',
                    builder: (context, state) => const AddEditProductScreen(),
                  ),
                  GoRoute(
                    path: 'low-stock',
                    name: 'inventory-low-stock',
                    builder: (context, state) => const LowStockScreen(),
                  ),
                  GoRoute(
                    path: 'bulk-update',
                    name: 'inventory-bulk-update',
                    builder: (context, state) => const BulkUpdateScreen(),
                  ),
                  GoRoute(
                    path: ':productId/edit',
                    name: 'inventory-edit',
                    builder: (context, state) {
                      final productId = state.pathParameters['productId'] ?? '';
                      return AddEditProductScreen(productId: productId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Shop
          StatefulShellBranch(
            navigatorKey: _shopNavKey,
            routes: [
              GoRoute(
                path: '/shop',
                name: 'shop',
                builder: (context, state) => const ShopProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: 'shop-edit',
                    builder: (context, state) => const EditShopScreen(),
                  ),
                  GoRoute(
                    path: 'working-hours',
                    name: 'shop-working-hours',
                    builder: (context, state) => const WorkingHoursScreen(),
                  ),
                  GoRoute(
                    path: 'bank-details',
                    name: 'shop-bank-details',
                    builder: (context, state) => const BankDetailsScreen(),
                  ),
                  GoRoute(
                    path: 'upload-docs',
                    name: 'shop-upload-docs',
                    builder: (context, state) => const UploadDocsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ---- Earnings routes (full-screen, outside shell) ----
      GoRoute(
        path: '/earnings',
        name: 'earnings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: '/earnings/payouts',
        name: 'payout-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PayoutHistoryScreen(),
      ),
      GoRoute(
        path: '/earnings/payouts/:payoutId',
        name: 'transaction-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final payoutId = state.pathParameters['payoutId'] ?? '';
          final extra = state.extra as PayoutModel?;
          return TransactionDetailScreen(
            payoutId: payoutId,
            payoutExtra: extra,
          );
        },
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// Redirect logic
// ---------------------------------------------------------------------------

String? _globalRedirect(BuildContext context, GoRouterState state) {
  final storage = LocalStorage.instance;
  final isLoggedIn = storage.isLoggedIn;
  final currentPath = state.matchedLocation;

  // Splash always allowed
  if (currentPath == '/') return null;

  // Auth routes -- allow if not logged in
  const authRoutes = [
    '/login',
    '/otp',
    '/register-vendor',
    '/pending-approval',
  ];
  final isAuthRoute = authRoutes.contains(currentPath);

  if (!isLoggedIn && !isAuthRoute) {
    return '/login';
  }

  // If logged in and trying to go to login, redirect to dashboard
  if (isLoggedIn && currentPath == '/login') {
    final vendorId = storage.getVendorId();
    if (vendorId == null) return '/register-vendor';
    return '/dashboard';
  }

  return null;
}

// ---------------------------------------------------------------------------
// Scaffold with Bottom Nav wrapper
// ---------------------------------------------------------------------------

class ScaffoldWithBottomNav extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithBottomNav({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: VendorBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder screen for routes not yet implemented
// ---------------------------------------------------------------------------

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: VendorColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: VendorColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon',
              style: TextStyle(fontSize: 14, color: VendorColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider for the router
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) => AppRouter.router);
