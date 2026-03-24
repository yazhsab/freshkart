import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/features/bookings/providers/bookings_provider.dart';
import 'package:freshkart_worker/features/bookings/widgets/booking_card.dart';
import 'package:freshkart_worker/shared/widgets/empty_state_widget.dart';
import 'package:freshkart_worker/shared/widgets/shimmer_loader.dart';

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingsProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            labelColor: WorkerColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: WorkerColors.primary,
            tabs: [
              Tab(text: 'Upcoming (${state.upcoming.length})'),
              Tab(text: 'Active (${state.active.length})'),
              Tab(text: 'Past (${state.past.length})'),
            ],
          ),
        ),
        body: state.isLoading
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: ShimmerLoader.list(),
              )
            : TabBarView(
                children: [
                  _BookingList(
                    bookings: state.upcoming,
                    emptyIcon: Icons.event_available,
                    emptyText: 'No upcoming bookings',
                  ),
                  _BookingList(
                    bookings: state.active,
                    emptyIcon: Icons.work,
                    emptyText: 'No active jobs',
                  ),
                  _BookingList(
                    bookings: state.past,
                    emptyIcon: Icons.history,
                    emptyText: 'No past bookings',
                  ),
                ],
              ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List bookings;
  final IconData emptyIcon;
  final String emptyText;

  const _BookingList({
    required this.bookings,
    required this.emptyIcon,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty)
      return EmptyStateWidget(icon: emptyIcon, title: emptyText);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: BookingCard(
          booking: bookings[index],
          onTap: () => context.push('/booking/${bookings[index].id}'),
        ),
      ),
    );
  }
}
