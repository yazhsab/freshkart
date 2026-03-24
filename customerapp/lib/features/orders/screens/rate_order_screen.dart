import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/api/api_client.dart';
import 'package:freshkart_customer/core/api/api_endpoints.dart';
import 'package:freshkart_customer/core/models/order_model.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/orders/screens/order_detail_screen.dart';

class RateOrderScreen extends ConsumerStatefulWidget {
  final String orderId;
  const RateOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends ConsumerState<RateOrderScreen> {
  double _vendorRating = 0;
  double _deliveryRating = 0;
  final _commentController = TextEditingController();
  final Set<String> _vendorChips = {};
  final Set<String> _deliveryChips = {};
  bool _isSubmitting = false;

  static const _vendorFeedbackOptions = [
    'Fresh items',
    'Fast delivery',
    'Good packaging',
    'Helpful vendor',
  ];

  static const _deliveryFeedbackOptions = [
    'Quick delivery',
    'Professional',
    'Friendly',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit(OrderModel order) async {
    if (_vendorRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please rate the vendor')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ApiClient();

      // Submit vendor review
      await api.post(
        ApiEndpoints.reviews,
        data: {
          'target_id': order.vendorId,
          'target_type': 'vendor',
          'rating': _vendorRating.round(),
          'comment': _commentController.text.trim().isNotEmpty
              ? _commentController.text.trim()
              : null,
          'tags': _vendorChips.toList(),
          'order_id': widget.orderId,
        },
      );

      // Submit delivery review if rated
      if (_deliveryRating > 0 && order.deliveryAgentId != null) {
        await api.post(
          ApiEndpoints.reviews,
          data: {
            'target_id': order.deliveryAgentId,
            'target_type': 'delivery_agent',
            'rating': _deliveryRating.round(),
            'tags': _deliveryChips.toList(),
            'order_id': widget.orderId,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your review!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Rate Order')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (order) => _buildBody(order),
      ),
    );
  }

  Widget _buildBody(OrderModel order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          const Center(
            child: Text(
              'How was your order?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Your feedback helps us improve',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 28),

          // Vendor rating section
          _SectionCard(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.backgroundGreen,
                    child: const Icon(
                      Icons.store,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      order.vendor?.shopName ?? 'Vendor',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: RatingBar.builder(
                  initialRating: _vendorRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 5,
                  itemSize: 40,
                  unratedColor: AppColors.divider,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                  itemBuilder: (_, __) =>
                      const Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) =>
                      setState(() => _vendorRating = rating),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _vendorFeedbackOptions.map((chip) {
                  final selected = _vendorChips.contains(chip);
                  return FilterChip(
                    label: Text(chip),
                    selected: selected,
                    selectedColor: AppColors.backgroundGreen,
                    checkmarkColor: AppColors.primaryGreen,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryGreen
                          : AppColors.divider,
                    ),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _vendorChips.add(chip);
                        } else {
                          _vendorChips.remove(chip);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a comment (optional)',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Delivery rating section
          if (order.deliveryAgentId != null)
            _SectionCard(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryAmber.withOpacity(0.15),
                      child: const Icon(
                        Icons.delivery_dining,
                        color: AppColors.primaryAmber,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Delivery Partner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: RatingBar.builder(
                    initialRating: _deliveryRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 40,
                    unratedColor: AppColors.divider,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (_, __) =>
                        const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) =>
                        setState(() => _deliveryRating = rating),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _deliveryFeedbackOptions.map((chip) {
                    final selected = _deliveryChips.contains(chip);
                    return FilterChip(
                      label: Text(chip),
                      selected: selected,
                      selectedColor: AppColors.backgroundAmber,
                      checkmarkColor: AppColors.primaryAmber,
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primaryAmber
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primaryAmber
                            : AppColors.divider,
                      ),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _deliveryChips.add(chip);
                          } else {
                            _deliveryChips.remove(chip);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                disabledBackgroundColor: AppColors.primaryGreen.withOpacity(
                  0.5,
                ),
              ),
              onPressed: _isSubmitting ? null : () => _submit(order),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section card wrapper
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
