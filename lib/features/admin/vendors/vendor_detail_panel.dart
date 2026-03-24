import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../shared/widgets/status_badge.dart';
import '../shared/widgets/confirm_dialog.dart';
import 'vendors_provider.dart';

class VendorDetailPanel extends ConsumerStatefulWidget {
  const VendorDetailPanel({super.key, required this.vendor});
  final VendorRow vendor;

  @override
  ConsumerState<VendorDetailPanel> createState() => _VendorDetailPanelState();
}

class _VendorDetailPanelState extends ConsumerState<VendorDetailPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'Products'),
              Tab(text: 'Orders'),
              Tab(text: 'Payouts'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ProfileTab(vendor: widget.vendor),
              _ProductsTab(vendorId: widget.vendor.id),
              _OrdersTab(vendorId: widget.vendor.id),
              _PayoutsTab(vendorId: widget.vendor.id),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// TAB 1: Profile
// ═════════════════════════════════════════════════════════════════

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab({required this.vendor});
  final VendorRow vendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = vendor;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              StatusBadge(status: v.status),
              const Spacer(),
              if (v.isOpen)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.statusDelivered.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SHOP OPEN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusDelivered,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'SHOP CLOSED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Shop info
          _SectionLabel('Shop Information'),
          _InfoRow('Shop Name', v.shopName),
          if (v.shopNameTamil != null && v.shopNameTamil!.isNotEmpty)
            _InfoRow('Tamil Name', v.shopNameTamil!),
          if (v.description != null && v.description!.isNotEmpty)
            _InfoRow('Description', v.description!),
          const Divider(height: 24, color: AppColors.border),

          // Owner
          _SectionLabel('Owner Details'),
          _InfoRow('Name', v.ownerName?.isNotEmpty == true ? v.ownerName! : '-'),
          _InfoRow('Phone', v.ownerPhone ?? '-'),
          if (v.ownerEmail != null && v.ownerEmail!.isNotEmpty)
            _InfoRow('Email', v.ownerEmail!),
          const Divider(height: 24, color: AppColors.border),

          // Address
          _SectionLabel('Address'),
          _InfoRow('Address', v.address ?? '-'),
          _InfoRow('Pincode', v.pincode ?? '-'),
          _InfoRow('City', v.city ?? 'Chennai'),
          if (v.lat != null && v.lng != null)
            _InfoRow(
              'Coordinates',
              '${v.lat!.toStringAsFixed(6)}, ${v.lng!.toStringAsFixed(6)}',
            ),
          const Divider(height: 24, color: AppColors.border),

          // Documents / KYC
          _SectionLabel('KYC Documents'),
          Row(
            children: [
              Expanded(
                child:
                    _InfoRow('FSSAI', v.fssaiNumber ?? 'Not submitted'),
              ),
              if (v.fssaiDocUrl != null && v.fssaiDocUrl!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openDocUrl(context, v.fssaiDocUrl!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _InfoRow('GSTIN', v.gstin ?? 'Not submitted'),
              ),
              if (v.gstinDocUrl != null && v.gstinDocUrl!.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _openDocUrl(context, v.gstinDocUrl!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const Divider(height: 24, color: AppColors.border),

          // Bank
          _SectionLabel('Bank Details'),
          _InfoRow('Account', v.maskedBank),
          _InfoRow('IFSC', v.bankIfsc ?? '-'),
          const Divider(height: 24, color: AppColors.border),

          // Operations
          _SectionLabel('Operations'),
          _InfoRow(
            'Working Hours',
            '${v.openingTime ?? "-"} - ${v.closingTime ?? "-"}',
          ),
          if (v.workingDays.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 110,
                    child: Text(
                      'Working Days',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: v.workingDays
                          .map((d) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  d,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          _InfoRow('Delivery Radius', '${v.deliveryRadiusKm} km'),
          _InfoRow(
            'Rating',
            '${v.rating.toStringAsFixed(1)} (${v.totalRatings} reviews)',
          ),
          _InfoRow(
            'Joined',
            v.createdAt != null ? formatDate(v.createdAt!) : '-',
          ),
          const SizedBox(height: 20),

          // Action buttons
          if (v.status == 'active')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _suspendDialog(context, ref, v),
                icon:
                    const Icon(Icons.block_rounded, size: 16, color: AppColors.error),
                label: const Text(
                  'Suspend Vendor',
                  style: TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
          if (v.status == 'pending')
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _approveDialog(context, ref, v),
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.statusDelivered,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectDialog(context, ref, v),
                    icon: const Icon(Icons.cancel_outlined,
                        size: 16, color: AppColors.error),
                    label: const Text(
                      'Reject',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ),
          if (v.status == 'suspended')
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _reinstateDialog(context, ref, v),
                icon: const Icon(
                    Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Reinstate Vendor'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.statusDelivered,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openDocUrl(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening: $url')),
    );
  }

  Future<void> _approveDialog(
      BuildContext context, WidgetRef ref, VendorRow v) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Approve Vendor',
      message:
          'Approve "${v.shopName}"? They will be able to receive orders.',
      confirmLabel: 'Approve',
      confirmColor: AppColors.statusDelivered,
    );
    if (confirmed == true) {
      await ref.read(vendorListProvider.notifier).approveVendor(v.id);
    }
  }

  Future<void> _rejectDialog(
      BuildContext context, WidgetRef ref, VendorRow v) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reject Vendor',
      message:
          'Reject "${v.shopName}"? This will deactivate their application.',
      confirmLabel: 'Reject',
      confirmColor: AppColors.error,
    );
    if (confirmed == true) {
      await ref.read(vendorListProvider.notifier).rejectVendor(v.id);
    }
  }

  Future<void> _suspendDialog(
      BuildContext context, WidgetRef ref, VendorRow v) async {
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
          labelText: 'Reason',
          border: OutlineInputBorder(),
        ),
        maxLines: 2,
      ),
    );
    if (confirmed == true) {
      await ref
          .read(vendorListProvider.notifier)
          .suspendVendor(v.id, reasonCtrl.text);
    }
    reasonCtrl.dispose();
  }

  Future<void> _reinstateDialog(
      BuildContext context, WidgetRef ref, VendorRow v) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Reinstate Vendor',
      message: 'Reinstate "${v.shopName}"?',
      confirmLabel: 'Reinstate',
      confirmColor: AppColors.statusDelivered,
    );
    if (confirmed == true) {
      await ref.read(vendorListProvider.notifier).reinstateVendor(v.id);
    }
  }
}

