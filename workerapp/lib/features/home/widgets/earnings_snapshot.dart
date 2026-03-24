import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/currency_util.dart';

class EarningsSnapshot extends StatelessWidget {
  final double todayEarnings;
  final double weekEarnings;

  const EarningsSnapshot({
    super.key,
    required this.todayEarnings,
    required this.weekEarnings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EarningTile(
            label: 'Today',
            amount: todayEarnings,
            icon: Icons.today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _EarningTile(
            label: 'This Week',
            amount: weekEarnings,
            icon: Icons.date_range,
          ),
        ),
      ],
    );
  }
}

class _EarningTile extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;

  const _EarningTile({
    required this.label,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WorkerColors.earningsGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WorkerColors.earningsGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: WorkerColors.earningsGreen),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyUtil.format(amount),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
