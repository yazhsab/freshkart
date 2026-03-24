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
import '../shared/widgets/status_badge.dart';
import '../shared/widgets/export_button.dart';
import 'referral_provider.dart';

class ReferralsScreen extends ConsumerStatefulWidget {
  const ReferralsScreen({super.key});

  @override
  ConsumerState<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends ConsumerState<ReferralsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refState = ref.watch(referralListProvider);
    final stats = refState.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        SectionHeader(
          title: 'Referrals',
          subtitle: 'Referral codes & rewards',
          actions: [
            ExportButton(
              onPressed: () => refState.activeTab == 0
                  ? _exportCodesCSV(refState.filteredCodes)
                  : _exportReferralsCSV(refState.filteredReferrals),
            ),
          ],
        ),

        // Stats cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final cards = [
                Expanded(
                  child: StatCard(
                    title: 'Total Referrals',
                    value: stats.totalReferrals.toString(),
                    icon: Icons.people_outline,
                    accentColor: AppColors.primary,
                  ),
                ),
                SizedBox(width: isWide ? 12 : 8),
                Expanded(
                  child: StatCard(
                    title: 'Total Rewards Paid',
                    value: formatINR(stats.totalRewardsPaid),
                    icon: Icons.payments_outlined,
                    accentColor: AppColors.statusDelivered,
                  ),
                ),
                SizedBox(width: isWide ? 12 : 8),
                Expanded(
                  child: StatCard(
                    title: 'Active Codes',
                    value: stats.activeReferralCodes.toString(),
                    icon: Icons.qr_code_2,
                    accentColor: AppColors.secondary,
                  ),
                ),
              ];

              return Row(children: cards);
            },
          ),
        ),
        const SizedBox(height: 16),

        // Tab bar + search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _TabButton(
                label: 'Referral Codes',
                isActive: refState.activeTab == 0,
                onTap: () => ref
                    .read(referralListProvider.notifier)
                    .setActiveTab(0),
              ),
              const SizedBox(width: 8),
              _TabButton(
                label: 'Individual Referrals',
                isActive: refState.activeTab == 1,
                onTap: () => ref
                    .read(referralListProvider.notifier)
                    .setActiveTab(1),
              ),
              const Spacer(),
              SizedBox(
                width: 240,
                height: 36,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search...',
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
                    ref.read(referralListProvider.notifier).setSearch(v);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Table (tab-based)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: refState.activeTab == 0
                ? _buildCodesTable(refState)
                : _buildReferralsTable(refState),
          ),
        ),
      ],
    );
  }

  Widget _buildCodesTable(ReferralListState refState) {
    final codes = refState.filteredCodes;
    return AdminDataTable(
      isLoading: refState.isLoading,
      emptyIcon: Icons.qr_code_2,
      emptyTitle: 'No referral codes found',
      minWidth: 900,
      columns: const [
        DataColumn2(label: Text('User'), size: ColumnSize.L),
        DataColumn2(label: Text('Phone'), size: ColumnSize.M),
        DataColumn2(label: Text('Code'), size: ColumnSize.M),
        DataColumn2(
          label: Text('Total Referrals'),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(
          label: Text('Total Earned'),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(
          label: Text('Status'),
          size: ColumnSize.S,
          fixedWidth: 90,
        ),
      ],
      rows: codes.map((c) => _buildCodeRow(c)).toList(),
    );
  }

  DataRow2 _buildCodeRow(ReferralCodeRow c) {
    return DataRow2(
      cells: [
        DataCell(Text(c.userName,
            style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(c.userPhone ?? '-')),
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
        DataCell(Text(c.totalReferrals.toString())),
        DataCell(Text(
          formatINR(c.totalEarned),
          style: const TextStyle(fontWeight: FontWeight.w500),
        )),
        DataCell(StatusBadge(
          status: c.isActive ? 'active' : 'inactive',
        )),
      ],
    );
  }

  Widget _buildReferralsTable(ReferralListState refState) {
    final referrals = refState.filteredReferrals;
    return AdminDataTable(
      isLoading: refState.isLoading,
      emptyIcon: Icons.people_outline,
      emptyTitle: 'No referrals found',
      minWidth: 1000,
      columns: const [
        DataColumn2(label: Text('Referrer'), size: ColumnSize.M),
        DataColumn2(label: Text('Referee'), size: ColumnSize.M),
        DataColumn2(
          label: Text('Status'),
          size: ColumnSize.S,
          fixedWidth: 100,
        ),
        DataColumn2(
          label: Text('Referrer Reward'),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(
          label: Text('Referee Reward'),
          size: ColumnSize.S,
          numeric: true,
        ),
        DataColumn2(label: Text('Date'), size: ColumnSize.S),
      ],
      rows: referrals.map((r) => _buildReferralRow(r)).toList(),
    );
  }

  DataRow2 _buildReferralRow(ReferralRow r) {
    return DataRow2(
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(r.referrerName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              if (r.referrerPhone != null)
                Text(
                  r.referrerPhone!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(r.refereeName,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              if (r.refereePhone != null)
                Text(
                  r.refereePhone!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        DataCell(StatusBadge(status: r.status)),
        DataCell(Text(formatINR(r.referrerReward))),
        DataCell(Text(formatINR(r.refereeReward))),
        DataCell(
          Text(
            r.createdAt != null ? formatDate(r.createdAt!) : '-',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  void _exportCodesCSV(List<ReferralCodeRow> codes) {
    exportToCSV(
      'referral_codes_export.csv',
      ['User', 'Phone', 'Code', 'Total Referrals', 'Total Earned', 'Status'],
      codes
          .map((c) => [
                c.userName,
                c.userPhone ?? '-',
                c.code,
                c.totalReferrals,
                c.totalEarned,
                c.isActive ? 'Active' : 'Inactive',
              ])
          .toList(),
    );
  }

  void _exportReferralsCSV(List<ReferralRow> referrals) {
    exportToCSV(
      'referrals_export.csv',
      [
        'Referrer',
        'Referrer Phone',
        'Referee',
        'Referee Phone',
        'Status',
        'Referrer Reward',
        'Referee Reward',
        'Date',
      ],
      referrals
          .map((r) => [
                r.referrerName,
                r.referrerPhone ?? '-',
                r.refereeName,
                r.refereePhone ?? '-',
                r.statusLabel,
                r.referrerReward,
                r.refereeReward,
                r.createdAt != null ? formatDate(r.createdAt!) : '-',
              ])
          .toList(),
    );
  }
}

// ── Tab button ───────────────────────────────────────────────────

class _TabButton extends StatefulWidget {
  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.primary
                : _hover
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isActive
                  ? AppColors.primary
                  : AppColors.border,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.isActive
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
