import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/storage/local_storage.dart';
import 'package:freshkart_worker/core/utils/extensions.dart';
import 'package:freshkart_worker/features/profile/providers/profile_provider.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';
import 'package:freshkart_worker/shared/widgets/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final workerId = LocalStorage.workerId;
      if (workerId == null) return;
      await Supabase.instance.client.from('workers').update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'experience_years': int.tryParse(_experienceController.text) ?? 0,
      }).eq('id', workerId);
      ref.invalidate(workerProfileProvider);
      if (mounted) {
        context.showSnackBar('Profile updated!');
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(workerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (worker) {
          if (worker == null) return const Center(child: Text('Not found'));
          if (!_initialized) {
            _nameController.text = worker.name;
            _bioController.text = worker.bio ?? '';
            _experienceController.text = '${worker.experienceYears}';
            _initialized = true;
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AppTextField(label: 'Full Name', controller: _nameController),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Bio',
                controller: _bioController,
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Years of Experience',
                controller: _experienceController,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Save Changes',
                onPressed: _save,
                isLoading: _isLoading,
              ),
            ],
          );
        },
      ),
    );
  }
}
