import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/section_header.dart';
import 'agents_provider.dart';
import 'live_map_widget.dart';

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onlineCount = ref.watch(onlineAgentCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          SectionHeader(
            title: 'Delivery Agents',
            subtitle: '$onlineCount online now',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(agentsProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(7),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textPrimary,
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w400),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Agents List'),
                Tab(text: 'Live Map'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AgentsListTab(),
                LiveMapWidget(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Agents List Tab ─────────────────────────────────────────────

class _AgentsListTab extends ConsumerWidget {
  const _AgentsListTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsProvider);

    return agentsAsync.when(
      loading: () => const LoadingShimmer(),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Error: $e'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(agentsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (agents) {
        if (agents.isEmpty) {
          return const EmptyState(
            icon: Icons.delivery_dining_outlined,
            title: 'No delivery agents',
            subtitle: 'Delivery agents will appear here once registered',
          );
        }

        final onlineCount = agents.where((a) => a.isOnline).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary row
              Row(
                children: [
                  _summaryChip(
                    'Total',
                    '${agents.length}',
                    Icons.people_outline,
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _summaryChip(
                    'Online',
                    '$onlineCount',
                    Icons.circle,
                    AppColors.statusDelivered,
                  ),
                  const SizedBox(width: 12),
                  _summaryChip(
                    'Offline',
                    '${agents.length - onlineCount}',
                    Icons.circle_outlined,
                    AppColors.statusPending,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Data table
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(AppColors.background),
                    headingRowHeight: 44,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 56,
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Agent')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Current Order')),
                      DataColumn(
                          label: Text('Today'),
                          numeric: true),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: agents.map((agent) {
                      final p = agent.profile;
                      return DataRow(cells: [
                        // Avatar + Name
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                backgroundImage: p.avatarUrl != null
                                    ? NetworkImage(p.avatarUrl!)
                                    : null,
                                child: p.avatarUrl == null
                                    ? Text(
                                        p.initials,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                p.displayName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Phone
                        DataCell(Text(
                          p.phone,
                          style: const TextStyle(fontSize: 13),
                        )),
                        // Online dot
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: agent.isOnline
                                      ? AppColors.statusDelivered
                                      : AppColors.statusPending,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                agent.isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: agent.isOnline
                                      ? AppColors.statusDelivered
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Current Order
                        DataCell(
                          agent.currentOrderNumber != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.statusPickedUp
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '#${agent.currentOrderNumber}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.statusPickedUp,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Free',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        ),
                        // Today deliveries
                        DataCell(Text(
                          '${agent.todayDeliveries}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                        // Actions
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _AgentToggleButton(agent: agent),
                              if (agent.currentOrderId != null) ...[
                                const SizedBox(width: 4),
                                _UnassignButton(
                                    orderId: agent.currentOrderId!),
                              ],
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryChip(
      String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle Button ───────────────────────────────────────────────

class _AgentToggleButton extends ConsumerWidget {
  const _AgentToggleButton({required this.agent});
  final DeliveryAgent agent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        agent.isOnline
            ? Icons.toggle_on_outlined
            : Icons.toggle_off_outlined,
        size: 28,
        color: agent.isOnline ? AppColors.primary : AppColors.textSecondary,
      ),
      tooltip: agent.isOnline ? 'Deactivate' : 'Activate',
      onPressed: () async {
        try {
          await ref
              .read(agentActionsProvider.notifier)
              .toggleAgentActive(agent.profile.id, !agent.isOnline);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error),
            );
          }
        }
      },
    );
  }
}

// ── Unassign Button ─────────────────────────────────────────────

class _UnassignButton extends ConsumerWidget {
  const _UnassignButton({required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.cancel_outlined, size: 20),
      tooltip: 'Unassign order',
      color: AppColors.error,
      onPressed: () async {
        try {
          await ref
              .read(agentActionsProvider.notifier)
              .unassignCurrentOrder(orderId);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order unassigned')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.error),
            );
          }
        }
      },
    );
  }
}
