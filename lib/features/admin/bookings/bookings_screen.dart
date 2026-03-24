import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/booking.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../shared/widgets/admin_data_table.dart';
import '../shared/widgets/filter_chip_row.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/status_badge.dart';
import 'booking_detail_panel.dart';
import 'bookings_provider.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(bookingListProvider);
    final bookings = st.filtered;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SectionHeader(
                title: 'Bookings',
                subtitle: '${st.bookings.length} total bookings',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: () =>
                        ref.read(bookingListProvider.notifier).loadBookings(),
                    tooltip: 'Refresh',
                  ),
                ],
              ),

              // Unassigned alert banner
              if (st.unassignedCount > 0)
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${st.unassignedCount} booking${st.unassignedCount > 1 ? 's' : ''} pending worker assignment',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(bookingListProvider.notifier)
                              .setStatusFilter('pending');
                        },
                        child: const Text('View',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 8),

              // Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildFilters(st),
              ),
              const SizedBox(height: 12),

              // Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AdminDataTable(
                    isLoading: st.isLoading,
                    minWidth: 1200,
                    emptyIcon: Icons.calendar_month_outlined,
                    emptyTitle: 'No bookings found',
                    emptySubtitle: 'Try adjusting your filters',
                    columns: const [
                      DataColumn2(
                          label: Text('Booking #'), fixedWidth: 100),
                      DataColumn2(
                          label: Text('Service'), size: ColumnSize.M),
                      DataColumn2(
                          label: Text('Customer'), size: ColumnSize.M),
                      DataColumn2(label: Text('Slot'), size: ColumnSize.M),
                      DataColumn2(
                          label: Text('Worker'), size: ColumnSize.M),
                      DataColumn2(
                          label: Text('Address'), size: ColumnSize.L),
                      DataColumn2(
                          label: Text('Price'), fixedWidth: 90, numeric: true),
                      DataColumn2(
                          label: Text('Status'), fixedWidth: 100),
                      DataColumn2(
                          label: Text('Payment'), fixedWidth: 85),
                      DataColumn2(
                          label: Text(''), fixedWidth: 60),
                    ],
                    rows: bookings
                        .map((b) => _buildRow(b, isDesktop))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Detail panel (desktop)
        if (isDesktop) _buildDetailPanel(),
      ],
    );
  }

  // ── Filters ──────────────────────────────────────────────────────

  Widget _buildFilters(BookingListState st) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Status chips
        SizedBox(
          width: 580,
          child: FilterChipRow(
            options: const [
              'All',
              'pending',
              'assigned',
              'confirmed',
              'worker_on_way',
              'in_progress',
              'completed',
              'cancelled',
              'disputed',
            ],
            selected: st.statusFilter,
            onSelected: (v) =>
                ref.read(bookingListProvider.notifier).setStatusFilter(v),
          ),
        ),

        // Date range picker
        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.date_range_rounded, size: 16),
            label: Text(
              st.dateRange != null
                  ? '${formatDate(st.dateRange!.start)} - ${formatDate(st.dateRange!.end)}'
                  : 'Date Range',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _pickDateRange(st),
            style: OutlinedButton.styleFrom(
              foregroundColor: st.dateRange != null
                  ? AppColors.primary
                  : AppColors.textPrimary,
              side: BorderSide(
                color: st.dateRange != null
                    ? AppColors.primary
                    : AppColors.border,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),

        // Clear date
        if (st.dateRange != null)
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: () =>
                ref.read(bookingListProvider.notifier).setDateRange(null),
            tooltip: 'Clear date filter',
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),

        // Category dropdown
        SizedBox(
          width: 180,
          height: 36,
          child: DropdownButtonFormField<String>(
            value: st.categoryFilter,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'All Services',
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('All Services')),
              ...st.serviceCategories.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (v) =>
                ref.read(bookingListProvider.notifier).setCategoryFilter(v),
          ),
        ),

        // Search
        SizedBox(
          width: 220,
          height: 36,
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search booking, name...',
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 18, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
            onChanged: (v) =>
                ref.read(bookingListProvider.notifier).setSearch(v),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDateRange(BookingListState st) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: st.dateRange != null
          ? DateTimeRange(
              start: st.dateRange!.start,
              end: st.dateRange!.end,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      ref.read(bookingListProvider.notifier).setDateRange(
            ProviderDateTimeRange(start: picked.start, end: picked.end),
          );
    }
  }

  // ── Table row ────────────────────────────────────────────────────

  DataRow2 _buildRow(Booking b, bool isDesktop) {
    final address = b.serviceAddress;
    final addressStr = address != null
        ? '${address['line1'] ?? ''}, ${address['pincode'] ?? ''}'
        : '-';

    return DataRow2(
      onTap: () => _openDetail(b, isDesktop),
      cells: [
        // Booking #
        DataCell(Text(
          '#${b.bookingNumber ?? '-'}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        )),
        // Service
        DataCell(Text(
          b.serviceCategory?.name ?? '-',
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        )),
        // Customer
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                b.customer?.displayName ?? '-',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                b.customer?.phone ?? '',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        // Slot
        DataCell(Text(
          formatSlot(b.slotDate, b.slotStart, b.slotEnd),
          style: const TextStyle(fontSize: 12),
        )),
        // Worker
        DataCell(
          b.isUnassigned
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    const Text(
                      'Unassigned',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                )
              : Text(
                  b.worker?.displayName ?? '-',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        // Address
        DataCell(Text(
          addressStr,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        )),
        // Price
        DataCell(Text(
          formatINR(b.finalPrice ?? b.quotedPrice ?? 0),
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500),
        )),
        // Status
        DataCell(StatusBadge(status: b.status, type: 'booking')),
        // Payment
        DataCell(StatusBadge(status: b.paymentStatus, type: 'payment')),
        // View button
        DataCell(
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            onPressed: () => _openDetail(b, isDesktop),
            splashRadius: 16,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Detail panel ─────────────────────────────────────────────────

  Widget _buildDetailPanel() {
    final selectedId = ref.watch(selectedBookingIdProvider);
    if (selectedId == null) return const SizedBox.shrink();

    return Container(
      width: 440,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: BookingDetailPanel(bookingId: selectedId),
    );
  }

  void _openDetail(Booking b, bool isDesktop) {
    if (isDesktop) {
      ref.read(selectedBookingIdProvider.notifier).select(b.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              Scaffold(body: BookingDetailPanel(bookingId: b.id)),
        ),
      );
    }
  }
}

