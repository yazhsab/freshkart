import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/csv_export.dart';
import '../shared/widgets/admin_data_table.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/stat_card.dart';
import '../shared/widgets/export_button.dart';
import 'loyalty_provider.dart';

class LoyaltyScreen extends ConsumerStatefulWidget {
  const LoyaltyScreen({super.key});

  @override
  ConsumerState<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends ConsumerState<LoyaltyScreen> {
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
    final loyaltyState = ref.watch(loyaltyProvider);
    final stats = loyaltyState.stats;
    final filtered = loyaltyState.filteredUsers;
    final sorted = _sortUsers(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        SectionHeader(
          title: 'Loyalty Program',
          subtitle: 'Points & rewards management',
          actions: [
            ExportButton(onPressed: () => _exportCSV(filtered)),
          ],
        ),

        // Config cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.settings_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Configuration',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 24),
                _ConfigChip(
                  label: 'Points per \u20B9100',
                  value: stats.pointsPer100.toString(),
                ),
                const SizedBox(width: 16),
                _ConfigChip(
                  label: 'Point Value',
                  value: '\u20B9${stats.pointValue.toStringAsFixed(2)}',
                ),
                const SizedBox(width: 16),
                _ConfigChip(
                  label: 'Min Redeem',
                  value: '${stats.minRedeem} pts',
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _showConfigDialog,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Config'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Stats cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Points Earned',
                  value: _formatPoints(stats.totalPointsEarned),
                  icon: Icons.stars_outlined,
                  accentColor: AppColors.primary,
                  subtitle:
                      'Worth ${formatINR(stats.totalPointsEarned * stats.pointValue)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total Redeemed',
                  value: _formatPoints(stats.totalPointsRedeemed),
                  icon: Icons.redeem,
                  accentColor: AppColors.statusDelivered,
                  subtitle:
                      'Worth ${formatINR(stats.totalPointsRedeemed * stats.pointValue)}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Outstanding Points',
                  value: _formatPoints(stats.totalOutstanding),
                  icon: Icons.account_balance,
                  accentColor: AppColors.secondary,
                  subtitle:
                      'Liability: ${formatINR(stats.totalOutstanding * stats.pointValue)}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Spacer(),
              SizedBox(
                width: 280,
                height: 36,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search name, phone...',
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
                    ref.read(loyaltyProvider.notifier).setSearch(v);
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
              isLoading: loyaltyState.isLoading,
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              emptyIcon: Icons.stars_outlined,
              emptyTitle: 'No loyalty accounts found',
              minWidth: 900,
              columns: [
                DataColumn2(
                  label: const Text('Customer'),
                  size: ColumnSize.L,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Phone'),
                  size: ColumnSize.M,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Balance'),
                  size: ColumnSize.S,
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Total Earned'),
                  size: ColumnSize.S,
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Total Redeemed'),
                  size: ColumnSize.S,
                  numeric: true,
                  onSort: _onSort,
                ),
                DataColumn2(
                  label: const Text('Last Earned'),
                  size: ColumnSize.S,
                  onSort: _onSort,
                ),
              ],
              rows: sorted.map((u) => _buildRow(u)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  DataRow2 _buildRow(LoyaltyUserRow u) {
    return DataRow2(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                u.userName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              if (u.userEmail != null)
                Text(
                  u.userEmail!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        DataCell(Text(u.userPhone ?? '-')),
        DataCell(
          Text(
            _formatPoints(u.pointsBalance),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: u.pointsBalance > 0
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
        ),
        DataCell(Text(_formatPoints(u.totalEarned))),
        DataCell(Text(_formatPoints(u.totalRedeemed))),
        DataCell(
          Text(
            u.lastEarnedAt != null ? timeAgoStr(u.lastEarnedAt!) : '-',
            style: const TextStyle(fontSize: 12),
          ),
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

  List<LoyaltyUserRow> _sortUsers(List<LoyaltyUserRow> users) {
    if (_sortColumnIndex == null) return users;
    final list = List<LoyaltyUserRow>.from(users);
    final asc = _sortAscending;
    list.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.userName.compareTo(b.userName);
        case 1:
          cmp = (a.userPhone ?? '').compareTo(b.userPhone ?? '');
        case 2:
          cmp = a.pointsBalance.compareTo(b.pointsBalance);
        case 3:
          cmp = a.totalEarned.compareTo(b.totalEarned);
        case 4:
          cmp = a.totalRedeemed.compareTo(b.totalRedeemed);
        case 5:
          cmp = (a.lastEarnedAt ?? DateTime(2000))
              .compareTo(b.lastEarnedAt ?? DateTime(2000));
        default:
          cmp = 0;
      }
      return asc ? cmp : -cmp;
    });
    return list;
  }

  void _showConfigDialog() {
    final stats = ref.read(loyaltyProvider).stats;
    final pointsPer100Ctrl =
        TextEditingController(text: stats.pointsPer100.toString());
    final pointValueCtrl =
        TextEditingController(text: stats.pointValue.toString());
    final minRedeemCtrl =
        TextEditingController(text: stats.minRedeem.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Loyalty Configuration'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pointsPer100Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Points per \u20B9100 spent',
                    border: OutlineInputBorder(),
                    helperText:
                        'How many loyalty points earned per \u20B9100 order value',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointValueCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Point Value (\u20B9)',
                    border: OutlineInputBorder(),
                    helperText: 'INR value of each loyalty point when redeemed',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: minRedeemCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Minimum Points to Redeem',
                    border: OutlineInputBorder(),
                    helperText:
                        'User must have at least this many points to redeem',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await ref.read(loyaltyProvider.notifier).updateConfig({
                  'loyalty_points_per_100': pointsPer100Ctrl.text.trim(),
                  'loyalty_point_value': pointValueCtrl.text.trim(),
                  'loyalty_min_redeem': minRedeemCtrl.text.trim(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Loyalty configuration updated'),
                      backgroundColor: AppColors.statusDelivered,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _formatPoints(int points) {
    if (points >= 10000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return points.toString();
  }

  void _exportCSV(List<LoyaltyUserRow> users) {
    exportToCSV(
      'loyalty_export.csv',
      [
        'Customer',
        'Phone',
        'Email',
        'Points Balance',
        'Total Earned',
        'Total Redeemed',
        'Last Earned',
      ],
      users
          .map((u) => [
                u.userName,
                u.userPhone ?? '-',
                u.userEmail ?? '-',
                u.pointsBalance,
                u.totalEarned,
                u.totalRedeemed,
                u.lastEarnedAt != null
                    ? formatDate(u.lastEarnedAt!)
                    : '-',
              ])
          .toList(),
    );
  }
}

// ── Config chip ──────────────────────────────────────────────────

class _ConfigChip extends StatelessWidget {
  const _ConfigChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
