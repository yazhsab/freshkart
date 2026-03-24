import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/service_category.dart';
import '../../../core/utils/currency.dart';
import '../shared/widgets/confirm_dialog.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/section_header.dart';
import 'add_edit_service_dialog.dart';
import 'service_catalog_provider.dart';

class ServiceCatalogScreen extends ConsumerWidget {
  const ServiceCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(serviceCatalogProvider);
    final showOnlyActive = ref.watch(showOnlyActiveServicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header
          SectionHeader(
            title: 'Service Catalog',
            subtitle: 'Manage home services offered on the platform',
            actions: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Active only',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Switch(
                    value: showOnlyActive,
                    onChanged: (_) => ref
                        .read(showOnlyActiveServicesProvider.notifier)
                        .toggle(),
                    activeColor: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(context, ref, null),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Content
          Expanded(
            child: servicesAsync.when(
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
                      onPressed: () => ref.invalidate(serviceCatalogProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (services) {
                if (services.isEmpty) {
                  return const EmptyState(
                    icon: Icons.home_repair_service_outlined,
                    title: 'No services found',
                    subtitle: 'Add your first service to get started',
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Grid of service cards
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount =
                              constraints.maxWidth > 800 ? 2 : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio:
                                  crossAxisCount == 2 ? 2.4 : 3.0,
                            ),
                            itemCount: services.length,
                            itemBuilder: (context, index) =>
                                _ServiceCard(
                              service: services[index],
                              onEdit: () => _showAddEditDialog(
                                  context, ref, services[index]),
                              onDelete: () => _confirmDelete(
                                  context, ref, services[index]),
                              onToggle: (active) => ref
                                  .read(serviceCatalogActionsProvider.notifier)
                                  .toggleService(services[index].id, active),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Workers per service section
                      const Text(
                        'Workers per Service',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Workers assigned to each service category',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...services.map((service) => _WorkersPerServiceTile(
                            service: service,
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(
      BuildContext context, WidgetRef ref, ServiceCategory? service) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditServiceDialog(service: service),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, ServiceCategory service) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Service',
      message:
          'Are you sure you want to delete "${service.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.error,
    );
    if (confirmed == true) {
      try {
        await ref
            .read(serviceCatalogActionsProvider.notifier)
            .deleteService(service.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Service deleted')),
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
    }
  }
}

// ── Service Card ────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final ServiceCategory service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  IconData get _serviceIcon {
    final name = service.name.toLowerCase();
    if (name.contains('plumb')) return Icons.plumbing;
    if (name.contains('electric')) return Icons.electrical_services;
    if (name.contains('clean')) return Icons.cleaning_services;
    if (name.contains('paint')) return Icons.format_paint;
    if (name.contains('ac') || name.contains('air')) return Icons.ac_unit;
    if (name.contains('carpent')) return Icons.carpenter;
    if (name.contains('pest')) return Icons.pest_control;
    if (name.contains('appliance')) return Icons.kitchen;
    return Icons.home_repair_service;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: service.isActive ? AppColors.border : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_serviceIcon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (service.nameTamil != null &&
                    service.nameTamil!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    service.nameTamil!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    _chip(service.priceLabel, Icons.currency_rupee, 11),
                    const SizedBox(width: 8),
                    _chip(service.durationLabel, Icons.schedule, 11),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Switch(
                value: service.isActive,
                onChanged: onToggle,
                activeColor: AppColors.primary,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onEdit,
                    tooltip: 'Edit',
                    visualDensity: VisualDensity.compact,
                    color: AppColors.textSecondary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    visualDensity: VisualDensity.compact,
                    color: AppColors.error,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Workers per service tile ────────────────────────────────────

class _WorkersPerServiceTile extends ConsumerWidget {
  const _WorkersPerServiceTile({required this.service});

  final ServiceCategory service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(workersPerServiceProvider(service.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              workersAsync.when(
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text(
                  'Error',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
                data: (workers) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${workers.length} worker${workers.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          workersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Failed to load workers: $e',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
            data: (workers) {
              if (workers.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'No workers assigned to this service yet',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: workers.map((worker) {
                    final name = worker.displayName;
                    final approved = worker.isApproved;
                    return Chip(
                      avatar: CircleAvatar(
                        radius: 14,
                        backgroundColor: approved
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.statusPending.withValues(alpha: 0.15),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: approved
                                ? AppColors.primary
                                : AppColors.statusPending,
                          ),
                        ),
                      ),
                      label: Text(
                        name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
