import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/routes.dart';
import '../providers/admin_nav_provider.dart';
import 'admin_sidebar.dart';
import 'admin_topbar.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigate(String route) {
    ref.read(adminNavProvider.notifier).go(route);
    context.go(route);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(adminNavProvider) != location) {
        final matched = pageTitles.containsKey(location);
        ref
            .read(adminNavProvider.notifier)
            .go(matched ? location : kAdminDashboard);
      }
    });

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F7F2), Color(0xFFEDF5EF), Color(0xFFF7F8F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 640;
          final collapsed = width >= 640 && width < 1180;

          if (isMobile) {
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.transparent,
              drawer: SizedBox(
                width: 292,
                child: AdminSidebar(onNavigate: _navigate),
              ),
              body: Column(
                children: [
                  AdminTopbar(
                    showMenuButton: true,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  Expanded(
                    child: _ContentArea(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            );
          }

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: [
                AdminSidebar(collapsed: collapsed, onNavigate: _navigate),
                Expanded(
                  child: Column(
                    children: [
                      const AdminTopbar(showMenuButton: false),
                      Expanded(
                        child: _ContentArea(
                          padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ContentArea extends StatelessWidget {
  const _ContentArea({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: AppColors.spotlight.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -110,
              left: -30,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.spotlightAmber.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.62),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
