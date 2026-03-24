import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/worker.dart';
import '../../../core/utils/date_helpers.dart';
import '../shared/widgets/admin_data_table.dart';
import '../shared/widgets/filter_chip_row.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/status_badge.dart';
import 'worker_detail_screen.dart';
import 'workers_provider.dart';

class WorkersScreen extends ConsumerStatefulWidget {
  const WorkersScreen({super.key});

  @override
  ConsumerState<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends ConsumerState<WorkersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(workerListProvider);
    final workers = st.filtered;
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
                title: 'Workers',
                subtitle: '${st.workers.length} total workers',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    onPressed: () =>
                        ref.read(workerListProvider.notifier).loadWorkers(),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
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
                    minWidth: 1300,
                    emptyIcon: Icons.engineering_outlined,
                    emptyTitle: 'No workers found',
                    emptySubtitle: 'Try adjusting your filters',
                    columns: const [
                      DataColumn2(label: Text('Worker'), size: ColumnSize.L),
                      DataColumn2(label: Text('Phone'), size: ColumnSize.S),
                      DataColumn2(label: Text('Skills'), size: ColumnSize.L),
                      DataColumn2(label: Text('BGV'), size: ColumnSize.S),
                      DataColumn2(
                          label: Text('Aadhaar'), fixedWidth: 70),
                      DataColumn2(
                          label: Text('Police'), fixedWidth: 70),
                      DataColumn2(label: Text('Rating'), fixedWidth: 70),
                      DataColumn2(
                          label: Text('Jobs'), fixedWidth: 60, numeric: true),
                      DataColumn2(
                          label: Text('Avail'), fixedWidth: 55),
                      DataColumn2(label: Text('Joined'), size: ColumnSize.S),
                      DataColumn2(
                          label: Text('Actions'), size: ColumnSize.M),
                    ],
                    rows: workers.map((w) => _buildRow(w, isDesktop)).toList(),
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

  Widget _buildFilters(WorkerListState st) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // BGV status chips
        SizedBox(
          width: 460,
          child: FilterChipRow(
            options: const ['All', 'pending', 'in_progress', 'approved', 'rejected'],
            selected: st.bgvFilter,
            onSelected: (v) =>
                ref.read(workerListProvider.notifier).setBgvFilter(v),
          ),
        ),

        // Skill dropdown
        SizedBox(
          width: 180,
          height: 36,
          child: DropdownButtonFormField<String>(
            value: st.skillFilter,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'All Skills',
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
              const DropdownMenuItem(value: null, child: Text('All Skills')),
              ...st.serviceCategories.map(
                (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
              ),
            ],
            onChanged: (v) =>
                ref.read(workerListProvider.notifier).setSkillFilter(v),
          ),
        ),

