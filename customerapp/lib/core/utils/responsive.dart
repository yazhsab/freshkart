import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  static int gridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 800;
    return double.infinity;
  }

  static EdgeInsets contentPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 64, vertical: 16);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    return const EdgeInsets.all(16);
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) return desktop!;
    if (Responsive.isTablet(context) && tablet != null) return tablet!;
    return mobile;
  }
}

class ResponsiveCenter extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
