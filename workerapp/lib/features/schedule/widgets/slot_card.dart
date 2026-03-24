import 'package:flutter/material.dart';
import 'package:freshkart_worker/core/models/slot_model.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/shared/widgets/confirm_dialog.dart';

class SlotCard extends StatelessWidget {
  final SlotModel slot;
  final VoidCallback? onDelete;

  const SlotCard({super.key, required this.slot, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: slot.isBooked ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: slot.isBooked ? Colors.blue.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: slot.isBooked ? Colors.blue : WorkerColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.access_time,
            size: 18,
            color: slot.isBooked ? Colors.blue : WorkerColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              slot.timeLabel,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
            ),
          ),
          if (slot.isBooked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Booked',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (!slot.isPast)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              onPressed: () async {
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Delete Slot?',
                  message: 'Remove this availability slot?',
                  isDangerous: true,
                );
                if (confirmed) onDelete?.call();
              },
            ),
        ],
      ),
    );
  }
}
