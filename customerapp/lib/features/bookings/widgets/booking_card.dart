import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:freshkart_customer/core/models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isUpcoming;

  const BookingCard({super.key, required this.booking, this.isUpcoming = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/bookings/${booking.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isUpcoming ? _buildUpcoming(context) : _buildPast(context),
        ),
      ),
    );
  }

  Widget _buildUpcoming(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Service icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.build, size: 20, color: Colors.amber[700]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.serviceCategory?.name ?? 'Service',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.worker?.profile?.fullName ?? 'Being assigned...',
                    style: TextStyle(
                      fontSize: 13,
                      color: booking.worker != null
                          ? Colors.grey[700]
                          : Colors.amber[700],
                      fontStyle: booking.worker != null
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            _StatusBadge(status: booking.status),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),

        // Date, time, address
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              DateFormat('EEE, dd MMM').format(booking.slotDate),
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              '${booking.slotStart} - ${booking.slotEnd}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        if (booking.serviceAddress != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${booking.serviceAddress!.flatNo}, ${booking.serviceAddress!.area}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => context.push('/bookings/${booking.id}'),
              child: Text(
                'View Details',
                style: TextStyle(color: Colors.amber[700]),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                _showCancelConfirm(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPast(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.build, size: 20, color: Colors.grey[500]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.serviceCategory?.name ?? 'Service',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy').format(booking.slotDate),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            _StatusBadge(status: booking.status),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            if (booking.worker?.profile?.fullName != null) ...[
              Icon(Icons.person, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 6),
              Text(
                booking.worker!.profile!.fullName,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
            ],
            if (booking.finalPrice != null) ...[
              Icon(Icons.currency_rupee, size: 14, color: Colors.grey[500]),
              Text(
                '\u20B9${booking.finalPrice!.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (booking.status == 'completed')
              TextButton(
                onPressed: () {
                  context.push('/bookings/${booking.id}/rate');
                },
                child: Text('Rate', style: TextStyle(color: Colors.amber[700])),
              ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                // Navigate to book the same service again
                if (booking.serviceCategoryId.isNotEmpty) {
                  context.push('/services/${booking.serviceCategoryId}/book');
                }
              },
              child: Text('Rebook', style: TextStyle(color: Colors.amber[700])),
            ),
          ],
        ),
      ],
    );
  }

  void _showCancelConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // The actual cancellation is handled via the detail screen
              // or the bookings provider. Navigate to detail for cancel flow.
              context.push('/bookings/${booking.id}');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  String get _label {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'confirmed':
        return 'Confirmed';
      case 'worker_on_way':
        return 'On the way';
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

  Color get _bgColor {
    switch (status) {
      case 'completed':
        return Colors.green[50]!;
      case 'cancelled':
        return Colors.red[50]!;
      default:
        return Colors.amber[50]!;
    }
  }

  Color get _textColor {
    switch (status) {
      case 'completed':
        return Colors.green[700]!;
      case 'cancelled':
        return Colors.red[700]!;
      default:
        return Colors.amber[800]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}
