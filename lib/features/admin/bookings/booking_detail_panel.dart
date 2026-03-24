import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/booking.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../shared/widgets/status_badge.dart';
import 'bookings_provider.dart';

final _dateFmt = DateFormat('dd MMM yyyy');

class BookingDetailPanel extends ConsumerWidget {
  const BookingDetailPanel({super.key, required this.bookingId});
  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(bookingListProvider);
    final booking =
        st.bookings.where((b) => b.id == bookingId).firstOrNull;

    if (booking == null) {
      return const Center(
        child: Text(
          'Booking not found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return _PanelContent(booking: booking);
  }
}

class _PanelContent extends ConsumerWidget {
  const _PanelContent({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;

    return Column(
      children: [
        // Header
        _buildHeader(context, ref, b),
        const Divider(height: 1, color: AppColors.border),
        // Scrollable body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                _SectionLabel('Customer'),
                _InfoRow('Name', b.customer?.displayName ?? '-'),
                _InfoRow('Phone', b.customer?.phone ?? '-'),
                _InfoRow('Email', b.customer?.email ?? '-'),
                const Divider(height: 20, color: AppColors.border),

                // Service details
                _SectionLabel('Service Details'),
                _InfoRow('Service', b.serviceCategory?.name ?? '-'),
                _InfoRow(
                  'Duration',
                  b.serviceCategory?.durationLabel ?? '-',
                ),
                _InfoRow(
                  'Slot',
                  formatSlot(b.slotDate, b.slotStart, b.slotEnd),
                ),
                if (b.customerNotes != null && b.customerNotes!.isNotEmpty)
                  _InfoRow('Customer Notes', b.customerNotes!),
                const Divider(height: 20, color: AppColors.border),

                // Price
                _SectionLabel('Pricing'),
                _InfoRow(
                  'Quoted Price',
                  b.quotedPrice != null ? formatINR(b.quotedPrice!) : '-',
                ),
                _InfoRow(
                  'Final Price',
                  b.finalPrice != null ? formatINR(b.finalPrice!) : '-',
                ),
                _InfoRow('Booking Fee', formatINR(b.bookingFee)),
                if (b.platformCommission != null)
                  _InfoRow(
                    'Platform Commission',
                    formatINR(b.platformCommission!),
                  ),
                const Divider(height: 20, color: AppColors.border),

                // Worker Assignment
                _SectionLabel('Worker Assignment'),
                if (b.isUnassigned && b.status != 'cancelled') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'No worker assigned to this booking',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () =>
                              _showAssignWorkerDialog(context, ref, b),
                          icon: const Icon(Icons.person_add_rounded,
                              size: 16),
                          label: const Text('Assign',
                              style: TextStyle(fontSize: 12)),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (b.worker != null) ...[
                  _InfoRow('Worker', b.worker!.displayName),
                  _InfoRow('Phone', b.worker!.profile?.phone ?? '-'),
                  _InfoRow(
                    'Rating',
                    '${b.worker!.rating.toStringAsFixed(1)} (${b.worker!.totalRatings})',
                  ),
                ] else ...[
                  _InfoRow('Worker', '-'),
                ],
                const Divider(height: 20, color: AppColors.border),

                // Address
                _SectionLabel('Service Address'),
                if (b.serviceAddress != null) ...[
                  _InfoRow('Line 1', b.serviceAddress!['line1']?.toString() ?? '-'),
                  if (b.serviceAddress!['line2'] != null)
                    _InfoRow('Line 2', b.serviceAddress!['line2'].toString()),
                  _InfoRow('City', b.serviceAddress!['city']?.toString() ?? '-'),
                  _InfoRow(
                    'Pincode',
                    b.serviceAddress!['pincode']?.toString() ?? '-',
                  ),
                ] else ...[
                  const Text(
                    'No address provided',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Divider(height: 20, color: AppColors.border),

                // Payment
                _SectionLabel('Payment'),
                _InfoRow('Method', b.paymentMethod ?? '-'),
                Row(
                  children: [
                    const SizedBox(
                      width: 110,
                      child: Text('Status',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ),
                    StatusBadge(status: b.paymentStatus, type: 'payment'),
                  ],
                ),
                const SizedBox(height: 4),
                if (b.razorpayPaymentId != null)
                  _InfoRow('Razorpay ID', b.razorpayPaymentId!),
                const Divider(height: 20, color: AppColors.border),

                // Timeline
                _SectionLabel('Timeline'),
                _TimelineStep(
                  label: 'Created',
                  time: b.createdAt != null
                      ? formatDateTime(b.createdAt!)
                      : '-',
                  isActive: true,
                ),
                if (b.checkinAt != null)
                  _TimelineStep(
                    label: 'Worker Checked In',
                    time: formatDateTime(b.checkinAt!),
                    isActive: true,
                  ),
                if (b.checkoutAt != null)
                  _TimelineStep(
                    label: 'Worker Checked Out',
                    time: formatDateTime(b.checkoutAt!),
                    isActive: true,
                  ),
                if (b.status == 'completed')
                  _TimelineStep(
                    label: 'Completed',
                    time: b.checkoutAt != null
                        ? formatDateTime(b.checkoutAt!)
                        : '-',
                    isActive: true,
                    isLast: true,
                  ),
                if (b.status == 'cancelled')
                  _TimelineStep(
                    label: 'Cancelled',
                    time: '-',
                    isActive: true,
                    isLast: true,
                    color: AppColors.error,
                  ),
                const Divider(height: 20, color: AppColors.border),

                // Dispute section
                if (b.status == 'disputed') ...[
                  _SectionLabel('Dispute'),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.gavel_rounded,
                                color: AppColors.error, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Booking is Disputed',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                        if (b.disputeReason != null &&
                            b.disputeReason!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Reason: ${b.disputeReason}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () =>
                                _showResolveDisputeDialog(context, ref, b),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                            child: const Text('Resolve Dispute'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20, color: AppColors.border),
                ],

                // Admin actions
                _SectionLabel('Admin Actions'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (b.status != 'cancelled' && b.status != 'completed')
                      _ActionButton(
                        label: 'Reschedule',
                        icon: Icons.schedule_rounded,
                        color: AppColors.statusAssigned,
                        onPressed: () =>
                            _showRescheduleDialog(context, ref, b),
                      ),
                    if (b.status != 'cancelled' && b.status != 'completed')
                      _ActionButton(
                        label: 'Cancel',
                        icon: Icons.cancel_outlined,
                        color: AppColors.error,
                        onPressed: () =>
                            _showCancelDialog(context, ref, b),
                      ),
                    if (b.status != 'disputed' &&
                        b.status != 'cancelled' &&
                        b.status != 'pending')
                      _ActionButton(
                        label: 'Mark Disputed',
                        icon: Icons.gavel_rounded,
                        color: AppColors.statusDisputed,
                        onPressed: () =>
                            _showDisputeDialog(context, ref, b),
                      ),
                    _ActionButton(
                      label: 'Override Price',
                      icon: Icons.currency_rupee_rounded,
                      color: AppColors.secondary,
                      onPressed: () =>
                          _showOverridePriceDialog(context, ref, b),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, Booking b) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#${b.bookingNumber ?? '-'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: b.status, type: 'booking'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  b.serviceCategory?.name ?? 'Service',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () =>
                ref.read(selectedBookingIdProvider.notifier).select(null),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  // ── Assign Worker Dialog ─────────────────────────────────────────

  void _showAssignWorkerDialog(
      BuildContext context, WidgetRef ref, Booking b) {
    showDialog(
      context: context,
      builder: (ctx) => _AssignWorkerDialog(
        booking: b,
        onAssign: (workerId) async {
          Navigator.pop(ctx);
          await ref
              .read(bookingListProvider.notifier)
              .assignWorker(b.id, workerId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Worker assigned successfully'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        },
      ),
    );
  }

  // ── Reschedule Dialog ────────────────────────────────────────────

  void _showRescheduleDialog(
      BuildContext context, WidgetRef ref, Booking b) {
    final dateCtrl = TextEditingController(
      text: _dateFmt.format(b.slotDate),
    );
    final startCtrl = TextEditingController(text: b.slotStart);
    final endCtrl = TextEditingController(text: b.slotEnd);
    DateTime selectedDate = b.slotDate;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reschedule Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today_rounded, size: 18),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate:
                      DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  selectedDate = picked;
                  dateCtrl.text = _dateFmt.format(picked);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: startCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Start Time',
                      border: OutlineInputBorder(),
                      hintText: '09:00',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: endCtrl,
                    decoration: const InputDecoration(
                      labelText: 'End Time',
                      border: OutlineInputBorder(),
                      hintText: '11:00',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(bookingListProvider.notifier)
                  .rescheduleBooking(
                    b.id,
                    selectedDate,
                    startCtrl.text.trim(),
                    endCtrl.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking rescheduled'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }

  // ── Cancel Dialog ────────────────────────────────────────────────

  void _showCancelDialog(
      BuildContext context, WidgetRef ref, Booking b) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancel booking #${b.bookingNumber}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Cancellation reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(bookingListProvider.notifier)
                  .cancelBooking(b.id, reasonCtrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking cancelled'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  // ── Dispute Dialog ───────────────────────────────────────────────

  void _showDisputeDialog(
      BuildContext context, WidgetRef ref, Booking b) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Disputed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mark booking #${b.bookingNumber} as disputed?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Dispute reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.statusDisputed),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(bookingListProvider.notifier)
                  .markDisputed(b.id, reasonCtrl.text.trim());
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking marked as disputed'),
                    backgroundColor: AppColors.statusDisputed,
                  ),
                );
              }
            },
            child: const Text('Mark Disputed'),
          ),
        ],
      ),
    );
  }

  // ── Resolve Dispute Dialog ───────────────────────────────────────

  void _showResolveDisputeDialog(
      BuildContext context, WidgetRef ref, Booking b) {
    final resolutionCtrl = TextEditingController();
    final priceCtrl = TextEditingController(
      text: (b.finalPrice ?? b.quotedPrice ?? 0).toStringAsFixed(0),
    );
    bool overridePrice = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Resolve Dispute'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (b.disputeReason != null && b.disputeReason!.isNotEmpty) ...[
                Text(
                  'Reason: ${b.disputeReason}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: resolutionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Resolution notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: overridePrice,
                onChanged: (v) =>
                    setDlgState(() => overridePrice = v ?? false),
                title: const Text('Override price',
                    style: TextStyle(fontSize: 13)),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              if (overridePrice)
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'New price',
                    border: OutlineInputBorder(),
                    prefixText: '\u20B9 ',
                  ),
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final price = overridePrice
                    ? double.tryParse(priceCtrl.text.trim())
                    : null;
                await ref
                    .read(bookingListProvider.notifier)
                    .resolveDispute(
                      b.id,
                      resolutionCtrl.text.trim(),
                      price,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dispute resolved'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              child: const Text('Resolve'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Override Price Dialog ─────────────────────────────────────────

  void _showOverridePriceDialog(
      BuildContext context, WidgetRef ref, Booking b) {
    final priceCtrl = TextEditingController(
      text: (b.finalPrice ?? b.quotedPrice ?? 0).toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Override Price'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current: ${formatINR(b.finalPrice ?? b.quotedPrice ?? 0)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(
                labelText: 'New price',
                border: OutlineInputBorder(),
                prefixText: '\u20B9 ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary),
            onPressed: () async {
              final newPrice =
                  double.tryParse(priceCtrl.text.trim());
              Navigator.pop(ctx);
              if (newPrice != null) {
                await ref
                    .read(bookingListProvider.notifier)
                    .overridePrice(b.id, newPrice);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Price updated to ${formatINR(newPrice)}'),
                      backgroundColor: AppColors.secondary,
                    ),
                  );
                }
              }
            },
            child: const Text('Update Price'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Assign Worker Dialog
// ═══════════════════════════════════════════════════════════════════

class _AssignWorkerDialog extends ConsumerWidget {
  const _AssignWorkerDialog({
    required this.booking,
    required this.onAssign,
  });
  final Booking booking;
  final Future<void> Function(String workerId) onAssign;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catId = booking.serviceCategoryId ?? '';
    final asyncWorkers =
        ref.watch(availableWorkersForBookingProvider(catId));

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Assign Worker')),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
            splashRadius: 18,
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        height: 400,
        child: asyncWorkers.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (workers) {
            if (workers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_off_rounded,
                        size: 40, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text(
                      'No available workers\nfor this service category',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: workers.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (_, i) {
                final w = workers[i];
                final profile =
                    w['profiles'] as Map<String, dynamic>? ?? {};
                final name =
                    profile['full_name']?.toString() ?? 'Worker';
                final phone = profile['phone']?.toString() ?? '';
                final avatarUrl = profile['avatar_url']?.toString();
                final rating =
                    (w['rating'] as num?)?.toDouble() ?? 0;
                final jobs = w['total_jobs_completed'] as int? ?? 0;
                final city = w['city']?.toString() ?? '';

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.12),
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '$phone | $city | ${rating.toStringAsFixed(1)} | $jobs jobs',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: FilledButton(
                    onPressed: () => onAssign(w['id'] as String),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Assign',
                        style: TextStyle(fontSize: 12)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Small shared widgets
// ═══════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
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
            width: 110,
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

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.time,
    this.isActive = false,
    this.isLast = false,
    this.color,
  });
  final String label;
  final String time;
  final bool isActive;
  final bool isLast;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final dotColor = color ??
        (isActive ? AppColors.primary : AppColors.textSecondary);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
              child: isActive
                  ? const Icon(Icons.check, size: 8, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              if (!isLast) const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}
