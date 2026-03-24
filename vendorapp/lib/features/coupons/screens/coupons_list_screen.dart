import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:freshkart_vendor/features/coupons/providers/coupon_provider.dart';
import 'package:freshkart_vendor/features/coupons/screens/create_coupon_screen.dart';

class CouponsListScreen extends ConsumerWidget {
  const CouponsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateCouponScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Coupon'),
      ),
      body: couponsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(couponsProvider.notifier).fetchCoupons(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (coupons) {
          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No coupons yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first coupon',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(couponsProvider.notifier).fetchCoupons(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: coupons.length,
              itemBuilder: (context, index) {
                final coupon = coupons[index];
                return _CouponCard(coupon: coupon);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CouponCard extends ConsumerWidget {
  final CouponModel coupon;
  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final isExpired = coupon.isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.code,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(isExpired),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfo(
                  'Discount',
                  coupon.discountType == 'percentage'
                      ? '${coupon.discountValue.toInt()}%'
                      : '\u20B9${coupon.discountValue.toStringAsFixed(0)}',
                ),
                if (coupon.maxDiscount != null)
                  _buildInfo(
                    'Max Discount',
                    '\u20B9${coupon.maxDiscount!.toStringAsFixed(0)}',
                  ),
                if (coupon.minOrderAmount != null)
                  _buildInfo(
                    'Min Order',
                    '\u20B9${coupon.minOrderAmount!.toStringAsFixed(0)}',
                  ),
                _buildInfo('Used', '${coupon.usageCount}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Valid: ${dateFormat.format(coupon.validFrom)} - ${dateFormat.format(coupon.validUntil)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Switch(
                  value: coupon.isActive,
                  onChanged: isExpired
                      ? null
                      : (value) {
                          ref
                              .read(couponsProvider.notifier)
                              .toggleCouponStatus(coupon.id, value);
                        },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteDialog(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isExpired) {
    Color color;
    String label;

    if (isExpired) {
      color = Colors.red;
      label = 'Expired';
    } else if (coupon.isUpcoming) {
      color = Colors.orange;
      label = 'Upcoming';
    } else if (coupon.isActive) {
      color = Colors.green;
      label = 'Active';
    } else {
      color = Colors.grey;
      label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text('Are you sure you want to delete "${coupon.code}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(couponsProvider.notifier).deleteCoupon(coupon.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
