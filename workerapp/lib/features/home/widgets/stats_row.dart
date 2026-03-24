import 'package:flutter/material.dart';

class StatsRow extends StatelessWidget {
  final double rating;
  final int totalJobs;
  final int experience;

  const StatsRow({
    super.key,
    required this.rating,
    required this.totalJobs,
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          icon: Icons.star,
          value: rating.toStringAsFixed(1),
          label: 'Rating',
          color: Colors.amber,
        ),
        _StatItem(
          icon: Icons.check_circle,
          value: '$totalJobs',
          label: 'Jobs',
          color: Colors.green,
        ),
        _StatItem(
          icon: Icons.work_history,
          value: '${experience}yr',
          label: 'Exp',
          color: Colors.blue,
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
