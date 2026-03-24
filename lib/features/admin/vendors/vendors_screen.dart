import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/csv_export.dart';
import '../shared/widgets/admin_data_table.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/filter_chip_row.dart';
import '../shared/widgets/status_badge.dart';
import '../shared/widgets/detail_panel_wrapper.dart';
import '../shared/widgets/export_button.dart';
import '../shared/widgets/confirm_dialog.dart';
import 'vendors_provider.dart';
import 'vendor_detail_panel.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  final _searchCtrl = TextEditingController();
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorListProvider);
    final selectedVendor = ref.watch(selectedVendorProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final filtered = vendorState.filteredVendors;
    final sorted = _sortVendors(filtered);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SectionHeader(
                title: 'Vendors',
                subtitle: '${filtered.length} vendors',
                actions: [
                  ExportButton(onPressed: () => _exportCSV(filtered)),
                ],
              ),

              // Filter chips + search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: FilterChipRow(
                        options: const [
                          'All',
                          'Pending',
                          'Active',
                          'Suspended',
                        ],
                        selected: vendorState.filter,
                        onSelected: (f) {
                          ref.read(vendorListProvider.notifier).setFilter(f);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 240,
                      height: 36,
                      child: TextField(
                        controller: _searchCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search shop, owner, phone...',
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
                          ref.read(vendorListProvider.notifier).setSearch(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Table
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AdminDataTable(
                    isLoading: vendorState.isLoading,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    emptyIcon: Icons.store_outlined,
                    emptyTitle: 'No vendors found',
                    emptySubtitle: vendorState.filter != 'All'
                        ? 'No ${vendorState.filter.toLowerCase()} vendors'
                        : null,
                    minWidth: 1100,
                    columns: [
                      DataColumn2(
                        label: const Text('Shop'),
                        size: ColumnSize.L,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Owner'),
                        size: ColumnSize.M,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Location'),
                        size: ColumnSize.S,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('FSSAI'),
                        size: ColumnSize.S,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Status'),
                        size: ColumnSize.S,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Orders'),
                        size: ColumnSize.S,
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Revenue'),
                        size: ColumnSize.S,
                        numeric: true,
                        onSort: _onSort,
                      ),
                      DataColumn2(
                        label: const Text('Joined'),
                        size: ColumnSize.S,
                        onSort: _onSort,
                      ),
                      const DataColumn2(
                        label: Text('Actions'),
                        size: ColumnSize.M,
                        fixedWidth: 180,
                      ),
                    ],
                    rows: sorted.map((v) => _buildRow(v, isDesktop)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Detail panel (desktop)
        if (isDesktop && selectedVendor != null)
          DetailPanelWrapper(
            title: selectedVendor.shopName,
            onClose: () =>
                ref.read(selectedVendorProvider.notifier).clear(),
            child: VendorDetailPanel(vendor: selectedVendor),
          ),
      ],
    );
  }

  DataRow2 _buildRow(VendorRow v, bool isDesktop) {
    return DataRow2(
      onTap: () => _openDetail(v, isDesktop),
      cells: [
        // Shop
        DataCell(
          Row(
            children: [
              _ShopAvatar(name: v.shopName),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      v.shopName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (v.shopNameTamil != null &&
                        v.shopNameTamil!.isNotEmpty)
                      Text(
                        v.shopNameTamil!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Owner
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                v.ownerName?.isNotEmpty == true ? v.ownerName! : '-',
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                v.ownerPhone ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Location
        DataCell(Text('${v.city ?? "Chennai"}, ${v.pincode ?? "-"}')),
        // FSSAI
        DataCell(
          v.fssaiNumber != null && v.fssaiNumber!.isNotEmpty
              ? const Icon(Icons.check_circle_rounded,
                  size: 18, color: AppColors.statusDelivered)
              : const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.statusReady,
                  ),
                ),
        ),
        // Status
        DataCell(StatusBadge(status: v.status)),
        // Orders
        DataCell(Text(v.ordersCount.toString())),
        // Revenue
        DataCell(Text(formatINR(v.revenue))),
        // Joined
        DataCell(
          Text(
            v.createdAt != null ? formatDate(v.createdAt!) : '-',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        // Actions
        DataCell(_buildActions(v, isDesktop)),
      ],
    );
  }

  Widget _buildActions(VendorRow v, bool isDesktop) {
    switch (v.status) {
      case 'pending':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              label: 'Approve',
              color: AppColors.statusDelivered,
              onTap: () => _approveDialog(v),
            ),
            const SizedBox(width: 6),
            _ActionButton(
              label: 'Reject',
              color: AppColors.error,
              onTap: () => _rejectDialog(v),
            ),
          ],
        );
      case 'suspended':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              label: 'View',
              color: AppColors.primary,
              onTap: () => _openDetail(v, isDesktop),
            ),
            const SizedBox(width: 6),
            _ActionButton(
              label: 'Reinstate',
              color: AppColors.statusDelivered,
              onTap: () => _reinstateDialog(v),
            ),
          ],
        );
      default: // active
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionButton(
              label: 'View',
              color: AppColors.primary,
              onTap: () => _openDetail(v, isDesktop),
            ),
            const SizedBox(width: 6),
            _ActionButton(
              label: 'Suspend',
              color: AppColors.error,
              onTap: () => _suspendDialog(v),
            ),
          ],
        );
    }
  }

  void _openDetail(VendorRow v, bool isDesktop) {
    if (isDesktop) {
      ref.read(selectedVendorProvider.notifier).select(v);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(v.shopName)),
            body: VendorDetailPanel(vendor: v),
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

  List<VendorRow> _sortVendors(List<VendorRow> vendors) {
    if (_sortColumnIndex == null) return vendors;
    final list = List<VendorRow>.from(vendors);
    final asc = _sortAscending;
    list.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.shopName.compareTo(b.shopName);
        case 1:
          cmp = (a.ownerName ?? '').compareTo(b.ownerName ?? '');
        case 2:
          cmp = (a.pincode ?? '').compareTo(b.pincode ?? '');
        case 3:
          cmp = (a.fssaiNumber ?? '').compareTo(b.fssaiNumber ?? '');
        case 4:
          cmp = a.status.compareTo(b.status);
        case 5:
          cmp = a.ordersCount.compareTo(b.ordersCount);
        case 6:
          cmp = a.revenue.compareTo(b.revenue);
        case 7:
          cmp = (a.createdAt ?? DateTime(2000))
              .compareTo(b.createdAt ?? DateTime(2000));
        default:
          cmp = 0;
      }
      return asc ? cmp : -cmp;
    });
    return list;
  }

  void _exportCSV(List<VendorRow> vendors) {
    exportToCSV(
      'vendors_export.csv',
      [
        'Shop Name',
        'Owner',
        'Phone',
        'City',
        'Pincode',
        'FSSAI',
        'Status',
        'Orders',
        'Revenue',
        'Joined',
      ],
      vendors
          .map((v) => [
                v.shopName,
                v.ownerName ?? '-',
                v.ownerPhone ?? '-',
                v.city ?? '',
                v.pincode ?? '',
                v.fssaiNumber ?? '-',
                v.statusLabel,
                v.ordersCount,
                v.revenue,
                v.createdAt != null ? formatDate(v.createdAt!) : '-',
              ])
          .toList(),
    );
  }

  Future<void> _approveDialog(VendorRow v) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Approve Vendor',
      message:
          'Approve "${v.shopName}"? They will be able to receive orders.',
      confirmLabel: 'Approve',
      confirmColor: AppColors.statusDelivered,
    );
    if (confirmed == true && mounted) {
      await ref.read(vendorListProvider.notifier).approveVendor(v.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${v.shopName} approved'),
            backgroundColor: AppColors.statusDelivered,
          ),
        );
      }
    }
  }

  Future<void> _rejectDialog(VendorRow v) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reject Vendor',
      message:
          'Reject "${v.shopName}"? This will deactivate their application.',
      confirmLabel: 'Reject',
      confirmColor: AppColors.error,
    );
    if (confirmed == true && mounted) {
      await ref.read(vendorListProvider.notifier).rejectVendor(v.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${v.shopName} rejected'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _suspendDialog(VendorRow v) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Suspend Vendor',
      message: 'Suspend "${v.shopName}"?',
      confirmLabel: 'Suspend',
      confirmColor: AppColors.error,
      extraContent: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(
          labelText: 'Reason for suspension',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(vendorListProvider.notifier)
          .suspendVendor(v.id, reasonCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${v.shopName} suspended'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    reasonCtrl.dispose();
  }

  Future<void> _reinstateDialog(VendorRow v) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reinstate Vendor',
      message:
          'Reinstate "${v.shopName}"? They will be able to receive orders again.',
      confirmLabel: 'Reinstate',
      confirmColor: AppColors.statusDelivered,
    );
    if (confirmed == true && mounted) {
      await ref.read(vendorListProvider.notifier).reinstateVendor(v.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${v.shopName} reinstated'),
            backgroundColor: AppColors.statusDelivered,
          ),
        );
      }
    }
  }
}

// ── Small reusable widgets ───────────────────────────────────────

class _ShopAvatar extends StatelessWidget {
  const _ShopAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _hover
                ? widget.color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: widget.color.withValues(alpha: 0.5)),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
