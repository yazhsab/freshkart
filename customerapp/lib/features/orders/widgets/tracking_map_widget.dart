import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';

/// A styled map‐placeholder widget that visualises the rider and
/// destination without requiring a real map SDK.
class TrackingMapWidget extends StatelessWidget {
  final double? agentLat;
  final double? agentLng;
  final double destLat;
  final double destLng;
  final String destAddress;

  const TrackingMapWidget({
    super.key,
    this.agentLat,
    this.agentLng,
    required this.destLat,
    required this.destLng,
    required this.destAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3EFF9), Color(0xFFCBDFF0)],
        ),
      ),
      child: Stack(
        children: [
          // Decorative grid lines
          ..._gridLines(),

          // Dashed route line (simple diagonal)
          CustomPaint(
            size: Size.infinite,
            painter: _RoutePainter(hasAgent: agentLat != null),
          ),

          // Rider icon
          Positioned(
            top: agentLat != null ? 80 : 120,
            left: agentLng != null ? 80 : 120,
            child: _RiderMarker(),
          ),

          // Destination pin
          Positioned(
            bottom: 60,
            right: 50,
            child: _DestinationPin(address: destAddress),
          ),

          // "Live tracking" badge
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Live tracking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns faint horizontal & vertical lines that mimic a map grid.
  List<Widget> _gridLines() {
    return [
      // Horizontal lines
      for (var i = 0; i < 6; i++)
        Positioned(
          top: i * 60.0,
          left: 0,
          right: 0,
          child: Container(height: 0.5, color: Colors.white.withOpacity(0.5)),
        ),
      // Vertical lines
      for (var i = 0; i < 8; i++)
        Positioned(
          left: i * 60.0,
          top: 0,
          bottom: 0,
          child: Container(width: 0.5, color: Colors.white.withOpacity(0.5)),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Rider marker
// ---------------------------------------------------------------------------

class _RiderMarker extends StatefulWidget {
  @override
  State<_RiderMarker> createState() => _RiderMarkerState();
}

class _RiderMarkerState extends State<_RiderMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final radius = 18.0 + _ctrl.value * 10;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withOpacity(
                  0.15 * (1 - _ctrl.value),
                ),
              ),
            ),
            // Rider icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.delivery_dining,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Destination pin
// ---------------------------------------------------------------------------

class _DestinationPin extends StatelessWidget {
  final String address;
  const _DestinationPin({required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Address chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home, size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Pin stem
        Container(width: 2, height: 8, color: AppColors.error.withOpacity(0.5)),
        // Pin dot
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.error,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: AppColors.error.withOpacity(0.3), blurRadius: 4),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Route painter – draws a dashed diagonal line between rider & destination
// ---------------------------------------------------------------------------

class _RoutePainter extends CustomPainter {
  final bool hasAgent;
  _RoutePainter({required this.hasAgent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final start = Offset(hasAgent ? 100 : 140, hasAgent ? 100 : 140);
    final end = Offset(size.width - 56, size.height - 80);

    // Draw dashed line
    const dashLength = 8.0;
    const gapLength = 6.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final ux = dx / distance;
    final uy = dy / distance;

    var drawn = 0.0;
    var drawing = true;
    final path = Path();

    while (drawn < distance) {
      final segLen = drawing ? dashLength : gapLength;
      final remaining = distance - drawn;
      final len = segLen > remaining ? remaining : segLen;

      final sx = start.dx + ux * drawn;
      final sy = start.dy + uy * drawn;
      final ex = start.dx + ux * (drawn + len);
      final ey = start.dy + uy * (drawn + len);

      if (drawing) {
        path.moveTo(sx, sy);
        path.lineTo(ex, ey);
      }

      drawn += len;
      drawing = !drawing;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter old) => old.hasAgent != hasAgent;
}
