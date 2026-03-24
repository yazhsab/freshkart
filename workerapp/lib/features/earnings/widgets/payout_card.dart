import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/models/payout_model.dart';
import 'package:freshkart_worker/core/utils/currency_util.dart';

class PayoutCard extends StatelessWidget {
  final PayoutModel payout;
  const PayoutCard({super.key, required this.payout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                payout.weekLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: payout.isPaid
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  payout.isPaid ? 'Paid' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: payout.isPaid ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _col('Jobs', '${payout.jobCount}'),
              _col('Gross', CurrencyUtil.format(payout.grossAmount)),
              _col('Net', CurrencyUtil.format(payout.netAmount)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _col(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
