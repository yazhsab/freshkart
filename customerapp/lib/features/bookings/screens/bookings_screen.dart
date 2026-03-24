import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/features/bookings/providers/bookings_provider.dart';
import 'package:freshkart_customer/features/bookings/widgets/booking_card.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch bookings on screen load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingsProvider.notifier).fetchBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.amber[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : state.error != null
          ? _ErrorView(
              error: state.error!,
              onRetry: () =>
                  ref.read(bookingsProvider.notifier).fetchBookings(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Upcoming tab
                _BookingsList(
                  bookings: state.upcomingBookings,
                  isUpcoming: true,
                  emptyMessage: 'No upcoming bookings',
                  emptySubtext:
                      'Book a service to see your upcoming bookings here.',
                  onRefresh: () =>
                      ref.read(bookingsProvider.notifier).fetchBookings(),
                ),
                // Past tab
                _BookingsList(
                  bookings: state.pastBookings,
                  isUpcoming: false,
                  emptyMessage: 'No past bookings',
                  emptySubtext:
                      'Your completed and cancelled bookings will appear here.',
                  onRefresh: () =>
                      ref.read(bookingsProvider.notifier).fetchBookings(),
                ),
              ],
            ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List bookings;
  final bool isUpcoming;
  final String emptyMessage;
  final String emptySubtext;
  final Future<void> Function() onRefresh;

  const _BookingsList({
    required this.bookings,
    required this.isUpcoming,
    required this.emptyMessage,
    required this.emptySubtext,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUpcoming ? Icons.calendar_today : Icons.history,
                size: 64,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtext,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.amber[700],
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return BookingCard(booking: bookings[index], isUpcoming: isUpcoming);
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load bookings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
