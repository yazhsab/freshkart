import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/filter_chip_row.dart';
import '../shared/widgets/status_badge.dart';
import 'customers_provider.dart';
import 'customer_detail_panel.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  int _page = 1;
  static const _perPage = 20;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncCustomers = ref.watch(customersProvider);
    final filter = ref.watch(customerFilterProvider);
    final sort = ref.watch(customerSortProvider);
    final selectedId = ref.watch(selectedCustomerIdProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              SectionHeader(
                title: 'Customers',
                subtitle: 'Manage platform customers',
                actions: [
                  IconButton(
                    onPressed: () =>
                        ref.read(customersProvider.notifier).refresh(),
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              // Search + filter + sort
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: TextField(
                              controller: _searchCtrl,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Search name or phone...',
                                hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                                prefixIcon: const Icon(Icons.search_rounded,
                                    size: 18, color: AppColors.textSecondary),
                                filled: true,
                                fillColor: AppColors.background,
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 1.5)),
                              ),
                              onChanged: (v) {
                                ref
                                    .read(customerSearchProvider.notifier)
                                    .set(v);
                                _page = 1;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Sort dropdown
                        DropdownButton<String>(
                          value: sort,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.sort_rounded, size: 18),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textPrimary),
                          items: const [
                            DropdownMenuItem(
                                value: 'joined_desc',
                                child: Text('Newest first')),
                            DropdownMenuItem(
                                value: 'joined_asc',
                                child: Text('Oldest first')),
                            DropdownMenuItem(
                                value: 'spend_desc',
                                child: Text('Highest spend')),
                            DropdownMenuItem(
                                value: 'spend_asc',
                                child: Text('Lowest spend')),
                            DropdownMenuItem(
                                value: 'name_asc', child: Text('Name A-Z')),
                            DropdownMenuItem(
                                value: 'orders_desc',
                                child: Text('Most orders')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              ref.read(customerSortProvider.notifier).set(v);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilterChipRow(
                      options: const ['All', 'Active', 'Banned', 'New'],
                      selected: filter,
                      onSelected: (f) {
                        ref.read(customerFilterProvider.notifier).set(f);
                        _page = 1;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Data table
              Expanded(
                child: asyncCustomers.when(
                  loading: () => const LoadingShimmer(),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (customers) {
                    if (customers.isEmpty) {
                      return const EmptyState(
                        icon: Icons.people_outline,
                        title: 'No customers found',
                        subtitle: 'Try adjusting your search or filters.',
                      );
                    }

                    final totalPages =
                        (customers.length / _perPage).ceil();
                    final paginated = customers
                        .skip((_page - 1) * _perPage)
                        .take(_perPage)
                        .toList();

                    return Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            child: DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 8,
                              minWidth: 1100,
                              headingRowHeight: 44,
                              dataRowHeight: 56,
                              headingRowColor:
                                  WidgetStateProperty.all(AppColors.background),
                              columns: const [
                                DataColumn2(
                                    label: Text('Customer'), size: ColumnSize.L),
                                DataColumn2(label: Text('Phone')),
                                DataColumn2(label: Text('Joined')),
                                DataColumn2(
                                    label: Text('Orders'),
                                    numeric: true),
                                DataColumn2(
                                    label: Text('Bookings'),
                                    numeric: true),
                                DataColumn2(
                                    label: Text('Total Spend'),
                                    numeric: true),
                                DataColumn2(label: Text('Last Active')),
                                DataColumn2(label: Text('Status')),
                                DataColumn2(label: Text('Actions')),
                              ],
                              rows: paginated.map((c) {
                                return DataRow2(
                                  onTap: () {
                                    if (isDesktop) {
                                      ref
                                          .read(selectedCustomerIdProvider
                                              .notifier)
                                          .select(c.id);
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => Scaffold(
                                            body: CustomerDetailPanel(
                                                customerId: c.id,
                                                customer: c),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  cells: [
                                    DataCell(Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          backgroundImage: c.avatarUrl != null
                                              ? NetworkImage(c.avatarUrl!)
                                              : null,
                                          child: c.avatarUrl == null
                                              ? Text(c.initials,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.primary))
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(c.displayName,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w500)),
                                        ),
                                      ],
                                    )),
                                    DataCell(Text(c.phone,
                                        style: const TextStyle(
                                            fontSize: 12))),
                                    DataCell(Text(
                                        c.createdAt != null
                                            ? formatDate(c.createdAt!)
                                            : '--',
                                        style: const TextStyle(
                                            fontSize: 12))),
                                    DataCell(Text(
                                      '${c.orderCount} (${formatINRCompact(c.orderSpend)})',
                                      style: const TextStyle(fontSize: 12),
                                    )),
                                    DataCell(Text(
                                      '${c.bookingCount} (${formatINRCompact(c.bookingSpend)})',
                                      style: const TextStyle(fontSize: 12),
                                    )),
                                    DataCell(Text(
                                        formatINR(c.totalSpend),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600))),
                                    DataCell(Text(
                                        c.lastActive != null
                                            ? timeAgoStr(c.lastActive!)
                                            : 'Never',
                                        style: const TextStyle(
                                            fontSize: 12))),
                                    DataCell(StatusBadge(
                                        status: c.statusLabel
                                            .toLowerCase())),
                                    DataCell(_ActionCell(
                                      customer: c,
                                      onBan: () => ref
                                          .read(
                                              customersProvider.notifier)
                                          .toggleBan(c.id, true),
                                      onUnban: () => ref
                                          .read(
                                              customersProvider.notifier)
                                          .toggleBan(c.id, false),
                                    )),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        if (totalPages > 1)
                          _Pagination(
                            page: _page,
                            total: totalPages,
                            onChanged: (p) => setState(() => _page = p),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        // Detail panel
        if (isDesktop && selectedId != null)
          SizedBox(
            width: 440,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(left: BorderSide(color: AppColors.border)),
              ),
              child: asyncCustomers.whenData((customers) {
                    final c = customers.where((c) => c.id == selectedId).firstOrNull;
                    if (c == null) {
                      return const Center(child: Text('Customer not found'));
                    }
                    return CustomerDetailPanel(
                      customerId: selectedId,
                      customer: c,
                      onClose: () => ref
                          .read(selectedCustomerIdProvider.notifier)
                          .select(null),
                    );
                  }).value ??
                  const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({
    required this.customer,
    required this.onBan,
    required this.onUnban,
  });

  final CustomerRow customer;
  final VoidCallback onBan;
  final VoidCallback onUnban;

  @override
  Widget build(BuildContext context) {
    if (!customer.isActive) {
      return TextButton(
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Unban Customer'),
              content: Text('Unban ${customer.displayName}?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Unban')),
              ],
            ),
          );
          if (ok == true) onUnban();
        },
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: const Text('Unban'),
      );
    }

    return TextButton(
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Ban Customer'),
            content: Text(
                'Ban ${customer.displayName}? They will not be able to place orders or bookings.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  child: const Text('Ban')),
            ],
          ),
        );
        if (ok == true) onBan();
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.error,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: const Text('Ban'),
    );
  }
}

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.total,
    required this.onChanged,
  });

  final int page;
  final int total;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton.icon(
            onPressed: page > 1 ? () => onChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left, size: 18),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 8),
          Text('Page $page of $total',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: page < total ? () => onChanged(page + 1) : null,
            icon: const Text('Next'),
            label: const Icon(Icons.chevron_right, size: 18),
          ),
        ],
      ),
    );
  }
}
