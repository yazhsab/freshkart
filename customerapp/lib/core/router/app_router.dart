import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/router/route_names.dart';
import 'package:freshkart_customer/core/storage/local_storage.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/auth/screens/otp_screen.dart';
import 'package:freshkart_customer/features/auth/screens/phone_screen.dart';
import 'package:freshkart_customer/features/grocery/screens/product_detail_screen.dart';
import 'package:freshkart_customer/features/grocery/screens/vendor_detail_screen.dart';
import 'package:freshkart_customer/features/home/screens/home_screen.dart';
import 'package:freshkart_customer/features/home/screens/search_screen.dart';
import 'package:freshkart_customer/features/onboarding/onboarding_screen.dart';
import 'package:freshkart_customer/features/orders/screens/order_detail_screen.dart';
import 'package:freshkart_customer/features/orders/screens/order_tracking_screen.dart';
import 'package:freshkart_customer/features/orders/screens/orders_screen.dart';
import 'package:freshkart_customer/features/orders/screens/rate_order_screen.dart';
import 'package:freshkart_customer/features/profile/screens/addresses_screen.dart';
import 'package:freshkart_customer/features/profile/screens/edit_profile_screen.dart';
import 'package:freshkart_customer/features/profile/screens/help_screen.dart';
import 'package:freshkart_customer/features/profile/screens/notifications_screen.dart';
import 'package:freshkart_customer/features/profile/screens/profile_screen.dart';
import 'package:freshkart_customer/features/services/screens/book_service_screen.dart';
import 'package:freshkart_customer/features/services/screens/service_category_screen.dart';
import 'package:freshkart_customer/features/services/screens/services_home_screen.dart';
import 'package:freshkart_customer/features/shared/widgets/app_bottom_nav.dart';
import 'package:freshkart_customer/features/splash/splash_screen.dart';
import 'package:freshkart_customer/features/wallet/screens/wallet_screen.dart';
import 'package:freshkart_customer/features/loyalty/screens/loyalty_screen.dart';
import 'package:freshkart_customer/features/referral/screens/referral_screen.dart';
import 'package:freshkart_customer/features/chat/screens/chat_rooms_screen.dart';

// ---------------------------------------------------------------------------
// Navigator keys (one per branch to preserve state)
// ---------------------------------------------------------------------------
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _ordersNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'orders');
final _servicesNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'services');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

// ---------------------------------------------------------------------------
// Auth routes (no bottom nav)
// ---------------------------------------------------------------------------
const _authRoutes = ['/splash', '/onboarding', '/login', '/otp'];

bool _isAuthRoute(String location) {
  return _authRoutes.any((r) => location.startsWith(r));
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = LocalStorage.isLoggedIn();
      final location = state.matchedLocation;
      final onAuthRoute = _isAuthRoute(location);

      // Not logged in and not on an auth route -> go to login
      if (!isLoggedIn && !onAuthRoute) {
        return '/login';
      }

      // Logged in but on an auth route (except splash) -> go home
      if (isLoggedIn && onAuthRoute && location != '/splash') {
        return '/home';
      }

      return null;
    },
    routes: [
      // ── Routes outside the shell (no bottom nav) ──
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: PhoneScreen()),
      ),
      GoRoute(
        path: '/otp',
        name: RouteNames.otp,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phone: phone);
        },
      ),

      // ── Main app shell with bottom navigation ──
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return _ScaffoldWithBottomNav(navigationShell: navigationShell);
        },
        branches: [
          // ── Branch 0: Home ──
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomeScreen()),
                routes: [
                  GoRoute(
                    path: 'search',
                    name: RouteNames.search,
                    builder: (context, state) => const SearchScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/vendor/:vendorId',
                name: RouteNames.vendorDetail,
                builder: (context, state) {
                  final vendorId = state.pathParameters['vendorId']!;
                  return VendorDetailScreen(vendorId: vendorId);
                },
              ),
              GoRoute(
                path: '/product/:productId',
                name: RouteNames.productDetail,
                builder: (context, state) {
                  final productId = state.pathParameters['productId']!;
                  return ProductDetailScreen(productId: productId);
                },
              ),
              GoRoute(
                path: '/cart',
                name: RouteNames.cart,
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Cart'),
              ),
              GoRoute(
                path: '/checkout',
                name: RouteNames.checkout,
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'Checkout'),
              ),
            ],
          ),

          // ── Branch 1: Orders ──
          StatefulShellBranch(
            navigatorKey: _ordersNavigatorKey,
            routes: [
              GoRoute(
                path: '/orders',
                name: RouteNames.orders,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: OrdersScreen()),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: RouteNames.orderDetail,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return OrderDetailScreen(orderId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'track',
                        name: RouteNames.orderTracking,
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return OrderTrackingScreen(orderId: id);
                        },
                      ),
                      GoRoute(
                        path: 'rate',
                        name: RouteNames.rateOrder,
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return RateOrderScreen(orderId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 2: Services ──
          StatefulShellBranch(
            navigatorKey: _servicesNavigatorKey,
            routes: [
              GoRoute(
                path: '/services',
                name: RouteNames.services,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ServicesHomeScreen()),
                routes: [
                  GoRoute(
                    path: ':categoryId',
                    name: RouteNames.serviceCategory,
                    builder: (context, state) {
                      final categoryId = state.pathParameters['categoryId']!;
                      return ServiceCategoryScreen(categoryId: categoryId);
                    },
                    routes: [
                      GoRoute(
                        path: 'book',
                        name: RouteNames.bookService,
                        builder: (context, state) {
                          final categoryId =
                              state.pathParameters['categoryId']!;
                          return BookServiceScreen(categoryId: categoryId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/bookings',
                name: RouteNames.bookings,
                builder: (context, state) =>
                    const _PlaceholderPage(title: 'My Bookings'),
                routes: [
                  GoRoute(
                    path: 'confirmation',
                    name: RouteNames.bookingConfirmation,
                    builder: (context, state) =>
                        const _PlaceholderPage(title: 'Booking Confirmed'),
                  ),
                  GoRoute(
                    path: ':id',
                    name: RouteNames.bookingDetail,
                    builder: (context, state) =>
                        const _PlaceholderPage(title: 'Booking Detail'),
                    routes: [
                      GoRoute(
                        path: 'rate',
                        name: RouteNames.rateBooking,
                        builder: (context, state) =>
                            const _PlaceholderPage(title: 'Rate Booking'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ── Branch 3: Profile ──
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: RouteNames.profile,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfileScreen()),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.editProfile,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'addresses',
                    name: RouteNames.profileAddresses,
                    builder: (context, state) => const AddressesScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        name: RouteNames.addAddress,
                        builder: (context, state) =>
                            const _PlaceholderPage(title: 'Add Address'),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: RouteNames.notifications,
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'wallet',
                    name: RouteNames.wallet,
                    builder: (context, state) => const WalletScreen(),
                  ),
                  GoRoute(
                    path: 'loyalty',
                    name: RouteNames.loyalty,
                    builder: (context, state) => const LoyaltyScreen(),
                  ),
                  GoRoute(
                    path: 'referral',
                    name: RouteNames.referral,
                    builder: (context, state) => const ReferralScreen(),
                  ),
                ],
              ),
              GoRoute(
                path: '/help',
                builder: (context, state) => const HelpScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Scaffold with bottom navigation (StatefulShellRoute wrapper)
// ---------------------------------------------------------------------------
class _ScaffoldWithBottomNav extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithBottomNav({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder for screens not yet built
// ---------------------------------------------------------------------------
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This screen is under construction',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
