import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/profile/providers/profile_provider.dart';
import 'package:freshkart_delivery/features/shared/widgets/app_button.dart';
import 'package:freshkart_delivery/features/shared/widgets/app_text_field.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyPhoneController;

  @override
  void initState() {
    super.initState();
    final agent = ref.read(profileProvider).agent;
    _fullNameController = TextEditingController(text: agent?.fullName ?? '');
    _emergencyNameController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final data = <String, dynamic>{
      'full_name': _fullNameController.text.trim(),
    };

    if (_emergencyNameController.text.trim().isNotEmpty) {
      data['emergency_contact_name'] = _emergencyNameController.text.trim();
    }
    if (_emergencyPhoneController.text.trim().isNotEmpty) {
      data['emergency_contact_phone'] = _emergencyPhoneController.text.trim();
    }

    final success = await ref
        .read(profileProvider.notifier)
        .updateProfile(data);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully',
            style: GoogleFonts.notoSans(),
          ),
          backgroundColor: DeliveryColors.online,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      context.pop();
    } else if (mounted) {
      final error = ref.read(profileProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'Failed to update profile',
            style: GoogleFonts.notoSans(),
          ),
          backgroundColor: DeliveryColors.newOrder,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: DeliveryColors.surface,
        foregroundColor: DeliveryColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DeliveryColors.primaryBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DeliveryColors.primaryLight.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: DeliveryColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Phone number and Aadhaar cannot be changed. Contact support if needed.',
                        style: GoogleFonts.notoSans(
                          fontSize: 13,
                          color: DeliveryColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                prefixIcon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Full name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Emergency Contact',
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: DeliveryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'This person will be contacted in case of an emergency during a delivery.',
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  color: DeliveryColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emergencyNameController,
                label: 'Emergency Contact Name',
                hint: 'e.g. Spouse, Parent',
                prefixIcon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emergencyPhoneController,
                label: 'Emergency Contact Phone',
                hint: 'Enter 10-digit phone number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      value.trim().length != 10) {
                    return 'Phone number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              AppButton(
                label: 'Save',
                onPressed: _saveProfile,
                isLoading: state.isLoading,
                fullWidth: true,
                color: DeliveryColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
