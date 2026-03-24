import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:freshkart_customer/core/models/order_model.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/core/storage/local_storage.dart';
import 'package:freshkart_customer/features/cart/providers/cart_provider.dart';
import 'package:freshkart_customer/features/cart/providers/checkout_provider.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final PaymentMethod paymentMethod;

  const PaymentScreen({
    super.key,
    required this.order,
    required this.paymentMethod,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _initiatePayment();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    try {
      // Create Razorpay order on backend
      final checkoutNotifier = ref.read(checkoutProvider.notifier);
      final razorpayData = await checkoutNotifier.createRazorpayOrder(
        amount: widget.order.finalAmount,
        orderId: widget.order.id,
      );

      final razorpayOrderId = razorpayData['razorpay_order_id'] as String;
      final razorpayKey = razorpayData['key'] as String? ?? '';
      final phone = LocalStorage.getString(LocalStorage.kUserPhone) ?? '';

      final options = {
        'key': razorpayKey,
        'amount': (widget.order.finalAmount * 100).round(),
        'name': 'FreshKart',
        'description': 'Order #${widget.order.orderNumber}',
        'order_id': razorpayOrderId,
        'prefill': {'contact': phone},
        'theme': {'color': '#2E7D32'},
      };

      // Set preferred method based on payment selection
      if (widget.paymentMethod == PaymentMethod.upi) {
        options['prefill'] = {...options['prefill'] as Map, 'method': 'upi'};
      } else if (widget.paymentMethod == PaymentMethod.card) {
        options['prefill'] = {...options['prefill'] as Map, 'method': 'card'};
      }

      _razorpay.open(options);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to initiate payment: $e';
      });
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      final checkoutNotifier = ref.read(checkoutProvider.notifier);
      final order = await checkoutNotifier.verifyPayment(
        razorpayPaymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        razorpaySignature: response.signature ?? '',
        orderId: widget.order.id,
      );

      // Clear cart on successful payment
      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        context.go('/orders/${order.id}');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment verification failed: $e';
      });
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
      _errorMessage = response.message ?? 'Payment failed. Please try again.';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(
          response.message ?? 'Something went wrong with the payment.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop(); // Go back to checkout
            },
            child: const Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isProcessing = true;
                _errorMessage = null;
              });
              _initiatePayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'External wallet selected: ${response.walletName ?? "Unknown"}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text(
                  'Your order has been created. You can complete the payment later from order details.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Continue Payment'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/orders/${widget.order.id}');
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isProcessing) ...[
                const CircularProgressIndicator(color: AppColors.primaryGreen),
                const SizedBox(height: 24),
                const Text(
                  'Processing Payment...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #${widget.order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.order.finalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ] else if (_errorMessage != null) ...[
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                      ),
                      child: const Text('Go Back'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isProcessing = true;
                          _errorMessage = null;
                        });
                        _initiatePayment();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry Payment'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
