import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/features/profile/providers/profile_provider.dart';
import 'package:freshkart_worker/shared/widgets/status_badge.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(workerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (worker) {
          if (worker == null) return const Center(child: Text('Not found'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _docCard(
                'Aadhaar Card',
                worker.maskedAadhaar,
                Icons.badge,
                worker.bgvStatus,
              ),
              _docCard(
                'Profile Photo',
                worker.profilePhotoUrl != null ? 'Uploaded' : 'Not uploaded',
                Icons.photo_camera,
                worker.profilePhotoUrl != null ? 'approved' : 'pending',
              ),
              _docCard(
                'Police Verification',
                'BGV Status',
                Icons.security,
                worker.bgvStatus,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'To update documents, please contact support.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _docCard(String title, String subtitle, IconData icon, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: WorkerColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: WorkerColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          StatusBadge(status: status, isBgv: true),
        ],
      ),
    );
  }
}
