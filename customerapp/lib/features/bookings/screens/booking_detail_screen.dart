import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/booking_model.dart';
import 'package:freshkart_customer/core/config/supabase_config.dart';
import 'package:freshkart_customer/features/bookings/providers/bookings_provider.dart';
import 'package:freshkart_customer/features/bookings/widgets/booking_status_stepper.dart';

/// Fetches a single booking by ID.
final _bookingDetailProvider = FutureProvider.family<BookingModel, String>((
  ref,
  bookingId,
) async {
  final response = await ApiClient().get(ApiEndpoints.bookingById(bookingId));
  final data = response.data as Map<String, dynamic>;
  return BookingModel.fromJson(data['booking'] as Map<String, dynamic>);
});

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _subscribeToUpdates();
  }

  void _subscribeToUpdates() {
    _channel = SupabaseConfig.client
        .channel('booking-detail-${widget.bookingId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.bookingId,
          ),
          callback: (payload) {
            // Refresh the booking details when updated.
            ref.invalidate(_bookingDetailProvider(widget.bookingId));
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(_bookingDetailProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
      ),
      body: bookingAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (booking) => _BookingDetailBody(booking: booking),
      ),
    );
  }
}

class _BookingDetailBody extends ConsumerWidget {
  final BookingModel booking;

  const _BookingDetailBody({required this.booking});

  bool get _isUpcoming => const {
    'pending',
    'assigned',
    'confirmed',
    'worker_on_way',
    'in_progress',
  }.contains(booking.status);

  bool get _isCompleted => booking.status == 'completed';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status banner
        _StatusBanner(status: booking.status),
        const SizedBox(height: 16),

        // Booking info card
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.confirmation_number,
                  label: 'Booking #',
                  value: booking.bookingNumber,
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.build,
                  label: 'Service',
                  value: booking.serviceCategory?.name ?? '-',
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: DateFormat(
                    'EEE, dd MMM yyyy',
                  ).format(booking.slotDate),
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.schedule,
                  label: 'Time',
                  value: '${booking.slotStart} - ${booking.slotEnd}',
                ),
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.location_on,
                  label: 'Address',
                  value: booking.serviceAddress != null
                      ? '${booking.serviceAddress!.flatNo}, ${booking.serviceAddress!.area}, ${booking.serviceAddress!.city}'
                      : '-',
                ),
                if (booking.customerNotes != null &&
                    booking.customerNotes!.isNotEmpty) ...[
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.notes,
                    label: 'Notes',
                    value: booking.customerNotes!,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Worker card (if assigned)
        if (booking.worker != null) ...[
          _WorkerSection(booking: booking),
          const SizedBox(height: 12),
          // Chat with Worker button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber[700],
                side: BorderSide(color: Colors.amber[700]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.chat_outlined),
              label: const Text(
                'Chat with Worker',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () => context.push(
                '/profile/chat?bookingId=${booking.id}&partyType=worker&partyId=${booking.workerId}',
              ),
            ),
          ),
          const SizedBox(height: 16),
        ] else if (_isUpcoming) ...[
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.amber[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.amber,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Worker being assigned...'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Payment breakdown
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _PaymentRow(
                  label: 'Booking fee',
                  value: '\u20B9${booking.bookingFee.toStringAsFixed(0)}',
                ),
                if (booking.quotedPrice != null) ...[
                  const SizedBox(height: 8),
                  _PaymentRow(
                    label: 'Service fee (estimated)',
                    value: '\u20B9${booking.quotedPrice!.toStringAsFixed(0)}',
                  ),
                ],
                if (booking.finalPrice != null) ...[
                  const SizedBox(height: 8),
                  _PaymentRow(
                    label: 'Final amount',
                    value: '\u20B9${booking.finalPrice!.toStringAsFixed(0)}',
                  ),
                ],
                const Divider(height: 20),
                _PaymentRow(
                  label: 'Total',
                  value: '\u20B9${_total.toStringAsFixed(0)}',
                  isBold: true,
                ),
                const SizedBox(height: 8),
                _PaymentRow(
                  label: 'Payment method',
                  value: booking.paymentMethod.toUpperCase(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Timeline stepper
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Timeline',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                BookingStatusStepper(currentStatus: booking.status),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Action buttons
        if (_isUpcoming)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel Booking',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

        if (_isCompleted)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                context.push('/bookings/${booking.id}/rate');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Rate this service',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  double get _total {
    if (booking.finalPrice != null) {
      return booking.bookingFee + booking.finalPrice!;
    }
    if (booking.quotedPrice != null) {
      return booking.bookingFee + booking.quotedPrice!;
    }
    return booking.bookingFee;
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, keep it'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(bookingsProvider.notifier)
                  .cancelBooking(booking.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking cancelled')),
                );
                context.pop();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;

  const _StatusBanner({required this.status});

  String get _label {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Worker Assigned';
      case 'confirmed':
        return 'Confirmed';
      case 'worker_on_way':
        return 'Worker on the way';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color get _color {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.amber[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          _label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _WorkerSection extends StatelessWidget {
  final BookingModel booking;

  const _WorkerSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    final worker = booking.worker!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigned Worker',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[300],
                  child: worker.profile?.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            worker.profile!.avatarUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.profile?.fullName ?? 'Worker',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${worker.rating}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${worker.experienceYears} yrs exp',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Call button
                if (worker.profile?.phone != null)
                  IconButton(
                    onPressed: () {
                      launchUrl(Uri.parse('tel:${worker.profile!.phone}'));
                    },
                    icon: Icon(Icons.phone, color: Colors.green[600]),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.green[50],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.amber[700]),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PaymentRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black87 : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? Colors.amber[700] : Colors.black87,
          ),
        ),
      ],
    );
  }
}
