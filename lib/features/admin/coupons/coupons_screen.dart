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
import '../shared/widgets/export_button.dart';
import '../shared/widgets/confirm_dialog.dart';
import 'coupon_provider.dart';

class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
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
    final couponState = ref.watch(couponListProvider);
    final filtered = couponState.filteredCoupons;
    final sorted = _sortCoupons(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        SectionHeader(
          title: 'Coupons',
          subtitle: '${filtered.length} coupons',
          actions: [
            FilledButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Coupon'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(width: 8),
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
                    'Active',
                    'Inactive',
                    'Vendor',
                    'Platform',
                    'Percentage',
                    'Flat',
                  ],
                  selected: couponState.filter,
                  onSelected: (f) {
                    ref.read(couponListProvider.notifier).setFilter(f);
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
                    hintText: 'Search code, title...',
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
                    ref.read(couponListProvider.notifier).setSearch(v);
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
              isLoading: couponState.isLoading,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              emptyIcon: Icons.local_offer_outlined,
              emptyTitle: 'No coupons found',
              emptySubtitle: couponState.filter != 'All'
                  ? 'No ${couponState.filter.toLowerCase()} coupons'
                  : null,
              minWidth: 1100,
              columns: [
                DataColumn2(
                  label: const Text('Code'),
                  size: ColumnSize.M,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Title'),
                  size: ColumnSize.L,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Type'),
                  size: ColumnSize.S,
                  fixedWidth: 100,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Value'),
                  size: ColumnSize.S,
                  fixedWidth: 90,
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Min Order'),
                  size: ColumnSize.S,
                  fixedWidth: 100,
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Usage'),
                  size: ColumnSize.S,
                  fixedWidth: 90,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Status'),
                  size: ColumnSize.S,
                  fixedWidth: 90,
                  onSort: _onSort,
                ),
                const DataColumn2(
                  label: Text('Actions'),
                  size: ColumnSize.M,
                  fixedWidth: 180,
                ),
              ],
              rows: sorted.map((c) => _buildRow(c)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  DataRow2 _buildRow(CouponRow c) {
    return DataRow2(
      cells: [
        // Code
        DataCell(
          Text(
            c.code,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Title
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                c.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              if (c.vendorName != null)
                Text(
                  c.vendorName!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        // Type
        DataCell(_TypeBadge(type: c.typeLabel)),
        // Value
        DataCell(Text(
          c.discountLabel,
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
        // Min Order
        DataCell(Text(formatINR(c.minOrderAmount))),
        // Usage
        DataCell(Text(c.usageLabel)),
        // Status
        DataCell(StatusBadge(
          status: c.isActive ? 'active' : 'inactive',
        )),
        // Actions
        DataCell(_buildActions(c)),
      ],
    );
  }

  Widget _buildActions(CouponRow c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionButton(
          label: c.isActive ? 'Deactivate' : 'Activate',
          color: c.isActive ? AppColors.error : AppColors.statusDelivered,
          onTap: () => _toggleActive(c),
        ),
        const SizedBox(width: 6),
        _ActionButton(
          label: 'Edit',
          color: AppColors.primary,
          onTap: () => _showEditDialog(c),
        ),
      ],
    );
  }

  void _onSort(int colIndex, bool asc) {
    setState(() {
      _sortColumnIndex = colIndex;
      _sortAscending = asc;
    });
  }

  List<CouponRow> _sortCoupons(List<CouponRow> coupons) {
    if (_sortColumnIndex == null) return coupons;
    final list = List<CouponRow>.from(coupons);
    final asc = _sortAscending;
    list.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.code.compareTo(b.code);
        case 1:
          cmp = a.title.compareTo(b.title);
        case 2:
          cmp = a.discountType.compareTo(b.discountType);
        case 3:
          cmp = a.discountValue.compareTo(b.discountValue);
        case 4:
          cmp = a.minOrderAmount.compareTo(b.minOrderAmount);
        case 5:
          cmp = a.usedCount.compareTo(b.usedCount);
        case 6:
          cmp = (a.isActive ? 1 : 0).compareTo(b.isActive ? 1 : 0);
        default:
          cmp = 0;
      }
      return asc ? cmp : -cmp;
    });
    return list;
  }

  Future<void> _toggleActive(CouponRow c) async {
    final action = c.isActive ? 'Deactivate' : 'Activate';
    final confirmed = await showConfirmDialog(
      context,
      title: '$action Coupon',
      message: '$action coupon "${c.code}"?',
      confirmLabel: action,
      confirmColor:
          c.isActive ? AppColors.error : AppColors.statusDelivered,
    );
    if (confirmed == true && mounted) {
      await ref
          .read(couponListProvider.notifier)
          .toggleActive(c.id, !c.isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${c.code} ${c.isActive ? "deactivated" : "activated"}'),
            backgroundColor:
                c.isActive ? AppColors.error : AppColors.statusDelivered,
          ),
        );
      }
    }
  }

  void _showCreateDialog() {
    _showCouponFormDialog(null);
  }

  void _showEditDialog(CouponRow c) {
    _showCouponFormDialog(c);
  }

  void _showCouponFormDialog(CouponRow? existing) {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final valueCtrl = TextEditingController(
      text: existing?.discountValue.toStringAsFixed(0) ?? '',
    );
    final minOrderCtrl = TextEditingController(
      text: existing?.minOrderAmount.toStringAsFixed(0) ?? '0',
    );
    final maxDiscountCtrl = TextEditingController(
      text: existing?.maxDiscount?.toStringAsFixed(0) ?? '',
    );
    final usageLimitCtrl = TextEditingController(
      text: existing?.usageLimit?.toString() ?? '',
    );
    var discountType = existing?.discountType ?? 'percentage';
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Coupon' : 'Create Coupon'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Coupon Code',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. SAVE20',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        enabled: !isEdit,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Title / Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: discountType,
                              items: const [
                                DropdownMenuItem(
                                  value: 'percentage',
                                  child: Text('Percentage (%)'),
                                ),
                                DropdownMenuItem(
                                  value: 'flat',
                                  child: Text('Flat Amount'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setDialogState(() => discountType = v);
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Discount Type',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: valueCtrl,
                              decoration: InputDecoration(
                                labelText: discountType == 'percentage'
                                    ? 'Percentage'
                                    : 'Amount',
                                border: const OutlineInputBorder(),
                                suffixText:
                                    discountType == 'percentage' ? '%' : '\u20B9',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minOrderCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Min Order Amount',
                                border: OutlineInputBorder(),
                                prefixText: '\u20B9 ',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxDiscountCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Max Discount',
                                border: OutlineInputBorder(),
                                prefixText: '\u20B9 ',
                                hintText: 'Optional',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: usageLimitCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Usage Limit',
                          border: OutlineInputBorder(),
                          hintText: 'Leave empty for unlimited',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final data = <String, dynamic>{
                      'code': codeCtrl.text.trim().toUpperCase(),
                      'title': titleCtrl.text.trim(),
                      'discount_type': discountType,
                      'discount_value':
                          double.tryParse(valueCtrl.text) ?? 0,
                      'min_order_amount':
                          double.tryParse(minOrderCtrl.text) ?? 0,
                    };
                    if (maxDiscountCtrl.text.isNotEmpty) {
                      data['max_discount'] =
                          double.tryParse(maxDiscountCtrl.text);
                    }
                    if (usageLimitCtrl.text.isNotEmpty) {
                      data['usage_limit'] =
                          int.tryParse(usageLimitCtrl.text);
                    }

                    Navigator.of(ctx).pop();

                    if (isEdit) {
                      await ref
                          .read(couponListProvider.notifier)
                          .updateCoupon(existing.id, data);
                    } else {
                      await ref
                          .read(couponListProvider.notifier)
                          .createCoupon(data);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit
                              ? 'Coupon updated'
                              : 'Coupon created'),
                          backgroundColor: AppColors.statusDelivered,
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: Text(isEdit ? 'Update' : 'Create'),
                ),
              ],
            );
          },
        );
      },
    );

    // Dispose controllers when dialog is done
    // (They are local to the method and will be GC'd after dialog closes)
  }

  void _exportCSV(List<CouponRow> coupons) {
    exportToCSV(
      'coupons_export.csv',
      [
        'Code',
        'Title',
        'Type',
        'Value',
        'Min Order',
        'Max Discount',
        'Used Count',
        'Usage Limit',
        'Status',
        'Created',
      ],
      coupons
          .map((c) => [
                c.code,
                c.title,
                c.typeLabel,
                c.discountValue,
                c.minOrderAmount,
                c.maxDiscount ?? '-',
                c.usedCount,
                c.usageLimit ?? 'Unlimited',
                c.isActive ? 'Active' : 'Inactive',
                c.createdAt != null ? formatDate(c.createdAt!) : '-',
              ])
          .toList(),
    );
  }
}

// ── Small reusable widgets ───────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final isPercentage = type == 'Percentage';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPercentage
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isPercentage ? AppColors.primary : AppColors.secondary,
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
