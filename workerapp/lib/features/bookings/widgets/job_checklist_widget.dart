import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';

class JobChecklistWidget extends StatelessWidget {
  final List<String> items;
  final List<bool> checked;
  final ValueChanged<int> onToggle;

  const JobChecklistWidget({
    super.key,
    required this.items,
    required this.checked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final completed = checked.where((c) => c).length;
    final total = items.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Service Checklist',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '$completed/$total',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            color: WorkerColors.primary,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          items.length,
          (i) => CheckboxListTile(
            value: checked[i],
            onChanged: (_) => onToggle(i),
            title: Text(
              items[i],
              style: TextStyle(
                decoration: checked[i] ? TextDecoration.lineThrough : null,
                color: checked[i] ? Colors.grey : Colors.black87,
              ),
            ),
            activeColor: WorkerColors.primary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
        ),
      ],
    );
  }
}
