import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/config/app_config.dart';
import 'package:freshkart_worker/core/models/service_category_model.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';
import 'package:freshkart_worker/core/theme/app_colors.dart';
import 'package:freshkart_worker/core/utils/extensions.dart';
import 'package:freshkart_worker/shared/widgets/app_button.dart';
import 'package:freshkart_worker/shared/widgets/app_text_field.dart';

class RegisterWorkerScreen extends ConsumerStatefulWidget {
  const RegisterWorkerScreen({super.key});

  @override
  ConsumerState<RegisterWorkerScreen> createState() =>
      _RegisterWorkerScreenState();
}

class _RegisterWorkerScreenState extends ConsumerState<RegisterWorkerScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Personal Info
  final _nameController = TextEditingController();
  String _selectedCity = AppConfig.supportedCities.first;
  final _pincodesController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();

  // Step 2: Skills
  final Set<String> _selectedSkills = {};

  // Step 3: Documents & Bank
  File? _profilePhoto;
  final _aadhaarController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankIfscController = TextEditingController();
  final _bankNameController = TextEditingController();

  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _pincodesController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _aadhaarController.dispose();
    _bankAccountController.dispose();
    _bankIfscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && !_formKeys[0].currentState!.validate()) return;
    if (_currentStep == 1 && _selectedSkills.isEmpty) {
      context.showSnackBar('Select at least one skill', isError: true);
      return;
    }
    if (_currentStep == 2) {
      if (!_formKeys[2].currentState!.validate()) return;
      _submitRegistration();
      return;
    }
    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (image != null) setState(() => _profilePhoto = File(image.path));
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSubmitting = true);
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final phone =
          supabase.auth.currentUser!.phone?.replaceFirst('+91', '') ?? '';

      String? photoUrl;
      if (_profilePhoto != null) {
        final path = 'workers/$userId/profile.jpg';
        await supabase.storage
            .from('worker-photos')
            .upload(path, _profilePhoto!);
        photoUrl = supabase.storage.from('worker-photos').getPublicUrl(path);
      }

      final pincodes = _pincodesController.text
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      final workerData = {
        'id': userId,
        'name': _nameController.text.trim(),
        'phone': phone,
        'city': _selectedCity,
        'pincodes': pincodes,
        'skills': _selectedSkills.toList(),
        'experience_years': int.tryParse(_experienceController.text) ?? 0,
        'bio': _bioController.text.trim(),
        'profile_photo_url': photoUrl,
        'aadhaar_number': _aadhaarController.text.trim(),
        'bank_account_number': _bankAccountController.text.trim(),
        'bank_ifsc': _bankIfscController.text.trim().toUpperCase(),
        'bank_name': _bankNameController.text.trim(),
        'bgv_status': 'pending',
        'is_available': false,
        'is_active': true,
        'rating': 0,
        'total_jobs': 0,
        'completed_jobs': 0,
      };

      await supabase.from('workers').upsert(workerData);
      LocalStorage.workerId = userId;

      if (mounted) context.go('/pending-approval');
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Registration'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _currentStep
                          ? WorkerColors.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_personalInfoStep(), _skillsStep(), _documentsStep()],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: AppButton(
              label: _currentStep == 2 ? 'Submit' : 'Next',
              onPressed: _nextStep,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  Widget _personalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Full Name',
              hint: 'Enter your full name',
              controller: _nameController,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'City',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              items: AppConfig.supportedCities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCity = v!),
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Service Pincodes',
              hint: '600001, 600002, 600003',
              controller: _pincodesController,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Add at least one pincode' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Years of Experience',
              hint: '3',
              controller: _experienceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Bio (Optional)',
              hint: 'Tell customers about yourself...',
              controller: _bioController,
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _skillsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Skills',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose services you can provide',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: ServiceCategory.defaultCategories.length,
            itemBuilder: (context, index) {
              final category = ServiceCategory.defaultCategories[index];
              final isSelected = _selectedSkills.contains(category.id);
              return GestureDetector(
                onTap: () => setState(() {
                  isSelected
                      ? _selectedSkills.remove(category.id)
                      : _selectedSkills.add(category.id);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? WorkerColors.primary.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? WorkerColors.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        category.tamilName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '₹${category.basePrice.toInt()}+',
                        style: TextStyle(
                          fontSize: 12,
                          color: WorkerColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _documentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documents & Bank',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      _profilePhoto != null ? FileImage(_profilePhoto!) : null,
                  child: _profilePhoto == null
                      ? const Icon(
                          Icons.camera_alt,
                          size: 32,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Tap to take profile photo',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Aadhaar Number',
              hint: 'XXXX XXXX XXXX',
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Aadhaar is required';
                if (!v.replaceAll(' ', '').isValidAadhaar)
                  return 'Enter valid 12-digit Aadhaar';
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Bank Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Bank Name',
              hint: 'e.g. State Bank of India',
              controller: _bankNameController,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Bank name is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Account Number',
              hint: 'Enter account number',
              controller: _bankAccountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Account number is required'
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'IFSC Code',
              hint: 'e.g. SBIN0001234',
              controller: _bankIfscController,
              validator: (v) {
                if (v == null || v.isEmpty) return 'IFSC is required';
                if (!v.toUpperCase().isValidIfsc)
                  return 'Enter valid IFSC code';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
