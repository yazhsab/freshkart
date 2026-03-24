import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/models/service_category_model.dart';
import 'package:freshkart_customer/features/services/providers/services_provider.dart';
import 'package:freshkart_customer/features/services/widgets/worker_card.dart';

class ServiceCategoryScreen extends ConsumerWidget {
  final String categoryId;

  const ServiceCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final workersAsync = ref.watch(workersProvider(categoryId));

    return categoriesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (categories) {
        final category = categories.firstWhere(
          (c) => c.id == categoryId,
          orElse: () => categories.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(category.name),
            backgroundColor: Colors.amber[700],
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Service info card
              _ServiceInfoCard(category: category),
              const SizedBox(height: 24),

              // Book Now button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/services/$categoryId/book');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Available workers section
              const Text(
                'Available Workers',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              workersAsync.when(
                loading: () => SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, __) => Container(
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Could not load workers: $e',
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
                data: (workers) {
                  if (workers.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No workers available at the moment.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: workers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 170,
                          child: WorkerCard(worker: workers[index]),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ServiceInfoCard extends StatelessWidget {
  final ServiceCategoryModel category;

  const _ServiceInfoCard({required this.category});

  IconData _iconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('plumb')) return Icons.plumbing;
    if (lower.contains('electric')) return Icons.electrical_services;
    if (lower.contains('clean')) return Icons.cleaning_services;
    if (lower.contains('paint')) return Icons.format_paint;
    if (lower.contains('carpenter') || lower.contains('wood')) {
      return Icons.carpenter;
    }
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit;
    if (lower.contains('pest')) return Icons.bug_report;
    if (lower.contains('garden') || lower.contains('lawn')) {
      return Icons.yard;
    }
    return Icons.build;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconForCategory(category.name),
                    size: 32,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (category.nameTamil != null)
                        Text(
                          category.nameTamil!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (category.description != null) ...[
              Text(
                category.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Divider(),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.currency_rupee,
                  label: 'From \u20B9${category.basePrice.toStringAsFixed(0)}',
                  color: Colors.amber[700]!,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.schedule,
                  label: '~${category.estimatedDurationMins} mins',
                  color: Colors.blue[600]!,
                ),
                const SizedBox(width: 12),
                _InfoChip(
                  icon: Icons.payments_outlined,
                  label: category.priceType,
                  color: Colors.green[600]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
