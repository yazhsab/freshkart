import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:freshkart_worker/core/models/booking_model.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/currency_util.dart';
import 'package:freshkart_worker/core/utils/date_util.dart';
import 'package:freshkart_worker/core/utils/extensions.dart';
import 'package:freshkart_worker/core/location/location_service.dart';
import 'package:freshkart_worker/features/bookings/providers/bookings_provider.dart';
import 'package:freshkart_worker/features/bookings/widgets/booking_status_stepper.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';
import 'package:freshkart_worker/shared/widgets/confirm_dialog.dart';
import 'package:freshkart_worker/shared/widgets/status_badge.dart';

final bookingDetailProvider = FutureProvider.family<BookingModel?, String>((
  ref,
  id,
) async {
  final data = await Supabase.instance.client
      .from('bookings')
      .select()
      .eq('id', id)
      .maybeSingle();
  return data != null ? BookingModel.fromJson(data) : null;
});

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingAsync = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: bookingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (booking) {
          if (booking == null)
            return const Center(child: Text('Booking not found'));
          return _BookingDetailContent(booking: booking);
        },
      ),
    );
  }
}

class _BookingDetailContent extends ConsumerWidget {
  final BookingModel booking;
  const _BookingDetailContent({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        BookingStatusStepper(status: booking.status),
        const SizedBox(height: 20),
        _InfoCard(
          title: 'Service',
          children: [
            _InfoRow('Service', booking.serviceName ?? 'N/A'),
            _InfoRow('Date', DateUtil.formatDay(booking.scheduledDate)),
            _InfoRow('Time', booking.slotFormatted),
            _InfoRow(
              'Status',
              '',
              trailing: StatusBadge(status: booking.status),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Customer',
          children: [
            _InfoRow('Name', booking.customerName ?? 'N/A'),
            _InfoRow('Phone', booking.customerPhone ?? 'N/A'),
            _InfoRow('Address', booking.customerAddress ?? 'N/A'),
            if (booking.customerLat != null && booking.customerLng != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppButton(
                  label: 'Navigate',
                  icon: Icons.navigation,
                  isOutlined: true,
                  onPressed: () => LocationService.navigateTo(
                    booking.customerLat!,
                    booking.customerLng!,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoCard(
          title: 'Earnings',
          children: [
            _InfoRow('Base Amount', CurrencyUtil.format(booking.baseAmount)),
            if (booking.additionalCharges != null &&
                booking.additionalCharges! > 0)
              _InfoRow(
                'Additional',
                CurrencyUtil.format(booking.additionalCharges!),
              ),
            _InfoRow('Total', CurrencyUtil.format(booking.displayAmount)),
            if (booking.workerEarnings != null)
              _InfoRow(
                'Your Earnings',
                CurrencyUtil.format(booking.workerEarnings!),
                valueStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: WorkerColors.earningsGreen,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _buildActions(context, ref),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(bookingsProvider.notifier);

    switch (booking.status) {
      case 'assigned':
        return Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Decline',
                isOutlined: true,
                color: Colors.red,
                onPressed: () async {
                  final confirmed = await ConfirmDialog.show(
                    context,
                    title: 'Decline Booking?',
                    message: 'Are you sure you want to decline this booking?',
                    isDangerous: true,
                  );
                  if (confirmed) {
                    await notifier.declineBooking(booking.id);
                    if (context.mounted) {
                      context.showSnackBar('Booking declined');
                      context.pop();
                    }
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                label: 'Accept',
                onPressed: () async {
                  await notifier.acceptBooking(booking.id);
                  if (context.mounted)
                    context.showSnackBar('Booking accepted!');
                },
              ),
            ),
          ],
        );
      case 'confirmed':
        return AppButton(
          label: 'On My Way',
          icon: Icons.directions_car,
          onPressed: () async {
            await notifier.markOnWay(booking.id);
            if (context.mounted) context.showSnackBar('Status updated');
          },
        );
      case 'on_way':
        return AppButton(
          label: 'Check In (Enter OTP)',
          icon: Icons.login,
          onPressed: () => context.push('/checkin/${booking.id}'),
        );
      case 'in_progress':
        return AppButton(
          label: 'Continue Job',
          icon: Icons.work,
          onPressed: () => context.push('/job-in-progress/${booking.id}'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final Widget? trailing;
  const _InfoRow(this.label, this.value, {this.valueStyle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            child:
                trailing ??
                Text(
                  value,
                  style:
                      valueStyle ??
                      const TextStyle(fontWeight: FontWeight.w500),
                ),
          ),
        ],
      ),
    );
  }
}
