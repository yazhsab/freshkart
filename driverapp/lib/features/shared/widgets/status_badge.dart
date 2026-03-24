import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StatusType { pending, active, pickup, delivering, delivered, cancelled }

class StatusBadge extends StatelessWidget {
  final String status;
  final StatusType? type;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  const StatusBadge({
    super.key,
    required this.status,
    this.type,
    this.fontSize,
    this.padding,
  });

  StatusType get _resolvedType {
    if (type != null) return type!;
    switch (status.toLowerCase()) {
      case 'pending':
      case 'assigned':
        return StatusType.pending;
      case 'active':
      case 'accepted':
        return StatusType.active;
      case 'pickup':
      case 'picked_up':
      case 'picking_up':
        return StatusType.pickup;
      case 'delivering':
      case 'in_transit':
      case 'on_the_way':
        return StatusType.delivering;
      case 'delivered':
      case 'completed':
      case 'done':
        return StatusType.delivered;
      case 'cancelled':
      case 'canceled':
      case 'failed':
        return StatusType.cancelled;
      default:
        return StatusType.pending;
    }
  }

  Color get _backgroundColor {
    switch (_resolvedType) {
      case StatusType.pending:
        return const Color(0xFF9E9E9E);
      case StatusType.active:
        return const Color(0xFF00695C);
      case StatusType.pickup:
        return const Color(0xFFFF8F00);
      case StatusType.delivering:
        return const Color(0xFF1976D2);
      case StatusType.delivered:
        return const Color(0xFF43A047);
      case StatusType.cancelled:
        return const Color(0xFFE53935);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: GoogleFonts.notoSans(
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
          color: _backgroundColor,
        ),
      ),
    );
  }
}
