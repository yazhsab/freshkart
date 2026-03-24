import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/date_helpers.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/status_badge.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
        SectionHeader(
          title: 'Notifications',
          subtitle: 'Send and manage platform notifications',
        ),
        TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Send'),
            Tab(text: 'History'),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [
              _SendTab(),
              _HistoryTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Send tab ─────────────────────────────────────────────────────

class _SendTab extends ConsumerStatefulWidget {
  const _SendTab();

  @override
  ConsumerState<_SendTab> createState() => _SendTabState();
}

class _SendTabState extends ConsumerState<_SendTab> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _audience = 'all';
  String _channel = 'push';
  bool _sending = false;

  static const _maxTitleLen = 60;
  static const _maxBodyLen = 200;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reachAsync = ref.watch(reachEstimateProvider(_audience));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audience selector
                const Text('Audience',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                _AudienceOption(
                  value: 'all',
                  label: 'All Users',
                  subtitle: 'Customers, vendors, and workers',
                  icon: Icons.groups_outlined,
                  groupValue: _audience,
                  onChanged: (v) => setState(() => _audience = v!),
                ),
                _AudienceOption(
                  value: 'customers',
                  label: 'Customers Only',
                  subtitle: 'All active customers',
                  icon: Icons.person_outline,
                  groupValue: _audience,
                  onChanged: (v) => setState(() => _audience = v!),
                ),
                _AudienceOption(
                  value: 'vendors',
                  label: 'Vendors Only',
                  subtitle: 'All active vendors',
                  icon: Icons.store_outlined,
                  groupValue: _audience,
                  onChanged: (v) => setState(() => _audience = v!),
                ),
                _AudienceOption(
                  value: 'workers',
                  label: 'Workers Only',
                  subtitle: 'All active service workers',
                  icon: Icons.engineering_outlined,
                  groupValue: _audience,
                  onChanged: (v) => setState(() => _audience = v!),
                ),
                const SizedBox(height: 20),
                // Channel selector
                const Text('Channel',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'push',
                        label: Text('Push'),
                        icon: Icon(Icons.notifications_outlined, size: 18)),
                    ButtonSegment(
                        value: 'sms',
                        label: Text('SMS'),
                        icon: Icon(Icons.sms_outlined, size: 18)),
                    ButtonSegment(
                        value: 'both',
                        label: Text('Both'),
                        icon: Icon(Icons.campaign_outlined, size: 18)),
                  ],
                  selected: {_channel},
                  onSelectionChanged: (v) =>
                      setState(() => _channel = v.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    selectedForegroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                // Title field
                TextField(
                  controller: _titleCtrl,
                  maxLength: _maxTitleLen,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: const OutlineInputBorder(),
                    counterText:
                        '${_titleCtrl.text.length}/$_maxTitleLen',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Message field
                TextField(
                  controller: _bodyCtrl,
                  maxLength: _maxBodyLen,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    border: const OutlineInputBorder(),
                    counterText:
                        '${_bodyCtrl.text.length}/$_maxBodyLen',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                // Reach estimate
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Estimated reach: ',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      reachAsync.when(
                        loading: () => const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const Text('--'),
                        data: (count) => Text(
                          '$count users',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Send button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _canSend ? _send : null,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(_sending ? 'Sending...' : 'Send Notification'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // Preview mockup
          Expanded(
            flex: 2,
            child: _NotificationPreview(
              title: _titleCtrl.text,
              body: _bodyCtrl.text,
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSend =>
      !_sending &&
      _titleCtrl.text.trim().isNotEmpty &&
      _bodyCtrl.text.trim().isNotEmpty;

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref.read(notificationsProvider.notifier).sendNotification(
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            audience: _audience,
            channel: _channel,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Notification sent successfully'),
              backgroundColor: AppColors.primary),
        );
        _titleCtrl.clear();
        _bodyCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _AudienceOption extends StatelessWidget {
  const _AudienceOption({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.groupValue,
    required this.onChanged,
  });

  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RadioListTile<String>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        title: Row(
          children: [
            Icon(icon, size: 18,
                color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary)),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ),
        activeColor: AppColors.primary,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        tileColor: isSelected
            ? AppColors.primary.withValues(alpha: 0.04)
            : null,
      ),
    );
  }
}

// ── Android notification preview mockup ──────────────────────────

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preview',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        // Android notification mockup
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status bar mockup
              Row(
                children: [
                  const Text('9:41',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.signal_cellular_4_bar,
                      size: 14, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Icon(Icons.wifi,
                      size: 14, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Icon(Icons.battery_full,
                      size: 14, color: Colors.white.withValues(alpha: 0.7)),
                ],
              ),
              const SizedBox(height: 16),
              // Notification card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF424242),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Icon(Icons.shopping_basket,
                              size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text('FreshKart',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11)),
                        const Spacer(),
                        Text('now',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title.isNotEmpty ? title : 'Notification Title',
                      style: TextStyle(
                        color: title.isNotEmpty
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body.isNotEmpty ? body : 'Your message will appear here...',
                      style: TextStyle(
                        color: body.isNotEmpty
                            ? Colors.white.withValues(alpha: 0.8)
                            : Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── History tab ──────────────────────────────────────────────────

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(notificationsProvider);

    return asyncNotifications.when(
      loading: () => const LoadingShimmer(),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Failed to load history: $e'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const EmptyState(
            icon: Icons.history_outlined,
            title: 'No notifications sent yet',
            subtitle: 'Sent notifications will appear here.',
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: DataTable2(
            columnSpacing: 16,
            horizontalMargin: 12,
            minWidth: 800,
            headingRowHeight: 44,
            dataRowHeight: 56,
            headingRowColor: WidgetStateProperty.all(AppColors.background),
            columns: const [
              DataColumn2(label: Text('Title'), size: ColumnSize.L),
              DataColumn2(label: Text('Audience')),
              DataColumn2(label: Text('Channel')),
              DataColumn2(label: Text('Reach'), numeric: true),
              DataColumn2(label: Text('Status')),
              DataColumn2(label: Text('Sent At')),
            ],
            rows: entries.map((e) {
              return DataRow2(cells: [
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.title,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis),
                    Text(e.body,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                )),
                DataCell(_AudienceBadge(audience: e.audience)),
                DataCell(_ChannelIcon(channel: e.channel)),
                DataCell(Text(e.reachCount?.toString() ?? '--',
                    style: const TextStyle(fontSize: 12))),
                DataCell(StatusBadge(status: e.status)),
                DataCell(Text(
                    e.createdAt != null
                        ? formatDateTime(e.createdAt!)
                        : '--',
                    style: const TextStyle(fontSize: 12))),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}

class _AudienceBadge extends StatelessWidget {
  const _AudienceBadge({required this.audience});
  final String audience;

  @override
  Widget build(BuildContext context) {
    final label = switch (audience) {
      'all' => 'All Users',
      'customers' => 'Customers',
      'vendors' => 'Vendors',
      'workers' => 'Workers',
      _ => audience,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary)),
    );
  }
}

class _ChannelIcon extends StatelessWidget {
  const _ChannelIcon({required this.channel});
  final String channel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (channel == 'push' || channel == 'both')
          const Icon(Icons.notifications_outlined,
              size: 16, color: AppColors.textSecondary),
        if (channel == 'both') const SizedBox(width: 4),
        if (channel == 'sms' || channel == 'both')
          const Icon(Icons.sms_outlined,
              size: 16, color: AppColors.textSecondary),
      ],
    );
  }
}
