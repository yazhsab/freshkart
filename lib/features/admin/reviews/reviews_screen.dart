import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../../core/constants/colors.dart';
import '../../../core/supabase/client.dart';
import '../../../core/utils/date_helpers.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/section_header.dart';
import '../shared/widgets/filter_chip_row.dart';

// ── Review filter ────────────────────────────────────────────────

final reviewFilterProvider =
    NotifierProvider<ReviewFilterNotifier, String>(ReviewFilterNotifier.new);

class ReviewFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String f) => state = f;
}

// ── Extended review model ────────────────────────────────────────

class ReviewRow {
  final String id;
  final String refType;
  final String refId;
  final String? customerId;
  final int rating;
  final String? comment;
  final bool isVisible;
  final bool isFlagged;
  final DateTime? createdAt;
  final String reviewerName;
  final String targetName;

  ReviewRow({
    required this.id,
    required this.refType,
    required this.refId,
    this.customerId,
    required this.rating,
    this.comment,
    required this.isVisible,
    required this.isFlagged,
    this.createdAt,
    required this.reviewerName,
    required this.targetName,
  });
}

// ── Reviews provider ─────────────────────────────────────────────

final reviewsProvider =
    AsyncNotifierProvider<ReviewsNotifier, List<ReviewRow>>(
  ReviewsNotifier.new,
);

class ReviewsNotifier extends AsyncNotifier<List<ReviewRow>> {
  @override
  Future<List<ReviewRow>> build() => _fetch();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<List<ReviewRow>> _fetch() async {
    final filter = ref.watch(reviewFilterProvider);

    var query = adminClient.from('reviews').select();

    // Apply server-side filters where possible
    switch (filter) {
      case 'Vendor Reviews':
        query = query.eq('ref_type', 'vendor');
      case 'Worker Reviews':
        query = query.eq('ref_type', 'worker');
      case 'Flagged':
        query = query.eq('is_flagged', true);
      case 'Hidden':
        query = query.eq('is_visible', false);
      default:
        break;
    }

    final rows =
        await query.order('created_at', ascending: false).limit(200);

    // Collect customer IDs and target IDs for name lookups
    final customerIds = <String>{};
    final vendorIds = <String>{};
    final workerIds = <String>{};

    for (final r in rows) {
      final cId = r['customer_id'] as String?;
      if (cId != null) customerIds.add(cId);
      final refType = r['ref_type'] as String;
      final refId = r['ref_id'] as String;
      if (refType == 'vendor') {
        vendorIds.add(refId);
      } else if (refType == 'worker') {
        workerIds.add(refId);
      }
    }

    // Fetch names in parallel
    final results = await Future.wait([
      customerIds.isNotEmpty
          ? adminClient
              .from('profiles')
              .select('id, full_name, phone')
              .inFilter('id', customerIds.toList())
          : Future.value(<Map<String, dynamic>>[]),
      vendorIds.isNotEmpty
          ? adminClient
              .from('vendors')
              .select('id, shop_name')
              .inFilter('id', vendorIds.toList())
          : Future.value(<Map<String, dynamic>>[]),
      workerIds.isNotEmpty
          ? adminClient
              .from('workers')
              .select('id, profiles(full_name, phone)')
              .inFilter('id', workerIds.toList())
          : Future.value(<Map<String, dynamic>>[]),
    ]);

    final customerMap = <String, String>{};
    for (final p in results[0]) {
      customerMap[p['id'] as String] =
          (p['full_name'] as String?)?.isNotEmpty == true
              ? p['full_name'] as String
              : p['phone'] as String? ?? 'Unknown';
    }

    final vendorMap = <String, String>{};
    for (final v in results[1]) {
      vendorMap[v['id'] as String] = v['shop_name'] as String? ?? 'Unknown';
    }

    final workerMap = <String, String>{};
    for (final w in results[2]) {
      final profile = w['profiles'] as Map<String, dynamic>?;
      workerMap[w['id'] as String] =
          (profile?['full_name'] as String?)?.isNotEmpty == true
              ? profile!['full_name'] as String
              : profile?['phone'] as String? ?? 'Unknown';
    }

    return rows.map((r) {
      final refType = r['ref_type'] as String;
      final refId = r['ref_id'] as String;
      String targetName;
      if (refType == 'vendor') {
        targetName = vendorMap[refId] ?? 'Unknown Vendor';
      } else if (refType == 'worker') {
        targetName = workerMap[refId] ?? 'Unknown Worker';
      } else {
        targetName = refId;
      }

      return ReviewRow(
        id: r['id'] as String,
        refType: refType,
        refId: refId,
        customerId: r['customer_id'] as String?,
        rating: r['rating'] as int? ?? 0,
        comment: r['comment'] as String?,
        isVisible: r['is_visible'] as bool? ?? true,
        isFlagged: r['is_flagged'] as bool? ?? false,
        createdAt: r['created_at'] != null
            ? DateTime.parse(r['created_at'] as String)
            : null,
        reviewerName: customerMap[r['customer_id'] as String? ?? ''] ??
            'Unknown',
        targetName: targetName,
      );
    }).toList();
  }

