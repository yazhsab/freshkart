import 'package:flutter/material.dart';

import '../../../../core/constants/colors.dart';
import '../../../../core/utils/date_helpers.dart';

/// Displays a scrollable list of recent activity items.
/// Each item has a colored dot by type, text description, and a timeAgo stamp.
///
/// Color mapping:
///   green  = order
///   amber  = booking
///   blue   = payment
///   red    = alert
class ActivityFeed extends StatelessWidget {
  const ActivityFeed({
    super.key,
    required this.activityItems,
  });

  final List<Map<String, dynamic>> activityItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.timeline_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          // Items
          if (activityItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activityItems.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, index) =>
                  _ActivityRow(data: activityItems[index]),
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final type = data['type']?.toString() ?? '';
    final dotColor = _dotColorForType(type);
    final title = data['title']?.toString() ?? 'Activity';
    final body = data['body']?.toString() ?? '';
    final sentAt = DateTime.tryParse(data['sent_at']?.toString() ?? '');
    final timeAgo = sentAt != null ? timeAgoStr(sentAt) : '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Time ago
          Text(
            timeAgo,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _dotColorForType(String type) {
    switch (type) {
      case 'order':
        return AppColors.primary; // green
      case 'booking':
        return AppColors.secondary; // amber
      case 'payment':
        return AppColors.statusConfirmed; // blue
      case 'alert':
        return AppColors.error; // red
      default:
        return AppColors.textSecondary;
    }
  }
}
