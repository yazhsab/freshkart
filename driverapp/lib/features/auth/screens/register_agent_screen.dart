import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/auth/providers/auth_provider.dart';

class RegisterAgentScreen extends ConsumerStatefulWidget {
  const RegisterAgentScreen({super.key});

  @override
  ConsumerState<RegisterAgentScreen> createState() =>
      _RegisterAgentScreenState();
}

class _RegisterAgentScreenState extends ConsumerState<RegisterAgentScreen> {
  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1 controllers
  final _nameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  String _vehicleType = 'bike';
  String? _selectedCity;

  // Step 2 controllers
  final _aadhaarController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _termsAccepted = false;

  // Document files
  File? _aadhaarFile;
  File? _licenseFile;
  File? _vehicleRcFile;
  File? _profilePhotoFile;

  final _imagePicker = ImagePicker();

  final List<String> _cities = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Salem',
    'Trichy',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _vehicleNumberController.dispose();
    _aadhaarController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _goToStep2() {
    if (!_step1FormKey.currentState!.validate()) return;
    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a service city'),
          backgroundColor: DeliveryColors.newOrder,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 1);
  }

  void _goBackToStep1() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = 0);
  }

  Future<void> _pickImage({
    required String label,
    required ValueChanged<File> onPicked,
    bool cameraOnly = false,
  }) async {
    ImageSource source = ImageSource.gallery;

    if (cameraOnly) {
      source = ImageSource.camera;
    } else {
      final chosen = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upload $label',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: DeliveryColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: DeliveryColors.primary,
                  ),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: DeliveryColors.primary,
                  ),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      );
      if (chosen == null) return;
      source = chosen;
    }

    try {
      final xFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (xFile != null) {
        onPicked(File(xFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: DeliveryColors.newOrder,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _onSubmit() async {
    if (!_step2FormKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the terms and conditions'),
          backgroundColor: DeliveryColors.newOrder,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    final data = <String, dynamic>{
      'full_name': _nameController.text.trim(),
      'vehicle_type': _vehicleType,
      'vehicle_number': _vehicleNumberController.text.trim(),
      'city': _selectedCity,
      'aadhaar_number': _aadhaarController.text.trim(),
      'bank_account': _bankAccountController.text.trim(),
      'ifsc_code': _ifscController.text.trim().toUpperCase(),
    };

    // Add file paths if available (backend would handle multipart separately)
    if (_aadhaarFile != null) {
      data['aadhaar_doc_path'] = _aadhaarFile!.path;
    }
    if (_licenseFile != null) {
      data['license_doc_path'] = _licenseFile!.path;
    }
    if (_vehicleRcFile != null) {
      data['vehicle_rc_path'] = _vehicleRcFile!.path;
    }
    if (_profilePhotoFile != null) {
      data['profile_photo_path'] = _profilePhotoFile!.path;
    }

    await ref.read(authProvider.notifier).registerAgent(data);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthPendingApproval) {
        context.go('/pending-approval');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: DeliveryColors.newOrder,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        backgroundColor: DeliveryColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Register as Delivery Partner'),
        leading: _currentStep == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _goBackToStep1,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),

          // Page view
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(isLoading), _buildStep2(isLoading)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepDot(0, 'Personal & Vehicle'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1
                  ? DeliveryColors.primary
                  : DeliveryColors.divider,
            ),
          ),
          _buildStepDot(1, 'Documents'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? DeliveryColors.primary : DeliveryColors.divider,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : DeliveryColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? DeliveryColors.primary
                : DeliveryColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ---- STEP 1: Personal & Vehicle ----
  Widget _buildStep1(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full name
            const Text(
              'Full Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: DeliveryColors.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: DeliveryColors.textSecondary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Full name is required';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Vehicle type
            const Text(
              'Vehicle Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildVehicleCard(
                  icon: '\u{1F6B2}',
                  label: 'Bicycle',
                  subtitle: 'Earn \u20B920\u201330/delivery',
                  value: 'bicycle',
                ),
                const SizedBox(width: 10),
                _buildVehicleCard(
                  icon: '\u{1F3CD}',
                  label: 'Bike',
                  subtitle: 'Earn \u20B930\u201350/delivery',
                  value: 'bike',
                ),
                const SizedBox(width: 10),
                _buildVehicleCard(
                  icon: '\u{1F690}',
                  label: 'Van',
                  subtitle: 'Earn \u20B950\u201380/delivery',
                  value: 'van',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Vehicle registration number
            const Text(
              'Vehicle Registration Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _vehicleNumberController,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'TN01AB1234',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: DeliveryColors.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.directions_car_outlined,
                  color: DeliveryColors.textSecondary,
                ),
              ),
              validator: (value) {
                if (_vehicleType == 'bicycle') return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Vehicle number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Service city dropdown
            const Text(
              'Service City',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              hint: const Text('Select your city'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: DeliveryColors.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.location_city_outlined,
                  color: DeliveryColors.textSecondary,
                ),
              ),
              items: _cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: isLoading
                  ? null
                  : (value) => setState(() => _selectedCity = value),
            ),
            const SizedBox(height: 32),

            // Next button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _goToStep2,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DeliveryColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleCard({
    required String icon,
    required String label,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _vehicleType == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _vehicleType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? DeliveryColors.primaryBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? DeliveryColors.primary
                  : DeliveryColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? DeliveryColors.primary
                      : DeliveryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: DeliveryColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- STEP 2: Documents ----
  Widget _buildStep2(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step2FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aadhaar number
            const Text(
              'Aadhaar Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _aadhaarController,
              enabled: !isLoading,
              keyboardType: TextInputType.number,
              maxLength: 12,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: InputDecoration(
                hintText: '123456789012',
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: DeliveryColors.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.credit_card_outlined,
                  color: DeliveryColors.textSecondary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Aadhaar number is required';
                }
                if (value.trim().length != 12) {
                  return 'Aadhaar number must be 12 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Document uploads
            const Text(
              'Upload Documents',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            _buildUploadButton(
              label: 'Aadhaar Card (Front)',
              icon: Icons.badge_outlined,
              file: _aadhaarFile,
              onTap: () => _pickImage(
                label: 'Aadhaar Card',
                onPicked: (f) => setState(() => _aadhaarFile = f),
              ),
            ),
            const SizedBox(height: 10),
            _buildUploadButton(
              label: 'Driving License',
              icon: Icons.card_membership_outlined,
              file: _licenseFile,
              onTap: () => _pickImage(
                label: 'Driving License',
                onPicked: (f) => setState(() => _licenseFile = f),
              ),
            ),
            const SizedBox(height: 10),
            _buildUploadButton(
              label: 'Vehicle RC',
              icon: Icons.description_outlined,
              file: _vehicleRcFile,
              onTap: () => _pickImage(
                label: 'Vehicle RC',
                onPicked: (f) => setState(() => _vehicleRcFile = f),
              ),
            ),
            const SizedBox(height: 10),
            _buildUploadButton(
              label: 'Profile Photo (Camera)',
              icon: Icons.camera_alt_outlined,
              file: _profilePhotoFile,
              onTap: () => _pickImage(
                label: 'Profile Photo',
                cameraOnly: true,
                onPicked: (f) => setState(() => _profilePhotoFile = f),
              ),
            ),
            const SizedBox(height: 24),

            // Bank details
            const Text(
              'Bank Account Number',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bankAccountController,
              enabled: !isLoading,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: 'Enter bank account number',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: DeliveryColors.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.account_balance_outlined,
                  color: DeliveryColors.textSecondary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Bank account number is required';
                }
                if (value.trim().length < 9) {
                  return 'Enter a valid account number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            const Text(
              'IFSC Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _ifscController,
              enabled: !isLoading,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. SBIN0001234',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: DeliveryColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: DeliveryColors.primary,
                    width: 1.5,
                  ),
                ),
                prefixIcon: const Icon(
                  Icons.code,
                  color: DeliveryColors.textSecondary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'IFSC code is required';
                }
                if (!RegExp(
                  r'^[A-Z]{4}0[A-Z0-9]{6}$',
                ).hasMatch(value.trim().toUpperCase())) {
                  return 'Enter a valid IFSC code';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Terms checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _termsAccepted,
                    onChanged: isLoading
                        ? null
                        : (val) =>
                              setState(() => _termsAccepted = val ?? false),
                    activeColor: DeliveryColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'I agree to FreshKart\'s Terms of Service, Privacy Policy, '
                    'and Delivery Partner Agreement. I confirm that all '
                    'information provided is accurate.',
                    style: TextStyle(
                      fontSize: 13,
                      color: DeliveryColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DeliveryColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: DeliveryColors.primary.withOpacity(
                    0.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Submit Application',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton({
    required String label,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
  }) {
    final hasFile = file != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasFile ? DeliveryColors.primaryBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? DeliveryColors.primary : DeliveryColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle : icon,
              color: hasFile
                  ? DeliveryColors.primary
                  : DeliveryColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: hasFile
                          ? DeliveryColors.primary
                          : DeliveryColors.textPrimary,
                    ),
                  ),
                  if (hasFile)
                    Text(
                      file!.path.split('/').last,
                      style: const TextStyle(
                        fontSize: 11,
                        color: DeliveryColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              hasFile ? Icons.edit : Icons.upload_file,
              color: DeliveryColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
