import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/worker.dart';
import '../../../core/utils/currency.dart';
import '../../../core/utils/date_helpers.dart';
import 'workers_provider.dart';

final _dateFmt = DateFormat('dd MMM yyyy');
final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 0);

class WorkerDetailScreen extends ConsumerWidget {
  const WorkerDetailScreen({super.key, required this.workerId});
  final String workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(workerListProvider);
    final worker = st.workers.where((w) => w.id == workerId).firstOrNull;

    if (worker == null) {
      return const Center(
        child: Text('Worker not found',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return _DetailContent(worker: worker, serviceCategories: st.serviceCategories);
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  const _DetailContent({
    required this.worker,
    required this.serviceCategories,
  });
  final Worker worker;
  final List<dynamic> serviceCategories;

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;

    return Column(
      children: [
        // Header
        _buildHeader(w),
        // Tabs
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: TabBar(
            controller: _tabCtrl,
            labelStyle:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Profile & BGV'),
              Tab(text: 'Skills'),
              Tab(text: 'Calendar'),
              Tab(text: 'Bookings'),
              Tab(text: 'Payouts'),
            ],
          ),
        ),
        // Tab views
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _ProfileBgvTab(worker: w),
              _SkillsTab(
                worker: w,
                serviceCategories: widget.serviceCategories,
              ),
              _AvailabilityCalendarTab(worker: w),
              _BookingHistoryTab(workerId: w.id),
              _PayoutsTab(workerId: w.id),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Worker w) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: w.profile?.avatarUrl != null
                ? NetworkImage(w.profile!.avatarUrl!)
                : null,
            child: w.profile?.avatarUrl == null
                ? Text(
                    w.profile?.initials ?? '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _BgvBadge(status: w.bgvStatus),
                    const SizedBox(width: 8),
                    if (w.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgvApproved.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ONLINE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.bgvApproved,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () =>
                ref.read(selectedWorkerIdProvider.notifier).select(null),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 1: Profile & BGV
// ═══════════════════════════════════════════════════════════════════

class _ProfileBgvTab extends ConsumerStatefulWidget {
  const _ProfileBgvTab({required this.worker});
  final Worker worker;

  @override
  ConsumerState<_ProfileBgvTab> createState() => _ProfileBgvTabState();
}

class _ProfileBgvTabState extends ConsumerState<_ProfileBgvTab> {
  late String _bgvStatus;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _bgvStatus = widget.worker.bgvStatus;
    _notesCtrl.text = widget.worker.bgvNotes ?? '';
  }

  @override
  void didUpdateWidget(covariant _ProfileBgvTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.worker.id != widget.worker.id) {
      _bgvStatus = widget.worker.bgvStatus;
      _notesCtrl.text = widget.worker.bgvNotes ?? '';
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal info
          _SectionLabel('Personal Information'),
          _InfoRow('Full Name', w.displayName),
          _InfoRow('Phone', w.profile?.phone ?? '-'),
          _InfoRow('Email', w.profile?.email ?? '-'),
          _InfoRow('City', w.city),
          _InfoRow('Experience', '${w.experienceYears} years'),
          if (w.bio != null && w.bio!.isNotEmpty) _InfoRow('Bio', w.bio!),
          _InfoRow(
            'Service Pincodes',
            w.servicePincodes.isNotEmpty
                ? w.servicePincodes.join(', ')
                : '-',
          ),
          _InfoRow(
            'Rating',
            '${w.rating.toStringAsFixed(1)} (${w.totalRatings} reviews)',
          ),
          _InfoRow('Jobs Completed', w.totalJobsCompleted.toString()),
          _InfoRow(
            'Joined',
            w.createdAt != null ? formatDate(w.createdAt!) : '-',
          ),
          const Divider(height: 24, color: AppColors.border),

          // Documents
          _SectionLabel('Verification Documents'),
          _DocRow(
            label: 'Aadhaar Number',
            value: w.aadhaarNumber ?? 'Not provided',
            docUrl: w.aadhaarDocUrl,
          ),
          _DocRow(
            label: 'Police Verification',
            value: w.policeVerificationUrl != null ? 'Uploaded' : 'Not uploaded',
            docUrl: w.policeVerificationUrl,
          ),
          if (w.skillCertificateUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Skill Certificates',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: w.skillCertificateUrls.asMap().entries.map((e) {
                return ActionChip(
                  label: Text('Certificate ${e.key + 1}'),
                  avatar:
                      const Icon(Icons.description_outlined, size: 14),
                  onPressed: () {
                    // Open URL in browser (placeholder).
                  },
                  labelStyle: const TextStyle(fontSize: 11),
                );
              }).toList(),
            ),
          ],
          const Divider(height: 24, color: AppColors.border),

          // BGV Decision Section
          _SectionLabel('BGV Decision'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _bgvStatus,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  items: const [
                    DropdownMenuItem(
                        value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(
                        value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _bgvStatus = v);
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add BGV notes...',
                    hintStyle: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveBgv,
                    style: FilledButton.styleFrom(
                      backgroundColor: _bgvStatus == 'approved'
                          ? AppColors.bgvApproved
                          : _bgvStatus == 'rejected'
                              ? AppColors.bgvRejected
                              : AppColors.primary,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save BGV Decision'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _saveBgv() async {
    setState(() => _saving = true);
    try {
      await ref.read(workerListProvider.notifier).updateBgvStatus(
            widget.worker.id,
            _bgvStatus,
            _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('BGV status updated to $_bgvStatus'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update BGV: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 2: Skills & Services
// ═══════════════════════════════════════════════════════════════════

class _SkillsTab extends StatelessWidget {
  const _SkillsTab({
    required this.worker,
    required this.serviceCategories,
  });
  final Worker worker;
  final List<dynamic> serviceCategories;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Service Categories'),
          const SizedBox(height: 8),
          Text(
            'Categories assigned to this worker. Toggle changes are not editable from admin.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...serviceCategories.map((cat) {
            final sc = cat as dynamic;
            final isAssigned = worker.serviceCategoryIds.contains(sc.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isAssigned
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isAssigned
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isAssigned
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: isAssigned
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sc.name as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isAssigned ? FontWeight.w600 : FontWeight.w400,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (sc.description != null &&
                            (sc.description as String).isNotEmpty)
                          Text(
                            sc.description as String,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    sc.priceLabel as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          _SectionLabel('Experience'),
          _InfoRow('Years', '${worker.experienceYears}'),
          _InfoRow(
            'Skill Certificates',
            '${worker.skillCertificateUrls.length} uploaded',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 3: Availability Calendar
// ═══════════════════════════════════════════════════════════════════

class _AvailabilityCalendarTab extends StatefulWidget {
  const _AvailabilityCalendarTab({required this.worker});
  final Worker worker;

  @override
  State<_AvailabilityCalendarTab> createState() =>
      _AvailabilityCalendarTabState();
}

class _AvailabilityCalendarTabState extends State<_AvailabilityCalendarTab> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1).weekday;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),

          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth + (firstWeekday - 1),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox.shrink();
              }
              final day = index - (firstWeekday - 1) + 1;
              final date =
                  DateTime(_selectedMonth.year, _selectedMonth.month, day);
              final isToday = _isToday(date);
              final isPast = date.isBefore(
                  DateTime(DateTime.now().year, DateTime.now().month,
                      DateTime.now().day));

              return Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : isPast
                          ? AppColors.background
                          : AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color:
                        isToday ? AppColors.primary : AppColors.border,
                    width: isToday ? 1.5 : 0.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isPast
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (!isPast && widget.worker.isAvailable)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.bgvApproved,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              _LegendDot(
                  color: AppColors.bgvApproved, label: 'Available'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: AppColors.textSecondary, label: 'Past'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.worker.isAvailable
                ? 'Worker is currently online and accepting bookings.'
                : 'Worker is currently offline.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            'Service Pincodes',
            widget.worker.servicePincodes.isNotEmpty
                ? widget.worker.servicePincodes.join(', ')
                : 'None configured',
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB 4: Booking History
// ═══════════════════════════════════════════════════════════════════

class _BookingHistoryTab extends ConsumerWidget {
  const _BookingHistoryTab({required this.workerId});
  final String workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookings = ref.watch(workerBookingsProvider(workerId));

    return asyncBookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (bookings) {
        var totalEarned = 0.0;
        var completed = 0;
        var cancelled = 0;

        for (final b in bookings) {
          if (b['status'] == 'completed') {
            completed++;
            totalEarned +=
                ((b['final_price'] as num?) ?? (b['quoted_price'] as num?) ?? 0)
                    .toDouble();
          }
          if (b['status'] == 'cancelled') cancelled++;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _MiniStat(
                      label: 'Total',
                      value: bookings.length.toString()),
                  const SizedBox(width: 16),
                  _MiniStat(
                      label: 'Completed',
                      value: completed.toString()),
                  const SizedBox(width: 16),
                  _MiniStat(
                    label: 'Earned',
                    value: formatINR(totalEarned),
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    label: 'Cancelled',
                    value: cancelled.toString(),
                    color: cancelled > 0 ? AppColors.error : null,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: bookings.isEmpty
                  ? const Center(
                      child: Text(
                        'No bookings yet',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.border),
                      itemBuilder: (_, i) {
                        final b = bookings[i];
                        final slotDate =
                            DateTime.tryParse(b['slot_date']?.toString() ?? '');
                        final customer =
                            b['customer'] as Map<String, dynamic>?;
                        final category =
                            b['service_categories'] as Map<String, dynamic>?;

                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Row(
                            children: [
                              Text(
                                '#${b['booking_number'] ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (category != null)
                                Flexible(
                                  child: Text(
                                    category['name']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            '${customer?['full_name'] ?? '-'} | ${slotDate != null ? formatDate(slotDate) : '-'} ${b['slot_start'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: _BookingStatusChip(
                              status: b['status']?.toString() ?? ''),
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

// ═══════════════════════════════════════════════════════════════════
// TAB 5: Payouts
// ═══════════════════════════════════════════════════════════════════

class _PayoutsTab extends ConsumerWidget {
  const _PayoutsTab({required this.workerId});
  final String workerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPayouts = ref.watch(workerPayoutsProvider(workerId));

    return asyncPayouts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.error)),
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
                    label: 'Total Earned',
                    value: _inr.format(data['totalEarned'] ?? 0),
                    color: AppColors.textPrimary,
                  ),
                  _PayoutStat(
                    label: 'Commission',
                    value: _inr.format(data['totalCommission'] ?? 0),
                    color: AppColors.secondary,
                  ),
                  _PayoutStat(
                    label: 'Net Paid',
                    value: _inr.format(data['totalPaid'] ?? 0),
                    color: AppColors.bgvApproved,
                  ),
                  _PayoutStat(
                    label: 'Pending',
                    value: _inr.format(data['pending'] ?? 0),
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
                                _inr.format(
                                    ((r['net_amount'] as num?) ?? 0)
                                        .toDouble()),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                paidAt != null
                                    ? _dateFmt.format(paidAt)
                                    : 'Pending',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _PayoutStatusChip(status: status),
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

// ═══════════════════════════════════════════════════════════════════
// Shared small widgets
// ═══════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
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

class _DocRow extends StatelessWidget {
  const _DocRow({
    required this.label,
    required this.value,
    this.docUrl,
  });
  final String label;
  final String value;
  final String? docUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
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
          if (docUrl != null && docUrl!.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                // Open document URL.
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 14),
              label: const Text('View', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
            ),
        ],
      ),
    );
  }
}

class _BgvBadge extends StatelessWidget {
  const _BgvBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => AppColors.bgvApproved,
      'rejected' => AppColors.bgvRejected,
      'in_progress' => AppColors.bgvInProgress,
      _ => AppColors.bgvPending,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.color,
  });
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

class _BookingStatusChip extends StatelessWidget {
  const _BookingStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'completed' => AppColors.statusCompleted,
      'cancelled' => AppColors.statusCancelled,
      'in_progress' => AppColors.statusInProgress,
      'assigned' => AppColors.statusAssigned,
      'disputed' => AppColors.statusDisputed,
      _ => AppColors.statusPending,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
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

class _PayoutStatusChip extends StatelessWidget {
  const _PayoutStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      'paid' => (
          AppColors.bgvApproved.withValues(alpha: 0.15),
          AppColors.bgvApproved
        ),
      'failed' => (
          AppColors.error.withValues(alpha: 0.15),
          AppColors.error
        ),
      'processing' => (
          AppColors.secondary.withValues(alpha: 0.15),
          AppColors.secondary
        ),
      _ => (
          AppColors.bgvPending.withValues(alpha: 0.15),
          AppColors.bgvPending
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
