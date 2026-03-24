import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/order.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/csv_export.dart';
import '../shared/widgets/admin_data_table.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/filter_chip_row.dart';
import '../shared/widgets/status_badge.dart';
import '../shared/widgets/detail_panel_wrapper.dart';
import '../shared/widgets/export_button.dart';
import 'orders_provider.dart';
import 'order_detail_panel.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _searchCtrl = TextEditingController();
  int? _sortColumnIndex;
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderListProvider);
    final selectedOrder = ref.watch(selectedOrderProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final filtered = orderState.filteredOrders;
    final sorted = _sortOrders(filtered);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SectionHeader(
                title: 'Orders',
                subtitle: '${orderState.totalCount} orders',
                actions: [
                  ExportButton(onPressed: () => _exportCSV(filtered)),
                ],
              ),

              // Filter bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status chips
                    Row(
                      children: [
                        Expanded(
                          child: FilterChipRow(
                            options: const [
                              'All',
                              'Pending',
                              'Confirmed',
                              'Packing',
                              'Ready',
                              'Picked Up',
                              'Delivered',
                              'Cancelled',
                            ],
                            selected: orderState.statusFilter,
                            onSelected: (f) {
                              ref
                                  .read(orderListProvider.notifier)
                                  .setStatusFilter(f);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row: date range, payment filter, search
                    Row(
                      children: [
                        // Date range picker
                        OutlinedButton.icon(
                          onPressed: () => _pickDateRange(context),
                          icon: const Icon(Icons.calendar_today_outlined,
                              size: 16),
                          label: Text(
                            orderState.dateRange != null
                                ? '${formatDate(orderState.dateRange!.start)} - ${formatDate(orderState.dateRange!.end)}'
                                : 'Date Range',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        if (orderState.dateRange != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              ref
                                  .read(orderListProvider.notifier)
                                  .setDateRange(null);
                            },
                            style: IconButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                        // Payment filter
                        SizedBox(
                          width: 120,
                          height: 36,
                          child: DropdownButtonFormField<String>(
                            value: orderState.paymentFilter,
                            items: const [
                              DropdownMenuItem(
                                  value: 'All', child: Text('All Payments')),
                              DropdownMenuItem(
                                  value: 'COD', child: Text('COD')),
                              DropdownMenuItem(
                                  value: 'Online', child: Text('Online')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                ref
                                    .read(orderListProvider.notifier)
                                    .setPaymentFilter(v);
                              }
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                            isExpanded: true,
                          ),
                        ),
                        const Spacer(),
                        // Search
                        SizedBox(
                          width: 240,
                          height: 36,
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Search order#, customer...',
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
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
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            onChanged: (v) {
                              ref
                                  .read(orderListProvider.notifier)
                                  .setSearch(v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Summary row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _SummaryChip(
                        label: '${orderState.totalCount} orders',
                        icon: Icons.receipt_long_outlined,
                      ),
                      const SizedBox(width: 20),
                      _SummaryChip(
                        label: formatINR(orderState.totalAmount),
                        icon: Icons.currency_rupee,
                      ),
                      const SizedBox(width: 20),
                      _SummaryChip(
                        label: '${orderState.codCount} COD',
                        icon: Icons.money,
                      ),
                      const SizedBox(width: 20),
                      _SummaryChip(
                        label: '${orderState.onlineCount} Online',
                        icon: Icons.credit_card,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AdminDataTable(
                    isLoading: orderState.isLoading,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    currentPage: orderState.page,
                    totalPages: orderState.totalPages,
                    onPageChange: (page) {
                      ref.read(orderListProvider.notifier).setPage(page);
                    },
                    emptyIcon: Icons.receipt_long_outlined,
                    emptyTitle: 'No orders found',
                    emptySubtitle: orderState.statusFilter != 'All'
                        ? 'No ${orderState.statusFilter.toLowerCase()} orders'
                        : null,
                    minWidth: 1200,
                    columns: [
                      DataColumn2(
                        label: const Text('Order #'),
                        size: ColumnSize.S,
                        fixedWidth: 100,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Customer'),
                        size: ColumnSize.M,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Vendor'),
                        size: ColumnSize.M,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Items'),
                        size: ColumnSize.S,
                        numeric: true,
                        fixedWidth: 60,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Amount'),
                        size: ColumnSize.S,
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Payment'),
                        size: ColumnSize.S,
                        fixedWidth: 80,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Status'),
                        size: ColumnSize.S,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Agent'),
                        size: ColumnSize.S,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Time'),
                        size: ColumnSize.S,
                        onSort: _onSort,
                      ),
                      const DataColumn2(
                        label: Text(''),
                        size: ColumnSize.S,
                        fixedWidth: 60,
                      ),
                    ],
                    rows: sorted
                        .map((o) => _buildRow(o, isDesktop))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Detail panel (desktop)
        if (isDesktop && selectedOrder != null)
          DetailPanelWrapper(
            title: 'Order #${selectedOrder.orderNumber ?? selectedOrder.id.substring(0, 8)}',
            onClose: () =>
                ref.read(selectedOrderProvider.notifier).clear(),
            child: OrderDetailPanel(order: selectedOrder),
          ),
      ],
    );
  }

  DataRow2 _buildRow(Order o, bool isDesktop) {
    return DataRow2(
      onTap: () => _openDetail(o, isDesktop),
      cells: [
        // Order#
        DataCell(
          Text(
            '#${o.orderNumber ?? o.id.substring(0, 8)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        // Customer
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                o.customer?.displayName ?? '-',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                o.customer?.phone ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Vendor
        DataCell(
          Text(
            o.vendor?.shopName ?? '-',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        // Items
        DataCell(Text(o.itemCount.toString())),
        // Amount
        DataCell(
          Text(
            formatINR(o.finalAmount),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        // Payment
        DataCell(
          _PaymentBadge(method: o.paymentMethod ?? '-'),
        ),
        // Status
        DataCell(StatusBadge(status: o.status, type: 'order')),
        // Agent
        DataCell(
          Text(
            o.agent?.displayName ?? '-',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        // Time
        DataCell(
          Text(
            o.createdAt != null ? timeAgoStr(o.createdAt!) : '-',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        // View
        DataCell(
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 18),
            onPressed: () => _openDetail(o, isDesktop),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  void _openDetail(Order o, bool isDesktop) {
    if (isDesktop) {
      ref.read(selectedOrderProvider.notifier).select(o);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text('Order #${o.orderNumber ?? o.id.substring(0, 8)}'),
            ),
            body: OrderDetailPanel(order: o),
          ),
        ),
      );
    }
  }

  void _onSort(int colIndex, bool asc) {
    setState(() {
      _sortColumnIndex = colIndex;
      _sortAscending = asc;
    });
  }

  List<Order> _sortOrders(List<Order> orders) {
    if (_sortColumnIndex == null) return orders;
    final list = List<Order>.from(orders);
    final asc = _sortAscending;
    list.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = (a.orderNumber ?? '').compareTo(b.orderNumber ?? '');
        case 1:
          cmp = (a.customer?.displayName ?? '')
              .compareTo(b.customer?.displayName ?? '');
        case 2:
          cmp = (a.vendor?.shopName ?? '')
              .compareTo(b.vendor?.shopName ?? '');
        case 3:
          cmp = a.itemCount.compareTo(b.itemCount);
        case 4:
          cmp = a.finalAmount.compareTo(b.finalAmount);
        case 5:
          cmp = (a.paymentMethod ?? '').compareTo(b.paymentMethod ?? '');
        case 6:
          cmp = a.status.compareTo(b.status);
        case 7:
          cmp = (a.agent?.displayName ?? '')
              .compareTo(b.agent?.displayName ?? '');
        case 8:
          cmp = (a.createdAt ?? DateTime(2000))
              .compareTo(b.createdAt ?? DateTime(2000));
        default:
          cmp = 0;
      }
      return asc ? cmp : -cmp;
    });
    return list;
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      ref.read(orderListProvider.notifier).setDateRange(range);
    }
  }

  void _exportCSV(List<Order> orders) {
    exportToCSV(
      'orders_export.csv',
      [
        'Order #',
        'Customer',
        'Phone',
        'Vendor',
        'Items',
        'Total',
        'Delivery Fee',
        'Discount',
        'Final Amount',
        'Payment',
        'Payment Status',
        'Status',
        'Agent',
        'Created',
      ],
      orders
          .map((o) => [
                o.orderNumber ?? o.id,
                o.customer?.displayName ?? '-',
                o.customer?.phone ?? '-',
                o.vendor?.shopName ?? '-',
                o.itemCount,
                o.totalAmount,
                o.deliveryFee,
                o.discountAmount,
                o.finalAmount,
                o.paymentMethod ?? '-',
                o.paymentStatus,
                o.status,
                o.agent?.displayName ?? '-',
                o.createdAt != null ? formatDateTime(o.createdAt!) : '-',
              ])
          .toList(),
    );
  }
}

// ── Small widgets ────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    final isCod = method.toLowerCase() == 'cod';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCod
            ? AppColors.secondary.withValues(alpha: 0.15)
            : AppColors.statusConfirmed.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isCod ? AppColors.secondary : AppColors.statusConfirmed,
        ),
      ),
    );
  }
}
