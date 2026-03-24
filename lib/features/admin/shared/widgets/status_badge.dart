import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.type = 'general',
  });

  final String status;
  final String type;

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _formatLabel(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatLabel() {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  Color _getColor() {
    switch (type) {
      case 'order':
        return _orderColor();
      case 'booking':
        return _bookingColor();
      case 'bgv':
        return _bgvColor();
      case 'payment':
        return _paymentColor();
      default:
        return _generalColor();
    }
  }

  Color _orderColor() {
    switch (status) {
      case 'pending':
        return AppColors.statusPending;
      case 'confirmed':
        return AppColors.statusConfirmed;
      case 'packing':
        return AppColors.statusPacking;
      case 'ready':
        return AppColors.statusReady;
      case 'picked_up':
        return AppColors.statusPickedUp;
      case 'delivered':
        return AppColors.statusDelivered;
      case 'cancelled':
        return AppColors.statusCancelled;
      case 'refunded':
        return AppColors.statusRefunded;
      default:
        return AppColors.statusPending;
    }
  }

  Color _bookingColor() {
    switch (status) {
      case 'pending':
        return AppColors.statusPending;
      case 'assigned':
        return AppColors.statusAssigned;
      case 'confirmed':
        return const Color(0xFF673AB7);
      case 'worker_on_way':
        return AppColors.statusWorkerOnWay;
      case 'in_progress':
        return AppColors.statusInProgress;
      case 'completed':
        return AppColors.statusCompleted;
      case 'cancelled':
        return AppColors.statusCancelled;
      case 'disputed':
        return AppColors.statusDisputed;
      default:
        return AppColors.statusPending;
    }
  }

  Color _bgvColor() {
    switch (status) {
      case 'pending':
        return AppColors.bgvPending;
      case 'in_progress':
        return AppColors.bgvInProgress;
      case 'approved':
        return AppColors.bgvApproved;
      case 'rejected':
        return AppColors.bgvRejected;
      default:
        return AppColors.bgvPending;
    }
  }

  Color _paymentColor() {
    switch (status) {
      case 'pending':
        return AppColors.paymentPending;
      case 'paid' || 'success':
        return AppColors.paymentPaid;
      case 'failed':
        return AppColors.paymentFailed;
      case 'refunded':
        return AppColors.paymentRefundedColor;
      case 'partial':
        return AppColors.paymentPending;
      default:
        return AppColors.paymentPending;
    }
  }

  Color _generalColor() {
    switch (status) {
      case 'active':
        return AppColors.statusCompleted;
      case 'inactive' || 'suspended':
        return AppColors.statusCancelled;
      case 'pending':
        return AppColors.statusPending;
      case 'processing':
        return AppColors.statusConfirmed;
      default:
        return AppColors.statusPending;
    }
  }
}
