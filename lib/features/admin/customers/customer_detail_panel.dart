import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../shared/widgets/status_badge.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/empty_state.dart';
import 'customers_provider.dart';

class CustomerDetailPanel extends ConsumerStatefulWidget {
  const CustomerDetailPanel({
    super.key,
    required this.customerId,
    required this.customer,
    this.onClose,
  });

  final String customerId;
  final CustomerRow customer;
  final VoidCallback? onClose;

  @override
  ConsumerState<CustomerDetailPanel> createState() =>
      _CustomerDetailPanelState();
}

class _CustomerDetailPanelState extends ConsumerState<CustomerDetailPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage:
                    c.avatarUrl != null ? NetworkImage(c.avatarUrl!) : null,
                child: c.avatarUrl == null
                    ? Text(c.initials,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.displayName,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(c.phone,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              StatusBadge(status: c.statusLabel.toLowerCase()),
              if (widget.onClose != null)
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 20),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Tabs
        TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Orders'),
            Tab(text: 'Bookings'),
            Tab(text: 'Payments'),
            Tab(text: 'Notes'),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _OverviewTab(customer: c),
              _OrdersTab(customerId: widget.customerId),
              _BookingsTab(customerId: widget.customerId),
              _PaymentsTab(customerId: widget.customerId),
              _NotesTab(
                controller: _notesCtrl,
                customerId: widget.customerId,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Overview tab ─────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.customer});
  final CustomerRow customer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _OverviewStat(
                  label: 'Grocery Orders',
                  value: customer.orderCount.toString(),
                  sub: formatINRCompact(customer.orderSpend),
                  color: AppColors.primary),
              const SizedBox(width: 12),
              _OverviewStat(
                  label: 'Service Bookings',
                  value: customer.bookingCount.toString(),
                  sub: formatINRCompact(customer.bookingSpend),
                  color: AppColors.secondary),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _OverviewStat(
                  label: 'Total Spend',
                  value: formatINR(customer.totalSpend),
                  color: AppColors.textPrimary),
              const SizedBox(width: 12),
              _OverviewStat(
                  label: 'Last Active',
                  value: customer.lastActive != null
                      ? timeAgoStr(customer.lastActive!)
                      : 'Never',
                  color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          _InfoRow(label: 'Email', value: customer.email ?? '--'),
          _InfoRow(label: 'Phone', value: customer.phone),
          _InfoRow(
              label: 'Joined',
              value: customer.createdAt != null
                  ? formatDate(customer.createdAt!)
                  : '--'),
          _InfoRow(
              label: 'Status',
              value: customer.isActive ? 'Active' : 'Banned'),
          _InfoRow(label: 'User ID', value: customer.id),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.label,
    required this.value,
    this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String? sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            if (sub != null)
              Text(sub!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

// ── Orders tab ───────────────────────────────────────────────────

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(customerOrdersProvider(customerId));

    return asyncOrders.when(
      loading: () => const LoadingShimmer(height: 200),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (orders) {
        if (orders.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final o = orders[i];
            final vendorName =
                (o['vendors'] as Map<String, dynamic>?)?['shop_name'] ?? '--';
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${o['order_number'] ?? o['id'].toString().substring(0, 8)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(vendorName.toString(),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          formatINR(
                              ((o['final_amount'] as num?) ?? 0).toDouble()),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      StatusBadge(
                          status: o['status'] as String? ?? 'pending',
                          type: 'order'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Bookings tab ─────────────────────────────────────────────────

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookings = ref.watch(customerBookingsProvider(customerId));

    return asyncBookings.when(
      loading: () => const LoadingShimmer(height: 200),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (bookings) {
        if (bookings.isEmpty) {
          return const EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'No bookings yet',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final b = bookings[i];
            final catName = (b['service_categories']
                    as Map<String, dynamic>?)?['name'] ??
                '--';
            final price = ((b['final_price'] as num?) ?? 0).toDouble();
            final fee = ((b['booking_fee'] as num?) ?? 0).toDouble();
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${b['booking_number'] ?? b['id'].toString().substring(0, 8)}',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(catName.toString(),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                        Text(
                            '${b['slot_date']} ${b['slot_start'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatINR(price + fee),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      StatusBadge(
                          status: b['status'] as String? ?? 'pending',
                          type: 'booking'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Payments tab ─────────────────────────────────────────────────

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({required this.customerId});
  final String customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPayments = ref.watch(customerPaymentsProvider(customerId));

    return asyncPayments.when(
      loading: () => const LoadingShimmer(height: 200),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (payments) {
        if (payments.isEmpty) {
          return const EmptyState(
            icon: Icons.payment_outlined,
            title: 'No payments yet',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) {
            final p = payments[i];
            final isOrder = p['type'] == 'order';
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    isOrder
                        ? Icons.shopping_bag_outlined
                        : Icons.home_repair_service_outlined,
                    size: 18,
                    color: isOrder ? AppColors.primary : AppColors.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${p['ref']}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        Text(
                            '${p['method'] ?? 'N/A'} | ${p['date']?.toString().split('T').first ?? ''}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          formatINR(((p['amount'] as num?) ?? 0).toDouble()),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      StatusBadge(
                          status: p['status'] as String? ?? 'pending',
                          type: 'payment'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Notes tab ────────────────────────────────────────────────────

class _NotesTab extends StatefulWidget {
  const _NotesTab({required this.controller, required this.customerId});
  final TextEditingController controller;
  final String customerId;

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  final _notes = <Map<String, String>>[];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _notes.isEmpty
              ? const EmptyState(
                  icon: Icons.note_outlined,
                  title: 'No notes yet',
                  subtitle: 'Add internal notes about this customer.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final n = _notes[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9C4).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n['text'] ?? '',
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(n['time'] ?? '',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  },
                ),
        ),
        // Add note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: TextStyle(fontSize: 13),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final text = widget.controller.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _notes.insert(0, {
                        'text': text,
                        'time': formatDateTime(DateTime.now()),
                      });
                    });
                    widget.controller.clear();
                  }
                },
                icon: const Icon(Icons.send_rounded),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
