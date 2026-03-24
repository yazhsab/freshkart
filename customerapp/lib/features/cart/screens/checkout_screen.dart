import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:freshkart_customer/core/config/app_config.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/cart/providers/cart_provider.dart';
import 'package:freshkart_customer/features/cart/providers/address_provider.dart';
import 'package:freshkart_customer/features/cart/providers/checkout_provider.dart';
import 'package:freshkart_customer/features/cart/widgets/price_summary_card.dart';
import 'package:freshkart_customer/features/coupon/providers/coupon_provider.dart';
import 'package:freshkart_customer/features/wallet/providers/wallet_provider.dart';
import 'package:freshkart_customer/features/loyalty/providers/loyalty_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String? specialInstructions;

  const CheckoutScreen({super.key, this.specialInstructions});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Reset checkout state when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutProvider.notifier).reset();
      ref.read(walletProvider.notifier).fetchWallet();
      ref.read(loyaltyProvider.notifier).fetchLoyalty();
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cartState = ref.read(cartProvider);
    final address = ref.read(selectedAddressProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final checkoutState = ref.read(checkoutProvider);

    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    try {
      final order = await checkoutNotifier.createOrder(
        cartState: cartState,
        address: address,
        paymentMethod: checkoutState.selectedPaymentMethod,
        specialInstructions: widget.specialInstructions,
        couponCode: checkoutState.couponCode,
        walletAmount: checkoutState.walletAmount,
        loyaltyPoints: checkoutState.loyaltyPoints,
        scheduledAt: checkoutState.scheduledAt,
      );

      if (checkoutState.selectedPaymentMethod == PaymentMethod.cod) {
        // COD: clear cart and go to order detail
        ref.read(cartProvider.notifier).clearCart();
        if (mounted) {
          context.go('/orders/${order.id}');
        }
      } else {
        // UPI/Card: navigate to payment screen
        if (mounted) {
          context.push(
            '/payment',
            extra: {
              'order': order,
              'paymentMethod': checkoutState.selectedPaymentMethod,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final minDate = now.add(
      const Duration(hours: AppConfig.minScheduleHoursAhead),
    );
    final maxDate = now.add(
      const Duration(days: AppConfig.maxScheduleDaysAhead),
    );

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(minDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryGreen,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) return;

    final scheduledAt = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (scheduledAt.isBefore(minDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a time at least ${AppConfig.minScheduleHoursAhead} hours from now',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ref.read(checkoutProvider.notifier).setScheduledAt(scheduledAt);
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final couponState = ref.watch(couponProvider);
    final walletState = ref.watch(walletProvider);
    final loyaltyState = ref.watch(loyaltyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Vendor & items summary
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.store,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cartState.vendorName ?? 'Vendor',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      ...cartState.itemsList.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.product.name} x${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Text(
                                '${AppConfig.currencySymbol}${item.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery address
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Delivery Address',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => context.push('/addresses'),
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (selectedAddress != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            '${selectedAddress.flatNo}, ${selectedAddress.area}, ${selectedAddress.city} - ${selectedAddress.pincode}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: TextButton(
                            onPressed: () => context.push('/addresses'),
                            child: const Text('Select address'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Payment method selector
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PaymentOptionTile(
                        icon: Icons.account_balance,
                        title: 'UPI',
                        subtitle: 'Google Pay, PhonePe, etc.',
                        isSelected:
                            checkoutState.selectedPaymentMethod ==
                            PaymentMethod.upi,
                        onTap: () => ref
                            .read(checkoutProvider.notifier)
                            .setPaymentMethod(PaymentMethod.upi),
                      ),
                      const SizedBox(height: 8),
                      _PaymentOptionTile(
                        icon: Icons.credit_card,
                        title: 'Credit/Debit Card',
                        subtitle: 'Visa, Mastercard, RuPay',
                        isSelected:
                            checkoutState.selectedPaymentMethod ==
                            PaymentMethod.card,
                        onTap: () => ref
                            .read(checkoutProvider.notifier)
                            .setPaymentMethod(PaymentMethod.card),
                      ),
                      const SizedBox(height: 8),
                      _PaymentOptionTile(
                        icon: Icons.money,
                        title: 'Cash on Delivery',
                        subtitle: 'Pay when your order arrives',
                        isSelected:
                            checkoutState.selectedPaymentMethod ==
                            PaymentMethod.cod,
                        onTap: () => ref
                            .read(checkoutProvider.notifier)
                            .setPaymentMethod(PaymentMethod.cod),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Coupon section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Apply Coupon',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (couponState.appliedCoupon != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundGreen,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryGreen),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 20,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      couponState.appliedCoupon!.code,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                    if (couponState.discountAmount != null)
                                      Text(
                                        'You save ${AppConfig.currencySymbol}${couponState.discountAmount!.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  ref.read(couponProvider.notifier).removeCoupon();
                                  ref.read(checkoutProvider.notifier).setCouponCode(null);
                                  _couponController.clear();
                                },
                                icon: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _couponController,
                                decoration: InputDecoration(
                                  hintText: 'Enter coupon code',
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textHint,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.divider,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                  isDense: true,
                                ),
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: couponState.isLoading
                                    ? null
                                    : () async {
                                        final code = _couponController.text.trim();
                                        if (code.isEmpty) return;
                                        final success = await ref
                                            .read(couponProvider.notifier)
                                            .applyCoupon(
                                              code,
                                              cartState.subtotal,
                                              cartState.vendorId ?? '',
                                            );
                                        if (success) {
                                          ref
                                              .read(checkoutProvider.notifier)
                                              .setCouponCode(code);
                                        } else if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                couponState.error ?? 'Invalid coupon',
                                              ),
                                              backgroundColor: AppColors.error,
                                            ),
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                                child: couponState.isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Apply',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Wallet payment section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Use Wallet Balance',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Switch(
                            value: checkoutState.useWallet,
                            onChanged: (value) {
                              final balance = walletState.wallet?.balance ?? 0;
                              final orderTotal = cartState.total;
                              final amount = balance > orderTotal ? orderTotal : balance;
                              ref
                                  .read(checkoutProvider.notifier)
                                  .setUseWallet(value, amount: amount);
                            },
                            activeColor: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 28),
                        child: Text(
                          'Available balance: ${AppConfig.currencySymbol}${(walletState.wallet?.balance ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (checkoutState.useWallet && checkoutState.walletAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 28, top: 4),
                          child: Text(
                            '${AppConfig.currencySymbol}${checkoutState.walletAmount.toStringAsFixed(2)} will be deducted from wallet',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Loyalty points section
                if (loyaltyState.loyalty != null &&
                    loyaltyState.loyalty!.currentBalance >= AppConfig.minRedeemPoints)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.stars_outlined,
                              size: 20,
                              color: AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Redeem Loyalty Points',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Text(
                            'Available: ${loyaltyState.loyalty!.currentBalance} points',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Text(
                                '0',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                              Expanded(
                                child: Slider(
                                  value: checkoutState.loyaltyPoints.toDouble(),
                                  min: 0,
                                  max: loyaltyState.loyalty!.currentBalance.toDouble(),
                                  divisions: loyaltyState.loyalty!.currentBalance > 0
                                      ? loyaltyState.loyalty!.currentBalance
                                      : 1,
                                  activeColor: AppColors.primaryGreen,
                                  inactiveColor: AppColors.divider,
                                  label: '${checkoutState.loyaltyPoints} pts',
                                  onChanged: (value) {
                                    ref
                                        .read(checkoutProvider.notifier)
                                        .setLoyaltyPoints(value.round());
                                  },
                                ),
                              ),
                              Text(
                                '${loyaltyState.loyalty!.currentBalance}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (checkoutState.loyaltyPoints > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 28),
                            child: Text(
                              '${checkoutState.loyaltyPoints} points = ${AppConfig.currencySymbol}${(checkoutState.loyaltyPoints * AppConfig.pointValueInr).toStringAsFixed(0)} discount',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (loyaltyState.loyalty != null &&
                    loyaltyState.loyalty!.currentBalance >= AppConfig.minRedeemPoints)
                  const SizedBox(height: 16),

                // Schedule order section
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 20,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Schedule for Later',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Switch(
                            value: checkoutState.isScheduled,
                            onChanged: (value) {
                              ref.read(checkoutProvider.notifier).setScheduled(value);
                              if (value && checkoutState.scheduledAt == null) {
                                _pickScheduleDateTime();
                              }
                            },
                            activeColor: AppColors.primaryGreen,
                          ),
                        ],
                      ),
                      if (checkoutState.isScheduled) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickScheduleDateTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.divider),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    checkoutState.scheduledAt != null
                                        ? DateFormat('EEE, dd MMM yyyy – hh:mm a')
                                            .format(checkoutState.scheduledAt!)
                                        : 'Select date & time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: checkoutState.scheduledAt != null
                                          ? AppColors.textPrimary
                                          : AppColors.textHint,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Price breakdown
                PriceSummaryCard(
                  subtotal: cartState.subtotal,
                  deliveryFee: cartState.deliveryFee,
                  total: cartState.total,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // Place order button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      checkoutState.isProcessing || selectedAddress == null
                      ? null
                      : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.divider,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: checkoutState.isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Place Order ${AppConfig.currencySymbol}${cartState.total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? AppColors.backgroundGreen : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AppColors.primaryGreen
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primaryGreen : AppColors.textHint,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
