import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_customer/core/models/service_category_model.dart';
import 'package:freshkart_customer/features/services/providers/services_provider.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final String categoryId;

  const ServiceDetailScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);

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
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
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
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hero image / icon section
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[100]!, Colors.amber[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    _iconForCategory(category.name),
                    size: 80,
                    color: Colors.amber[800],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title and Tamil name
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (category.nameTamil != null) ...[
                const SizedBox(height: 4),
                Text(
                  category.nameTamil!,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 16),

              // Description
              if (category.description != null) ...[
                Text(
                  category.description!,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Pricing breakdown card
              _SectionCard(
                title: 'Pricing',
                child: Column(
                  children: [
                    _PricingRow(
                      label: 'Service charge',
                      value:
                          'From \u20B9${category.basePrice.toStringAsFixed(0)}',
                      isHighlighted: true,
                    ),
                    const Divider(height: 24),
                    const _PricingRow(label: 'Booking fee', value: '\u20B999'),
                    const Divider(height: 24),
                    _PricingRow(
                      label: 'Price type',
                      value: category.priceType == 'fixed'
                          ? 'Fixed price'
                          : 'Per hour',
                    ),
                    const Divider(height: 24),
                    _PricingRow(
                      label: 'Estimated duration',
                      value: '${category.estimatedDurationMins} minutes',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // What's included card
              _SectionCard(
                title: "What's included",
                child: Column(
                  children: [
                    _IncludedItem(
                      icon: Icons.verified_user,
                      text: 'Verified & background-checked professionals',
                    ),
                    const SizedBox(height: 12),
                    _IncludedItem(
                      icon: Icons.schedule,
                      text: 'On-time arrival guarantee',
                    ),
                    const SizedBox(height: 12),
                    _IncludedItem(
                      icon: Icons.star,
                      text: 'Rated & reviewed workers',
                    ),
                    const SizedBox(height: 12),
                    _IncludedItem(
                      icon: Icons.support_agent,
                      text: '24/7 customer support',
                    ),
                    const SizedBox(height: 12),
                    _IncludedItem(
                      icon: Icons.shield_outlined,
                      text: 'Service quality guarantee',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reviews section
              _SectionCard(
                title: 'Customer Reviews',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[700], size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '4.5',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(120+ reviews)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ReviewItem(
                      name: 'Customer',
                      rating: 5,
                      comment: 'Excellent service, very professional!',
                      date: 'Recent',
                    ),
                    const SizedBox(height: 12),
                    _ReviewItem(
                      name: 'Customer',
                      rating: 4,
                      comment: 'Good work, arrived on time.',
                      date: 'Recent',
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        // TODO: Navigate to all reviews
                      },
                      child: Text(
                        'View all reviews',
                        style: TextStyle(color: Colors.amber[700]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // Space for bottom button
            ],
          ),
        );
      },
    );
  }

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
    if (lower.contains('garden') || lower.contains('lawn')) return Icons.yard;
    return Icons.build;
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _PricingRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _PricingRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            color: isHighlighted ? Colors.amber[700] : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _IncludedItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IncludedItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green[600]),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String name;
  final int rating;
  final String comment;
  final String date;

  const _ReviewItem({
    required this.name,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                date,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating ? Icons.star : Icons.star_border,
                size: 16,
                color: Colors.amber[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
