import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/router/route_names.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';
import 'package:freshkart_worker/shared/widgets/worker_bottom_nav.dart';
import 'package:freshkart_worker/features/auth/screens/phone_screen.dart';
import 'package:freshkart_worker/features/auth/screens/otp_screen.dart';
import 'package:freshkart_worker/features/auth/screens/register_worker_screen.dart';
import 'package:freshkart_worker/features/auth/screens/pending_approval_screen.dart';
import 'package:freshkart_worker/features/home/screens/home_screen.dart';
import 'package:freshkart_worker/features/bookings/screens/bookings_screen.dart';
import 'package:freshkart_worker/features/bookings/screens/booking_detail_screen.dart';
import 'package:freshkart_worker/features/job/screens/checkin_screen.dart';
import 'package:freshkart_worker/features/job/screens/job_in_progress_screen.dart';
import 'package:freshkart_worker/features/job/screens/job_report_screen.dart';
import 'package:freshkart_worker/features/job/screens/job_complete_screen.dart';
import 'package:freshkart_worker/features/schedule/screens/schedule_screen.dart';
import 'package:freshkart_worker/features/schedule/screens/add_slot_screen.dart';
import 'package:freshkart_worker/features/earnings/screens/earnings_screen.dart';
import 'package:freshkart_worker/features/earnings/screens/payout_history_screen.dart';
import 'package:freshkart_worker/features/profile/screens/profile_screen.dart';
import 'package:freshkart_worker/features/profile/screens/edit_profile_screen.dart';
import 'package:freshkart_worker/features/profile/screens/skills_screen.dart';
import 'package:freshkart_worker/features/profile/screens/documents_screen.dart';
import 'package:freshkart_worker/features/profile/screens/bank_details_screen.dart';
import 'package:freshkart_worker/features/profile/screens/reviews_screen.dart';
import 'package:freshkart_worker/features/profile/screens/support_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final workerId = LocalStorage.workerId;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/pending-approval';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn &&
          workerId == null &&
          state.matchedLocation != '/register') return '/register';
      if (isLoggedIn && state.matchedLocation == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: RouteNames.otp,
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) => const RegisterWorkerScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        name: RouteNames.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => WorkerBottomNav(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/bookings',
            name: RouteNames.bookings,
            builder: (context, state) => const BookingsScreen(),
          ),
          GoRoute(
            path: '/schedule',
            name: RouteNames.schedule,
            builder: (context, state) => const ScheduleScreen(),
          ),
          GoRoute(
            path: '/earnings',
            name: RouteNames.earnings,
            builder: (context, state) => const EarningsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/booking/:id',
        name: RouteNames.bookingDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BookingDetailScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/checkin/:id',
        name: RouteNames.checkin,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CheckinScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/job-in-progress/:id',
        name: RouteNames.jobInProgress,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobInProgressScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/job-report/:id',
        name: RouteNames.jobReport,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobReportScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/job-complete/:id',
        name: RouteNames.jobComplete,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobCompleteScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/add-slot',
        name: RouteNames.addSlot,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddSlotScreen(),
      ),
      GoRoute(
        path: '/payout-history',
        name: RouteNames.payoutHistory,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PayoutHistoryScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: RouteNames.editProfile,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/skills',
        name: RouteNames.skills,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SkillsScreen(),
      ),
      GoRoute(
        path: '/documents',
        name: RouteNames.documents,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DocumentsScreen(),
      ),
      GoRoute(
        path: '/bank-details',
        name: RouteNames.bankDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BankDetailsScreen(),
      ),
      GoRoute(
        path: '/reviews',
        name: RouteNames.reviews,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReviewsScreen(),
      ),
      GoRoute(
        path: '/support',
        name: RouteNames.support,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
    ],
  );
});
