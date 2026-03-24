import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/features/profile/providers/profile_provider.dart';
import 'package:freshkart_worker/shared/widgets/empty_state_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(workerReviewsProvider);
    final profileAsync = ref.watch(workerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: reviewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reviews) {
          if (reviews.isEmpty)
            return const EmptyStateWidget(
              icon: Icons.star_outline,
              title: 'No reviews yet',
            );

          final avgRating = profileAsync.valueOrNull?.rating ?? 0;
          final starDist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
          for (final r in reviews) {
            final star = r.rating.round().clamp(1, 5);
            starDist[star] = (starDist[star] ?? 0) + 1;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < avgRating.round()
                                  ? Icons.star
                                  : Icons.star_outline,
                              size: 18,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                        Text(
                          '${reviews.length} reviews',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [5, 4, 3, 2, 1].map((star) {
                          final count = starDist[star] ?? 0;
                          final pct = reviews.isNotEmpty
                              ? count / reviews.length
                              : 0.0;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  '$star',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: pct,
                                      backgroundColor: Colors.grey.shade200,
                                      color: Colors.amber,
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...reviews.map(
                (r) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            r.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < r.rating.round()
                                  ? Icons.star
                                  : Icons.star_outline,
                              size: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      if (r.serviceName != null)
                        Text(
                          r.serviceName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      if (r.comment != null && r.comment!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(r.comment!),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(r.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
