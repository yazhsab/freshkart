import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';

/// Panel showing actionable alerts grouped by category.
/// Sections: Failed Payments, Pending Vendor Approvals, Unassigned Bookings, Low Stock.
/// When all counts are zero, shows a checkmark with "All clear!" message.
class AlertsPanel extends StatelessWidget {
  const AlertsPanel({
    super.key,
    required this.failedPayments,
    required this.pendingVendorApprovals,
    required this.unassignedBookings,
    required this.lowStockProducts,
    this.onFailedPaymentsTap,
    this.onPendingVendorsTap,
    this.onUnassignedBookingsTap,
    this.onLowStockTap,
  });

  final int failedPayments;
  final int pendingVendorApprovals;
  final int unassignedBookings;
  final int lowStockProducts;
  final VoidCallback? onFailedPaymentsTap;
  final VoidCallback? onPendingVendorsTap;
  final VoidCallback? onUnassignedBookingsTap;
  final VoidCallback? onLowStockTap;

  bool get _hasAlerts =>
      failedPayments > 0 ||
      pendingVendorApprovals > 0 ||
      unassignedBookings > 0 ||
      lowStockProducts > 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Alerts & Actions Required',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Content
          if (!_hasAlerts)
            _buildEmptyState()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (failedPayments > 0)
                  _AlertSection(
                    icon: Icons.error_outline_rounded,
                    accentColor: AppColors.error,
                    title: 'Failed Payments',
                    count: failedPayments,
                    description:
                        '$failedPayments payment${failedPayments == 1 ? '' : 's'} failed and need attention',
                    actionLabel: 'View',
                    onTap: onFailedPaymentsTap,
                  ),
                if (pendingVendorApprovals > 0)
                  _AlertSection(
                    icon: Icons.store_rounded,
                    accentColor: AppColors.secondary,
                    title: 'Pending Vendor Approvals',
                    count: pendingVendorApprovals,
                    description:
                        '$pendingVendorApprovals vendor${pendingVendorApprovals == 1 ? '' : 's'} awaiting approval',
                    actionLabel: 'Review',
                    onTap: onPendingVendorsTap,
                  ),
                if (unassignedBookings > 0)
                  _AlertSection(
                    icon: Icons.calendar_month_rounded,
                    accentColor: AppColors.secondary,
                    title: 'Unassigned Bookings',
                    count: unassignedBookings,
                    description:
                        '$unassignedBookings booking${unassignedBookings == 1 ? '' : 's'} need worker assignment',
                    actionLabel: 'Assign',
                    onTap: onUnassignedBookingsTap,
                  ),
                if (lowStockProducts > 0)
                  _AlertSection(
                    icon: Icons.inventory_2_outlined,
                    accentColor: const Color(0xFFFDD835),
                    title: 'Low Stock Products',
                    count: lowStockProducts,
                    description:
                        '$lowStockProducts product${lowStockProducts == 1 ? '' : 's'} with stock at or below 5 units',
                    actionLabel: 'View',
                    onTap: onLowStockTap,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 36,
              color: AppColors.primary,
            ),
            SizedBox(height: 8),
            Text(
              'All clear!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'No alerts or pending actions',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertSection extends StatelessWidget {
  const _AlertSection({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.count,
    required this.description,
    this.actionLabel,
    this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final int count;
  final String description;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored dot
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Action button
            if (actionLabel != null && onTap != null)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.sidebar,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
