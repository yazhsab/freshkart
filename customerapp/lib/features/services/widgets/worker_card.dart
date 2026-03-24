import 'package:flutter/material.dart';

import 'package:freshkart_customer/core/models/worker_model.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;

  const WorkerCard({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey[300],
              child: worker.profile?.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        worker.profile!.avatarUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              worker.profile?.fullName ?? 'Worker',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),

            // Rating stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (i) {
                  final starValue = i + 1;
                  if (worker.rating >= starValue) {
                    return Icon(Icons.star, size: 14, color: Colors.amber[600]);
                  } else if (worker.rating >= starValue - 0.5) {
                    return Icon(
                      Icons.star_half,
                      size: 14,
                      color: Colors.amber[600],
                    );
                  }
                  return Icon(
                    Icons.star_border,
                    size: 14,
                    color: Colors.amber[600],
                  );
                }),
                const SizedBox(width: 4),
                Text('${worker.rating}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 6),

            // Experience & jobs
            Text(
              '${worker.experienceYears} yrs exp \u2022 ${worker.totalJobsCompleted} jobs',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),

            // View Profile link
            GestureDetector(
              onTap: () {
                // TODO: Navigate to worker profile
              },
              child: Text(
                'View Profile',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
