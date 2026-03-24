import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/utils/date_helpers.dart';
import 'agents_provider.dart';

class LiveMapWidget extends ConsumerWidget {
  const LiveMapWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(agentLocationsStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Map placeholder
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined,
                    size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Live Map - Ola Maps Integration',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'To enable the live map, configure Ola Maps SDK with your API key.\n'
                    'Add the ola_maps_flutter package and set OLA_MAPS_API_KEY '
                    'in your environment variables.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Agent locations table
          const Text(
            'Agent Locations (Real-time)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          locationsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Failed to load locations: $e',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            data: (locations) {
              if (locations.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No agent location data available.\n'
                      'Agents will appear here once they start sharing their location.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              return Container(
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
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 48,
                    columnSpacing: 32,
                    columns: const [
                      DataColumn(label: Text('Agent')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Latitude')),
                      DataColumn(label: Text('Longitude')),
                      DataColumn(label: Text('Last Updated')),
                    ],
                    rows: locations.map((loc) {
                      return DataRow(cells: [
                        DataCell(Text(
                          loc.agentName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: loc.isOnline
                                      ? AppColors.statusDelivered
                                      : AppColors.statusPending,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                loc.isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: loc.isOnline
                                      ? AppColors.statusDelivered
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(
                          loc.lat.toStringAsFixed(6),
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        )),
                        DataCell(Text(
                          loc.lng.toStringAsFixed(6),
                          style: const TextStyle(
                              fontSize: 12, fontFamily: 'monospace'),
                        )),
                        DataCell(Text(
                          loc.updatedAt != null
                              ? timeAgoStr(loc.updatedAt!)
                              : '--',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
