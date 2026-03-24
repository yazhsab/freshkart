import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_worker/core/models/service_category_model.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/features/profile/providers/profile_provider.dart';
import 'package:freshkart_worker/shared/widgets/shimmer_loader.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(workerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Skills')),
      body: profileAsync.when(
        loading: () =>
            const Padding(padding: EdgeInsets.all(16), child: ShimmerLoader()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (worker) {
          if (worker == null) return const Center(child: Text('Not found'));
          final skills = worker.skills;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ServiceCategory.defaultCategories.length,
            itemBuilder: (context, index) {
              final cat = ServiceCategory.defaultCategories[index];
              final isActive = skills.contains(cat.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive
                      ? WorkerColors.primary.withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? WorkerColors.primary.withValues(alpha: 0.3)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Text(cat.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            cat.tamilName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isActive ? Icons.check_circle : Icons.circle_outlined,
                      color: isActive
                          ? WorkerColors.primary
                          : Colors.grey.shade400,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
