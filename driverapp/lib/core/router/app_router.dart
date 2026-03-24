import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_delivery/core/router/route_names.dart';
import 'package:freshkart_delivery/features/splash/splash_screen.dart';
import 'package:freshkart_delivery/features/auth/screens/phone_screen.dart';
import 'package:freshkart_delivery/features/auth/screens/otp_screen.dart';
import 'package:freshkart_delivery/features/auth/screens/register_agent_screen.dart';
import 'package:freshkart_delivery/features/auth/screens/pending_approval_screen.dart';
import 'package:freshkart_delivery/features/home/screens/home_screen.dart';
import 'package:freshkart_delivery/features/delivery/screens/delivery_detail_screen.dart';
import 'package:freshkart_delivery/features/delivery/screens/pickup_otp_screen.dart';
import 'package:freshkart_delivery/features/delivery/screens/delivery_otp_screen.dart';
import 'package:freshkart_delivery/features/delivery/screens/delivery_complete_screen.dart';
import 'package:freshkart_delivery/features/history/screens/history_screen.dart';
import 'package:freshkart_delivery/features/history/screens/delivery_history_detail_screen.dart';
import 'package:freshkart_delivery/features/earnings/screens/earnings_screen.dart';
import 'package:freshkart_delivery/features/earnings/screens/payout_history_screen.dart';
import 'package:freshkart_delivery/features/profile/screens/profile_screen.dart';
import 'package:freshkart_delivery/features/profile/screens/edit_profile_screen.dart';
import 'package:freshkart_delivery/features/profile/screens/vehicle_details_screen.dart';
import 'package:freshkart_delivery/features/profile/screens/documents_screen.dart';
import 'package:freshkart_delivery/features/profile/screens/support_screen.dart';
import 'package:freshkart_delivery/features/shared/widgets/agent_bottom_nav.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorHistoryKey = GlobalKey<NavigatorState>(
  debugLabel: 'history',
);
final _shellNavigatorEarningsKey = GlobalKey<NavigatorState>(
  debugLabel: 'earnings',
);

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      // --- Auth & onboarding (full-screen) ---
      GoRoute(
        path: '/splash',
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: RouteNames.otp,
        builder: (context, state) {
          final phone = state.extra as String;
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterAgentScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        name: RouteNames.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),

      // --- Bottom nav shell ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AgentBottomNav(
            navigationShell: navigationShell,
            currentIndex: navigationShell.currentIndex,
          );
        },
        branches: [
          // Branch 0 – Home
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Branch 1 – History
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHistoryKey,
            routes: [
              GoRoute(
                path: '/history',
                name: RouteNames.history,
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    name: RouteNames.historyDetail,
                    builder: (context, state) {
                      final orderId = state.pathParameters['orderId']!;
                      return DeliveryHistoryDetailScreen(orderId: orderId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2 – Earnings
          StatefulShellBranch(
            navigatorKey: _shellNavigatorEarningsKey,
            routes: [
              GoRoute(
                path: '/earnings',
                name: RouteNames.earnings,
                builder: (context, state) => const EarningsScreen(),
                routes: [
                  GoRoute(
                    path: 'payouts',
                    name: RouteNames.payouts,
                    builder: (context, state) => const PayoutHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // --- Delivery flow (full-screen, NOT in shell) ---
      GoRoute(
        path: '/delivery/:orderId',
        name: RouteNames.delivery,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return DeliveryDetailScreen(orderId: orderId);
        },
        routes: [
          GoRoute(
            path: 'pickup-otp',
            name: RouteNames.pickupOtp,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return PickupOtpScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: 'delivery-otp',
            name: RouteNames.deliveryOtp,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return DeliveryOtpScreen(orderId: orderId);
            },
          ),
          GoRoute(
            path: 'complete',
            name: RouteNames.deliveryComplete,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return DeliveryCompleteScreen(orderId: orderId);
            },
          ),
        ],
      ),

      // --- Profile (full-screen, pushed on top) ---
      GoRoute(
        path: '/profile',
        name: RouteNames.profile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: RouteNames.editProfile,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const EditProfileScreen(),
          ),
          GoRoute(
            path: 'vehicle',
            name: RouteNames.vehicleDetails,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const VehicleDetailsScreen(),
          ),
          GoRoute(
            path: 'documents',
            name: RouteNames.documents,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const DocumentsScreen(),
          ),
          GoRoute(
            path: 'support',
            name: RouteNames.support,
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const SupportScreen(),
          ),
        ],
      ),
    ],
  );
}
