import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/profile/providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _selectedImage;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initFields() {
    if (_isInitialized) return;
    final profileState = ref.read(profileProvider);
    final user = profileState.valueOrNull;
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone;
      _isInitialized = true;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(profileProvider.notifier);

    // Upload avatar first if selected
    if (_selectedImage != null) {
      await notifier.uploadAvatar(_selectedImage!);
    }

    // Update name and email
    await notifier.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final user = profileState.valueOrNull;
    final isLoading = profileState is AsyncLoading;

    _initFields();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Avatar with camera overlay ──
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.backgroundGreen,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (user?.avatarUrl != null
                                ? NetworkImage(user!.avatarUrl!)
                                      as ImageProvider
                                : null),
                      child: _selectedImage == null && user?.avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primaryGreen,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Full Name ──
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Email (optional) ──
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Phone (read-only) ──
              TextFormField(
                controller: _phoneController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                ),
                style: TextStyle(color: AppColors.textHint),
              ),
              const SizedBox(height: 32),

              // ── Save Changes ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onSave,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
