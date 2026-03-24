import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/features/auth/providers/auth_provider.dart';
import 'package:freshkart_worker/features/profile/providers/profile_provider.dart';
import 'package:freshkart_worker/shared/widgets/confirm_dialog.dart';
import 'package:freshkart_worker/shared/widgets/network_image_widget.dart';
import 'package:freshkart_worker/shared/widgets/shimmer_loader.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(workerProfileProvider);

    return Scaffold(
      body: profileAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: ShimmerLoader.list(),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (worker) {
          if (worker == null)
            return const Center(child: Text('Profile not found'));
          return ListView(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      WorkerColors.primary,
                      WorkerColors.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    NetworkImageWidget(
                      imageUrl: worker.profilePhotoUrl,
                      width: 80,
                      height: 80,
                      borderRadius: 40,
                      placeholderIcon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      worker.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      worker.phone,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      worker.skillsLabel,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statCol('${worker.rating}', 'Rating'),
                        _statCol('${worker.completedJobs}', 'Jobs'),
                        _statCol('${worker.experienceYears}yr', 'Exp'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _section('Profile', [
                _menuItem(
                  Icons.person_outline,
                  'Edit Profile',
                  () => context.push('/edit-profile'),
                ),
                _menuItem(
                  Icons.build_outlined,
                  'My Skills',
                  () => context.push('/skills'),
                ),
                _menuItem(
                  Icons.description_outlined,
                  'Documents',
                  () => context.push('/documents'),
                ),
                _menuItem(
                  Icons.account_balance_outlined,
                  'Bank Details',
                  () => context.push('/bank-details'),
                ),
              ]),
              _section('Work', [
                _menuItem(
                  Icons.star_outline,
                  'Reviews',
                  () => context.push('/reviews'),
                ),
              ]),
              _section('Support', [
                _menuItem(
                  Icons.help_outline,
                  'Help & Support',
                  () => context.push('/support'),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.all(24),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Logout',
                      message: 'Are you sure you want to logout?',
                      isDangerous: true,
                    );
                    if (confirmed) {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCol(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: WorkerColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