        // City dropdown
        SizedBox(
          width: 160,
          height: 36,
          child: DropdownButtonFormField<String>(
            value: st.cityFilter,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'All Cities',
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
              const DropdownMenuItem(value: null, child: Text('All Cities')),
              ...st.cities.map(
                (c) => DropdownMenuItem(value: c, child: Text(c)),
              ),
            ],
            onChanged: (v) =>
                ref.read(workerListProvider.notifier).setCityFilter(v),
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
              hintText: 'Search name or phone...',
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
                ref.read(workerListProvider.notifier).setSearch(v),
          ),
        ),
      ],
    );
  }

  // ── Table row ────────────────────────────────────────────────────

  DataRow2 _buildRow(Worker w, bool isDesktop) {
    final catMap = <String, String>{};
    for (final c in ref.read(workerListProvider).serviceCategories) {
      catMap[c.id] = c.name;
    }

    return DataRow2(
      onTap: () => _openDetail(w, isDesktop),
      cells: [
        // Avatar + Name
        DataCell(
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: w.profile?.avatarUrl != null
                    ? NetworkImage(w.profile!.avatarUrl!)
                    : null,
                child: w.profile?.avatarUrl == null
                    ? Text(
                        w.profile?.initials ?? '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      w.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      w.city,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Phone
        DataCell(Text(
          w.profile?.phone ?? '-',
          style: const TextStyle(fontSize: 13),
        )),
        // Skills chips
        DataCell(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: w.serviceCategoryIds.take(3).map((id) {
                final name = catMap[id] ?? id.substring(0, 6);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        // BGV status
        DataCell(StatusBadge(status: w.bgvStatus, type: 'bgv')),
        // Aadhaar check
        DataCell(
          Icon(
            w.aadhaarDocUrl != null && w.aadhaarDocUrl!.isNotEmpty
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 18,
            color: w.aadhaarDocUrl != null && w.aadhaarDocUrl!.isNotEmpty
                ? AppColors.bgvApproved
                : AppColors.textSecondary,
          ),
        ),
        // Police check
        DataCell(
          Icon(
            w.policeVerificationUrl != null &&
                    w.policeVerificationUrl!.isNotEmpty
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 18,
            color: w.policeVerificationUrl != null &&
                    w.policeVerificationUrl!.isNotEmpty
                ? AppColors.bgvApproved
                : AppColors.textSecondary,
          ),
        ),
        // Rating
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                w.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        // Jobs
        DataCell(Text(
          w.totalJobsCompleted.toString(),
          style: const TextStyle(fontSize: 13),
        )),
        // Available dot
        DataCell(
          Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: w.isAvailable
                    ? AppColors.bgvApproved
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
        // Joined
        DataCell(Text(
          w.createdAt != null ? formatDate(w.createdAt!) : '-',
          style: const TextStyle(fontSize: 12),
        )),
        // Actions
        DataCell(_buildActions(w, isDesktop)),
      ],
    );
  }

  Widget _buildActions(Worker w, bool isDesktop) {
    if (w.bgvStatus == 'pending' || w.bgvStatus == 'in_progress') {
      return TextButton.icon(
        onPressed: () => _openDetail(w, isDesktop),
        icon: const Icon(Icons.rate_review_outlined, size: 16),
        label: const Text('Review BGV', style: TextStyle(fontSize: 12)),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.bgvInProgress,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
      );
    }
    if (w.bgvStatus == 'approved' && w.isApproved) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _openDetail(w, isDesktop),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () => _suspendDialog(w),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            child: const Text('Suspend', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }
    // suspended or rejected
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          onPressed: () => _openDetail(w, isDesktop),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: const Text('View', style: TextStyle(fontSize: 12)),
        ),
        TextButton(
          onPressed: () => _reinstateDialog(w),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.bgvApproved,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          child: const Text('Reinstate', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  // ── Detail panel ─────────────────────────────────────────────────

  Widget _buildDetailPanel() {
    final selectedId = ref.watch(selectedWorkerIdProvider);
    if (selectedId == null) return const SizedBox.shrink();

    return Container(
      width: 440,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: WorkerDetailScreen(workerId: selectedId),
    );
  }

  void _openDetail(Worker w, bool isDesktop) {
    if (isDesktop) {
      ref.read(selectedWorkerIdProvider.notifier).select(w.id);
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              Scaffold(body: WorkerDetailScreen(workerId: w.id)),
        ),
      );
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────

  Future<void> _suspendDialog(Worker w) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspend Worker'),
        content: Text(
            'Suspend "${w.displayName}"? They will no longer receive bookings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(workerListProvider.notifier).suspendWorker(w.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${w.displayName} suspended'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _reinstateDialog(Worker w) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reinstate Worker'),
        content: Text(
            'Reinstate "${w.displayName}"? They will be able to accept bookings again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.bgvApproved),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reinstate'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(workerListProvider.notifier).reinstateWorker(w.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${w.displayName} reinstated'),
            backgroundColor: AppColors.bgvApproved,
          ),
        );
      }
    }
  }
}
