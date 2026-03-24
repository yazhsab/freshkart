import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/coupon/providers/coupon_provider.dart';

class AvailableCouponsScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final double subtotal;

  const AvailableCouponsScreen({
    super.key,
    required this.vendorId,
    required this.subtotal,
  });

  @override
  ConsumerState<AvailableCouponsScreen> createState() => _AvailableCouponsScreenState();
}

class _AvailableCouponsScreenState extends ConsumerState<AvailableCouponsScreen> {
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(couponProvider.notifier).fetchCoupons(vendorId: widget.vendorId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(couponProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Available Coupons')),
      body: Column(
        children: [
          // Manual code input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter coupon code',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (_codeController.text.isNotEmpty) {
                      final success = await ref.read(couponProvider.notifier)
                          .applyCoupon(_codeController.text, widget.subtotal, widget.vendorId);
                      if (success && mounted) Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Coupon list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.coupons.isEmpty
                    ? const Center(child: Text('No coupons available'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.coupons.length,
                        itemBuilder: (context, index) {
                          final coupon = state.coupons[index];
                          final isEligible = widget.subtotal >= coupon.minOrderAmount;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: isEligible
                                  ? () async {
                                      final success = await ref.read(couponProvider.notifier)
                                          .applyCoupon(coupon.code, widget.subtotal, widget.vendorId);
                                      if (success && mounted) Navigator.pop(context, true);
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isEligible ? AppColors.primaryGreen : Colors.grey,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        coupon.discountLabel,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 1)),
                                          const SizedBox(height: 4),
                                          Text(coupon.title, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                          if (!isEligible)
                                            Text(
                                              'Min. order ₹${coupon.minOrderAmount.toInt()}',
                                              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isEligible)
                                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
