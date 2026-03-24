import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/currency_util.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';

class PaymentCollectionWidget extends StatelessWidget {
  final double amount;
  final String paymentMethod;
  final bool isCollected;
  final VoidCallback? onCollected;

  const PaymentCollectionWidget({
    super.key,
    required this.amount,
    required this.paymentMethod,
    this.isCollected = false,
    this.onCollected,
  });

  @override
  Widget build(BuildContext context) {
    final isCod = paymentMethod == 'cod';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCollected
            ? Colors.green.shade50
            : (isCod
                  ? WorkerColors.primary.withValues(alpha: 0.05)
                  : Colors.blue.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCollected
              ? Colors.green.shade200
              : (isCod
                    ? WorkerColors.primary.withValues(alpha: 0.2)
                    : Colors.blue.shade200),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isCollected
                ? Icons.check_circle
                : (isCod ? Icons.payments : Icons.credit_card),
            size: 40,
            color: isCollected
                ? Colors.green
                : (isCod ? WorkerColors.primary : Colors.blue),
          ),
          const SizedBox(height: 12),
          Text(
            isCollected
                ? 'Payment Collected'
                : (isCod ? 'Collect Cash Payment' : 'Online Payment'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyUtil.format(amount),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            isCod ? 'Cash on Delivery' : 'Paid Online',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (!isCollected && isCod) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Mark as Collected',
              icon: Icons.check,
              onPressed: onCollected,
            ),
          ],
        ],
      ),
    );
  }
}
