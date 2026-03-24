import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/booking_model.dart';
import 'package:freshkart_customer/core/models/worker_model.dart';
import 'package:freshkart_customer/core/config/supabase_config.dart';

/// Fetches a single booking by ID.
final _bookingDetailProvider = FutureProvider.family<BookingModel, String>((
  ref,
  bookingId,
) async {
  final response = await ApiClient().get(ApiEndpoints.bookingById(bookingId));
  final data = response.data as Map<String, dynamic>;
  return BookingModel.fromJson(data['booking'] as Map<String, dynamic>);
});

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const BookingConfirmationScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  RealtimeChannel? _channel;
  WorkerModel? _assignedWorker;
  bool _workerAssigned = false;

  @override
  void initState() {
    super.initState();
    _subscribeToBookingUpdates();
  }

  void _subscribeToBookingUpdates() {
    _channel = SupabaseConfig.client
        .channel('booking-${widget.bookingId}')
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
            final newRecord = payload.newRecord;
            if (newRecord['worker_id'] != null && !_workerAssigned) {
              // Fetch updated booking to get worker details
              ref.invalidate(_bookingDetailProvider(widget.bookingId));
              setState(() {
                _workerAssigned = true;
              });
            }
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
      body: SafeArea(
        child: bookingAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (booking) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 32),

              // Success icon
              const Center(
                child: Icon(Icons.check_circle, size: 120, color: Colors.green),
              ),
              const SizedBox(height: 24),

              // Heading
              const Center(
                child: Text(
                  'Booking Confirmed!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              // Booking number
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Booking #${booking.bookingNumber}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber[800],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Details card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.build,
                        label: 'Service',
                        value: booking.serviceCategory?.name ?? '-',
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.calendar_today,
                        label: 'Date',
                        value: DateFormat(
                          'EEE, dd MMM yyyy',
                        ).format(booking.slotDate),
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.schedule,
                        label: 'Time',
                        value: '${booking.slotStart} - ${booking.slotEnd}',
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: booking.serviceAddress != null
                            ? '${booking.serviceAddress!.flatNo}, ${booking.serviceAddress!.area}'
                            : '-',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Payment info
              Center(
                child: Text(
                  '\u20B999 booking fee paid',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Worker assignment section
              _WorkerAssignmentSection(
                booking: booking,
                workerAssigned: _workerAssigned || booking.workerId != null,
              ),
              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/bookings/${booking.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Booking Details',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/services');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.amber[700]!),
                    foregroundColor: Colors.amber[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Another Service',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    context.go('/');
                  },
                  child: Text(
                    'Go to Home',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amber[700]),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        const SizedBox(width: 8),
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

class _WorkerAssignmentSection extends StatelessWidget {
  final BookingModel booking;
  final bool workerAssigned;

  const _WorkerAssignmentSection({
    required this.booking,
    required this.workerAssigned,
  });

  @override
  Widget build(BuildContext context) {
    if (workerAssigned && booking.worker != null) {
      // Worker is assigned - show worker card
      final worker = booking.worker!;
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Worker Assigned',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[300],
                    child: worker.profile?.avatarUrl != null
                        ? ClipOval(
                            child: Image.network(
                              worker.profile!.avatarUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.profile?.fullName ?? 'Worker',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber[600],
                            ),
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
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Shimmer / looking for worker state
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const _ShimmerDots(),
            const SizedBox(height: 12),
            Text(
              'Looking for nearest worker...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.amber[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You will be notified once a worker is assigned',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated dots to simulate shimmer / loading.
class _ShimmerDots extends StatefulWidget {
  const _ShimmerDots();

  @override
  State<_ShimmerDots> createState() => _ShimmerDotsState();
}

class _ShimmerDotsState extends State<_ShimmerDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final opacity = (1.0 - (value * 2 - 1).abs()).clamp(0.3, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.amber[700]!.withOpacity(opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