// ═════════════════════════════════════════════════════════════════
// TAB 2: Products
// ═════════════════════════════════════════════════════════════════

class _ProductsTab extends ConsumerWidget {
  const _ProductsTab({required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(vendorProductsProvider(vendorId));

    return asyncProducts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (products) {
        final unavailable =
            products.where((p) => p['is_available'] != true).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${products.length} products ($unavailable unavailable)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? const Center(
                      child: Text(
                        'No products',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final p = products[i];
                        final available = p['is_available'] == true;
                        final stock = p['stock_quantity'] as int? ?? 0;
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: p['image_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      p['image_url'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_outlined,
                                        size: 18,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                          ),
                          title: Text(
                            p['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${formatINR((p['price'] as num?)?.toDouble() ?? 0)}'
                            ' / ${p['unit'] ?? ""}'
                            ' - Stock: $stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: stock <= 5
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: Switch(
                            value: available,
                            activeColor: AppColors.statusDelivered,
                            onChanged: (val) {
                              ref
                                  .read(vendorListProvider.notifier)
                                  .toggleProductAvailability(p['id'], val);
                              ref.invalidate(
                                  vendorProductsProvider(vendorId));
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// TAB 3: Orders (last 30 days)
// ═════════════════════════════════════════════════════════════════

class _OrdersTab extends ConsumerWidget {
  const _OrdersTab({required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrders = ref.watch(vendorOrdersProvider(vendorId));

    return asyncOrders.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (orders) {
        var totalRevenue = 0.0;
        var cancellations = 0;
        for (final o in orders) {
          totalRevenue += ((o['final_amount'] as num?) ?? 0).toDouble();
          if (o['status'] == 'cancelled') cancellations++;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _MiniStat(label: 'Orders', value: orders.length.toString()),
                  const SizedBox(width: 16),
                  _MiniStat(
                    label: 'Revenue',
                    value: formatINR(totalRevenue),
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    label: 'Cancelled',
                    value: cancellations.toString(),
                    color: cancellations > 0 ? AppColors.error : null,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: orders.isEmpty
                  ? const Center(
                      child: Text(
                        'No orders in last 30 days',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: orders.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final o = orders[i];
                        final date = DateTime.tryParse(
                            o['created_at']?.toString() ?? '');
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '#${o['order_number'] ?? "-"}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            date != null ? formatDate(date) : '-',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatINR(
                                  ((o['final_amount'] as num?) ?? 0)
                                      .toDouble(),
                                ),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                status: o['status']?.toString() ?? '',
                                type: 'order',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// TAB 4: Payouts
// ═════════════════════════════════════════════════════════════════

class _PayoutsTab extends ConsumerWidget {
  const _PayoutsTab({required this.vendorId});
  final String vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPayouts = ref.watch(vendorPayoutsProvider(vendorId));

    return asyncPayouts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e', style: const TextStyle(color: AppColors.error)),
      ),
      data: (data) {
        final records = data['records'] as List? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _PayoutStat(
                    label: 'Gross Earned',
                    value: formatINR(
                      (data['totalEarned'] as num?)?.toDouble() ?? 0,
                    ),
                    color: AppColors.textPrimary,
                  ),
                  _PayoutStat(
                    label: 'Commission',
                    value: formatINR(
                      (data['totalCommission'] as num?)?.toDouble() ?? 0,
                    ),
                    color: AppColors.secondary,
                  ),
                  _PayoutStat(
                    label: 'Net Paid',
                    value: formatINR(
                      (data['totalPaid'] as num?)?.toDouble() ?? 0,
                    ),
                    color: AppColors.statusDelivered,
                  ),
                  _PayoutStat(
                    label: 'Pending',
                    value: formatINR(
                      (data['pending'] as num?)?.toDouble() ?? 0,
                    ),
                    color: AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionLabel('Payout History'),
              const SizedBox(height: 8),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No payout records',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              else
                ...records.map((r) {
                  final paidAt =
                      DateTime.tryParse(r['paid_at']?.toString() ?? '');
                  final status = r['status']?.toString() ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatINR(
                                  ((r['net_amount'] as num?) ?? 0)
                                      .toDouble(),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                paidAt != null
                                    ? formatDate(paidAt)
                                    : 'Pending',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: status, type: 'payment'),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════
// Shared small widgets
// ═════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PayoutStat extends StatelessWidget {
  const _PayoutStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
