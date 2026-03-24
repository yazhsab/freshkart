import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/order.dart';
import '../../../core/models/order_item.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../shared/widgets/status_badge.dart';
import '../shared/widgets/confirm_dialog.dart';
import 'orders_provider.dart';

class OrderDetailPanel extends ConsumerStatefulWidget {
  const OrderDetailPanel({super.key, required this.order});
  final Order order;

  @override
  ConsumerState<OrderDetailPanel> createState() => _OrderDetailPanelState();
}

class _OrderDetailPanelState extends ConsumerState<OrderDetailPanel> {
  bool _showOtp = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: order# + status + time ──────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${o.orderNumber ?? o.id.substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (o.createdAt != null)
                      Text(
                        formatDateTime(o.createdAt!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              StatusBadge(status: o.status, type: 'order'),
            ],
          ),
          const SizedBox(height: 20),

          // ── Customer info ───────────────────────────────────────
          _SectionLabel('Customer'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: o.customer?.avatarUrl != null
                      ? NetworkImage(o.customer!.avatarUrl!)
                      : null,
                  child: o.customer?.avatarUrl == null
                      ? Text(
                          o.customer?.initials ?? '?',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.customer?.displayName ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            o.customer?.phone ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (o.customer?.email != null) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.email_outlined,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                o.customer!.email!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, color: AppColors.border),

          // ── Order items ─────────────────────────────────────────
          _SectionLabel('Order Items (${o.items.length})'),
          ...o.items.map((item) => _buildItemRow(item)),
          const Divider(height: 24, color: AppColors.border),

          // ── Price breakdown ─────────────────────────────────────
          _SectionLabel('Price Breakdown'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _PriceRow(label: 'Subtotal', value: formatINR(o.totalAmount)),
                _PriceRow(
                    label: 'Delivery Fee', value: formatINR(o.deliveryFee)),
                if (o.discountAmount > 0)
                  _PriceRow(
                    label: 'Discount',
                    value: '-${formatINR(o.discountAmount)}',
                    valueColor: AppColors.statusDelivered,
                  ),
                const Divider(height: 16, color: AppColors.border),
                _PriceRow(
                  label: 'Total',
                  value: formatINR(o.finalAmount),
                  isBold: true,
                ),
              ],
            ),
          ),
          const Divider(height: 24, color: AppColors.border),

          // ── Timeline stepper ────────────────────────────────────
          _SectionLabel('Timeline'),
          _buildTimeline(o),
          const Divider(height: 24, color: AppColors.border),

          // ── Delivery info ───────────────────────────────────────
          _SectionLabel('Delivery Info'),
          _buildDeliveryInfo(o),
          const Divider(height: 24, color: AppColors.border),

          // ── Payment info ────────────────────────────────────────
          _SectionLabel('Payment'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Payment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    StatusBadge(status: o.paymentStatus, type: 'payment'),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                    'Method', (o.paymentMethod ?? '-').toUpperCase()),
                _InfoRow('Status', o.paymentStatus.toUpperCase()),
                if (o.razorpayPaymentId != null)
                  _InfoRow('Transaction ID', o.razorpayPaymentId!),
                if (o.razorpayOrderId != null)
                  _InfoRow('Razorpay Order', o.razorpayOrderId!),
              ],
            ),
          ),
          const Divider(height: 24, color: AppColors.border),

          // ── Special instructions ────────────────────────────────
          if (o.specialInstructions != null &&
              o.specialInstructions!.isNotEmpty) ...[
            _SectionLabel('Special Instructions'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                o.specialInstructions!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 24, color: AppColors.border),
          ],

          // ── Cancellation info ───────────────────────────────────
          if (o.status == 'cancelled' || o.cancelReason != null) ...[
            _SectionLabel('Cancellation'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (o.cancelledBy != null)
                    _InfoRow('Cancelled By', o.cancelledBy!),
                  if (o.cancelReason != null)
                    _InfoRow('Reason', o.cancelReason!),
                ],
              ),
            ),
            const Divider(height: 24, color: AppColors.border),
          ],

          // ── Admin actions ───────────────────────────────────────
          _SectionLabel('Admin Actions'),
          const SizedBox(height: 8),
          _buildAdminActions(o),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Order item row ───────────────────────────────────────────────
  Widget _buildItemRow(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: item.productImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item.productImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.unit != null)
                  Text(
                    item.unit!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.quantity} x ${formatINR(item.unitPrice)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                formatINR(item.totalPrice),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Timeline stepper ─────────────────────────────────────────────
  Widget _buildTimeline(Order o) {
    final steps = <_TimelineStep>[
      _TimelineStep(
        label: 'Order Placed',
        time: o.createdAt,
        isCompleted: true,
      ),
      _TimelineStep(
        label: 'Vendor Confirmed',
        time: o.vendorConfirmedAt,
        isCompleted: o.vendorConfirmedAt != null,
      ),
      _TimelineStep(
        label: 'Packed',
        time: o.packedAt,
        isCompleted: o.packedAt != null,
      ),
      _TimelineStep(
        label: 'Picked Up',
        time: o.pickedUpAt,
        isCompleted: o.pickedUpAt != null,
      ),
      _TimelineStep(
        label: 'Delivered',
        time: o.deliveredAt,
        isCompleted: o.deliveredAt != null,
      ),
    ];

    if (o.status == 'cancelled') {
      steps.add(_TimelineStep(
        label: 'Cancelled',
        time: null,
        isCompleted: true,
        isError: true,
      ));
    }

    if (o.status == 'refunded') {
      steps.add(_TimelineStep(
        label: 'Refunded',
        time: null,
        isCompleted: true,
        isError: true,
      ));
    }

    return Column(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.isError
                          ? AppColors.error
                          : step.isCompleted
                              ? AppColors.statusDelivered
                              : AppColors.border,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 28,
                      color: step.isCompleted
                          ? AppColors.statusDelivered.withValues(alpha: 0.4)
                          : AppColors.border,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: step.isCompleted
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: step.isError
                              ? AppColors.error
                              : step.isCompleted
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (step.time != null)
                      Text(
                        formatDateTime(step.time!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Delivery info ────────────────────────────────────────────────
  Widget _buildDeliveryInfo(Order o) {
    final addr = o.deliveryAddress;
    String addressStr = '-';
    if (addr != null) {
      final parts = <String>[];
      if (addr['flat_no'] != null) parts.add(addr['flat_no'].toString());
      if (addr['line1'] != null) parts.add(addr['line1'].toString());
      if (addr['line2'] != null) parts.add(addr['line2'].toString());
      if (addr['area'] != null) parts.add(addr['area'].toString());
      if (addr['city'] != null) parts.add(addr['city'].toString());
      if (addr['pincode'] != null) parts.add(addr['pincode'].toString());
      if (parts.isNotEmpty) addressStr = parts.join(', ');
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('Address', addressStr),
          _InfoRow('Vendor', o.vendor?.shopName ?? '-'),
          if (o.agent != null)
            _InfoRow('Agent', o.agent!.displayName),
          if (o.deliveryOtp != null)
            Row(
              children: [
                const SizedBox(
                  width: 100,
                  child: Text(
                    'OTP',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  _showOtp ? o.deliveryOtp! : '****',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _showOtp ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _showOtp = !_showOtp),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Admin actions ────────────────────────────────────────────────
  Widget _buildAdminActions(Order o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Change status
        if (_availableStatusTransitions(o.status).isNotEmpty) ...[
          const Text(
            'Change Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableStatusTransitions(o.status)
                .map(
                  (status) => OutlinedButton(
                    onPressed: () => _changeStatusDialog(o, status),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _statusColor(status),
                      side: BorderSide(
                        color: _statusColor(status).withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      _statusDisplayName(status),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Assign agent
        const Text(
          'Assign Delivery Agent',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        _AssignAgentDropdown(orderId: o.id),
        const SizedBox(height: 16),

        // Refund button
        if (o.status == 'delivered' && o.paymentStatus != 'refunded')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => _refundDialog(o),
              icon: const Icon(Icons.replay_rounded,
                  size: 16, color: AppColors.statusRefunded),
              label: const Text(
                'Issue Refund',
                style: TextStyle(color: AppColors.statusRefunded),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.statusRefunded),
              ),
            ),
          ),

        // Cancel button
        if (o.status != 'cancelled' &&
            o.status != 'delivered' &&
            o.status != 'refunded')
          OutlinedButton.icon(
            onPressed: () => _cancelDialog(o),
            icon: const Icon(Icons.cancel_outlined,
                size: 16, color: AppColors.error),
            label: const Text(
              'Cancel Order',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  List<String> _availableStatusTransitions(String current) {
    switch (current) {
      case 'pending':
        return ['confirmed'];
      case 'confirmed':
        return ['packing'];
      case 'packing':
        return ['ready'];
      case 'ready':
        return ['picked_up'];
      case 'picked_up':
        return ['delivered'];
      default:
        return [];
    }
  }

  String _statusDisplayName(String status) {
    return status.replaceAll('_', ' ').split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');
  }

  Color _statusColor(String status) {
    switch (status) {
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
      default:
        return AppColors.statusPending;
    }
  }

  Future<void> _changeStatusDialog(Order o, String newStatus) async {
    final displayStatus = _statusDisplayName(newStatus);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Update Order Status',
      message:
          'Change order #${o.orderNumber ?? o.id.substring(0, 8)} to "$displayStatus"?',
      confirmLabel: displayStatus,
      confirmColor: _statusColor(newStatus),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(orderListProvider.notifier)
          .updateOrderStatus(o.id, newStatus);
    }
  }

  Future<void> _cancelDialog(Order o) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancel Order',
      message:
          'Cancel order #${o.orderNumber ?? o.id.substring(0, 8)}? This cannot be undone.',
      confirmLabel: 'Cancel Order',
      confirmColor: AppColors.error,
      extraContent: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(
          labelText: 'Cancellation reason',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(orderListProvider.notifier).updateOrderStatus(
            o.id,
            'cancelled',
            reason: reasonCtrl.text,
          );
    }
    reasonCtrl.dispose();
  }

  Future<void> _refundDialog(Order o) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Issue Refund',
      message:
          'Refund ${formatINR(o.finalAmount)} for order #${o.orderNumber ?? o.id.substring(0, 8)}?',
      confirmLabel: 'Refund',
      confirmColor: AppColors.statusRefunded,
    );
    if (confirmed == true && mounted) {
      await ref
          .read(orderListProvider.notifier)
          .updateOrderStatus(o.id, 'refunded');
    }
  }
}

// ── Assign Agent Dropdown ────────────────────────────────────────

class _AssignAgentDropdown extends ConsumerWidget {
  const _AssignAgentDropdown({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncAgents = ref.watch(availableAgentsProvider);

    return asyncAgents.when(
      loading: () => const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => const Text(
        'Failed to load agents',
        style: TextStyle(fontSize: 12, color: AppColors.error),
      ),
      data: (agents) {
        if (agents.isEmpty) {
          return const Text(
            'No delivery agents available',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          );
        }

        return DropdownButtonFormField<String>(
          items: agents
              .map((a) => DropdownMenuItem(
                    value: a['id'] as String,
                    child: Text(
                      '${a['full_name'] ?? "Unknown"} (${a['phone'] ?? ""})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ))
              .toList(),
          onChanged: (agentId) async {
            if (agentId != null) {
              final confirmed = await showConfirmDialog(
                context,
                title: 'Assign Agent',
                message: 'Assign this delivery agent to the order?',
                confirmLabel: 'Assign',
                confirmColor: AppColors.primary,
              );
              if (confirmed == true) {
                await ref
                    .read(orderListProvider.notifier)
                    .assignAgent(orderId, agentId);
              }
            }
          },
          decoration: InputDecoration(
            hintText: 'Select agent...',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          isExpanded: true,
        );
      },
    );
  }
}

// ── Small shared widgets ─────────────────────────────────────────

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    this.time,
    this.isCompleted = false,
    this.isError = false,
  });
  final String label;
  final DateTime? time;
  final bool isCompleted;
  final bool isError;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