  Future<void> toggleVisibility(String reviewId, bool visible) async {
    await adminClient
        .from('reviews')
        .update({'is_visible': visible}).eq('id', reviewId);
    await refresh();
  }

  Future<void> toggleFlag(String reviewId, bool flagged) async {
    await adminClient
        .from('reviews')
        .update({'is_flagged': flagged}).eq('id', reviewId);
    await refresh();
  }
}

// ── Reviews Screen ───────────────────────────────────────────────

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reviewFilterProvider);
    final asyncReviews = ref.watch(reviewsProvider);

    return Column(
      children: [
        SectionHeader(
          title: 'Reviews',
          subtitle: 'Manage customer reviews and ratings',
          actions: [
            IconButton(
              onPressed: () =>
                  ref.read(reviewsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: 'Refresh',
            ),
          ],
        ),
        // Filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FilterChipRow(
            options: const [
              'All',
              'Vendor Reviews',
              'Worker Reviews',
              'Flagged',
              'Hidden',
            ],
            selected: filter,
            onSelected: (f) =>
                ref.read(reviewFilterProvider.notifier).set(f),
          ),
        ),
        const SizedBox(height: 12),
        // Table
        Expanded(
          child: asyncReviews.when(
            loading: () => const LoadingShimmer(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (reviews) {
              if (reviews.isEmpty) {
                return const EmptyState(
                  icon: Icons.rate_review_outlined,
                  title: 'No reviews found',
                  subtitle: 'Try adjusting your filter.',
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 8,
                  minWidth: 1000,
                  headingRowHeight: 44,
                  dataRowHeight: 64,
                  headingRowColor:
                      WidgetStateProperty.all(AppColors.background),
                  columns: const [
                    DataColumn2(label: Text('Reviewer'), size: ColumnSize.S),
                    DataColumn2(label: Text('Target'), size: ColumnSize.S),
                    DataColumn2(
                        label: Text('Type'), fixedWidth: 80),
                    DataColumn2(
                        label: Text('Rating'), fixedWidth: 100),
                    DataColumn2(
                        label: Text('Comment'), size: ColumnSize.L),
                    DataColumn2(label: Text('Date'), fixedWidth: 100),
                    DataColumn2(
                        label: Text('Visible'), fixedWidth: 70),
                    DataColumn2(
                        label: Text('Actions'), fixedWidth: 90),
                  ],
                  rows: reviews.map((r) {
                    return DataRow2(
                      color: r.isFlagged
                          ? WidgetStateProperty.all(
                              AppColors.error.withValues(alpha: 0.04))
                          : null,
                      cells: [
                        DataCell(Text(r.reviewerName,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                        DataCell(Text(r.targetName,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis)),
                        DataCell(_TypeBadge(type: r.refType)),
                        DataCell(_StarRating(rating: r.rating)),
                        DataCell(
                          Tooltip(
                            message: r.comment ?? '',
                            child: Text(
                              r.comment ?? '--',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(
                            r.createdAt != null
                                ? formatDate(r.createdAt!)
                                : '--',
                            style: const TextStyle(fontSize: 11))),
                        DataCell(
                          Switch(
                            value: r.isVisible,
                            onChanged: (v) => ref
                                .read(reviewsProvider.notifier)
                                .toggleVisibility(r.id, v),
                            activeColor: AppColors.primary,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => ref
                                    .read(reviewsProvider.notifier)
                                    .toggleFlag(r.id, !r.isFlagged),
                                icon: Icon(
                                  r.isFlagged
                                      ? Icons.flag_rounded
                                      : Icons.flag_outlined,
                                  size: 18,
                                  color: r.isFlagged
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                                tooltip: r.isFlagged ? 'Unflag' : 'Flag',
                                splashRadius: 18,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                              ),
                              if (!r.isVisible)
                                IconButton(
                                  onPressed: () => ref
                                      .read(reviewsProvider.notifier)
                                      .toggleVisibility(r.id, true),
                                  icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 18,
                                      color: AppColors.textSecondary),
                                  tooltip: 'Show',
                                  splashRadius: 18,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                ),
                              if (r.isVisible)
                                IconButton(
                                  onPressed: () => ref
                                      .read(reviewsProvider.notifier)
                                      .toggleVisibility(r.id, false),
                                  icon: const Icon(
                                      Icons.visibility_off_outlined,
                                      size: 18,
                                      color: AppColors.textSecondary),
                                  tooltip: 'Hide',
                                  splashRadius: 18,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Star rating widget ───────────────────────────────────────────

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 16,
          color: i < rating
              ? const Color(0xFFFFC107)
              : Colors.grey.shade300,
        );
      }),
    );
  }
}

// ── Type badge ───────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (type) {
      'vendor' => (AppColors.primary, 'Vendor'),
      'worker' => (AppColors.secondary, 'Worker'),
      _ => (AppColors.textSecondary, type),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
