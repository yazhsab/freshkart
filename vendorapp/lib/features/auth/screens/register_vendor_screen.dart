import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/api/api_client.dart';
import 'package:freshkart_vendor/core/storage/local_storage.dart';
import 'package:dio/dio.dart';

class RegisterVendorScreen extends ConsumerStatefulWidget {
  const RegisterVendorScreen({super.key});

  @override
  ConsumerState<RegisterVendorScreen> createState() =>
      _RegisterVendorScreenState();
}

class _RegisterVendorScreenState extends ConsumerState<RegisterVendorScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;
  final _api = ApiClient.instance;

  // Step 1 controllers
  final _step1Key = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopNameTamilController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _shopCategory = 'Grocery';

  // Step 2 controllers
  final _step2Key = GlobalKey<FormState>();
  final _addressStreetController = TextEditingController();
  final _addressAreaController = TextEditingController();
  String _selectedCity = 'Chennai';
  final _pincodeController = TextEditingController();
  final _shopPhoneController = TextEditingController();
  TimeOfDay _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 21, minute: 0);
  final Set<String> _workingDays = {'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'};
  double _deliveryRadius = 5.0;

  // Step 3 controllers
  final _step3Key = GlobalKey<FormState>();
  final _fssaiController = TextEditingController();
  final _gstinController = TextEditingController();
  PlatformFile? _fssaiDoc;
  PlatformFile? _gstinDoc;
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderController = TextEditingController();
  bool _termsAccepted = false;

  static const List<String> _cities = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Salem',
    'Trichy',
  ];

  static const List<String> _categories = [
    'Grocery',
    'Supermarket',
    'Organic',
    'Other',
  ];

  static const List<String> _allDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill phone from storage
    final phone = LocalStorage.instance.getString(LocalStorage.kUserPhone);
    if (phone != null) {
      _shopPhoneController.text = phone.replaceFirst('+91', '');
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopNameTamilController.dispose();
    _descriptionController.dispose();
    _addressStreetController.dispose();
    _addressAreaController.dispose();
    _pincodeController.dispose();
    _shopPhoneController.dispose();
    _fssaiController.dispose();
    _gstinController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && !_step1Key.currentState!.validate()) return;
    if (_currentStep == 1 && !_step2Key.currentState!.validate()) return;

    setState(() => _currentStep++);
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickFile({required bool isFssai}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        if (isFssai) {
          _fssaiDoc = result.files.first;
        } else {
          _gstinDoc = result.files.first;
        }
      });
    }
  }

  Future<void> _pickTime({required bool isOpening}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: VendorColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _timeToDbFormat(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submitRegistration() async {
    if (!_step3Key.currentState!.validate()) return;
    if (!_termsAccepted) {
      _showError('Please accept the terms and conditions');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Step 1: Register vendor
      final address =
          '${_addressStreetController.text.trim()}, ${_addressAreaController.text.trim()}';

      final vendorData = {
        'shop_name': _shopNameController.text.trim(),
        'shop_name_tamil': _shopNameTamilController.text.trim().isEmpty
            ? null
            : _shopNameTamilController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'shop_category': _shopCategory,
        'address': address,
        'city': _selectedCity,
        'pincode': _pincodeController.text.trim(),
        'shop_phone': '+91${_shopPhoneController.text.trim()}',
        'opening_time': _timeToDbFormat(_openingTime),
        'closing_time': _timeToDbFormat(_closingTime),
        'working_days': _workingDays.toList(),
        'delivery_radius_km': _deliveryRadius,
        'fssai_number': _fssaiController.text.trim(),
        'gstin_number': _gstinController.text.trim().isEmpty
            ? null
            : _gstinController.text.trim(),
        'bank_account_number': _bankAccountController.text.trim(),
        'bank_ifsc': _ifscController.text.trim().toUpperCase(),
        'bank_account_holder_name': _accountHolderController.text.trim(),
      };

      final response = await _api.post('/vendors/register', data: vendorData);

      final vendorId =
          response.data['id'] as String? ??
          response.data['vendor']?['id'] as String? ??
          '';

      if (vendorId.isNotEmpty) {
        await LocalStorage.instance.saveVendorId(vendorId);
      }

      // Step 2: Upload documents
      if (_fssaiDoc != null && _fssaiDoc!.path != null) {
        final fssaiFormData = FormData.fromMap({
          'fssai_doc': await MultipartFile.fromFile(
            _fssaiDoc!.path!,
            filename: _fssaiDoc!.name,
          ),
          'doc_type': 'fssai',
        });
        await _api.postFormData('/vendors/me/docs', formData: fssaiFormData);
      }

      if (_gstinDoc != null && _gstinDoc!.path != null) {
        final gstinFormData = FormData.fromMap({
          'gstin_doc': await MultipartFile.fromFile(
            _gstinDoc!.path!,
            filename: _gstinDoc!.name,
          ),
          'doc_type': 'gstin',
        });
        await _api.postFormData('/vendors/me/docs', formData: gstinFormData);
      }

      if (mounted) {
        context.go('/pending-approval');
      }
    } catch (e) {
      _showError(
        e is DioException
            ? (e.message ?? 'Registration failed. Please try again.')
            : 'Registration failed. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: VendorColors.cancelledOrder,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorColors.background,
      appBar: AppBar(
        title: const Text('Vendor Registration'),
        leading: _currentStep > 0
            ? IconButton(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
      ),
      body: Column(
        children: [
          // Step indicator
          _buildStepIndicator(),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const labels = ['Shop Info', 'Location', 'Documents'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted || isActive
                          ? VendorColors.primary
                          : VendorColors.divider,
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? VendorColors.primary
                            : isActive
                            ? VendorColors.primary
                            : VendorColors.divider,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.white
                                      : VendorColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? VendorColors.primary
                            : VendorColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (index < 2 && index == 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep > 0
                          ? VendorColors.primary
                          : VendorColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---- STEP 1: Shop Basic Info ----
  Widget _buildStep1() {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Shop Basic Info'),
          const SizedBox(height: 16),

          // Shop name English
          _buildLabel('Shop Name (English)', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _shopNameController,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Shop name is required';
              if (v.trim().length < 3) return 'Minimum 3 characters';
              return null;
            },
            decoration: const InputDecoration(hintText: 'e.g. Fresh Mart'),
          ),
          const SizedBox(height: 16),

          // Shop name Tamil
          _buildLabel('Shop Name (Tamil)', required: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _shopNameTamilController,
            decoration: const InputDecoration(
              hintText:
                  '\u0B89\u0BA4\u0BBE\u0BB0\u0BA3\u0BAE\u0BCD: \u0BAA\u0BC1\u0BA4\u0BBF\u0BAF \u0BAE\u0BBE\u0BB0\u0BCD\u0B9F\u0BCD',
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _buildLabel('Description', required: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'Tell customers about your shop',
              counterText: '',
            ),
            validator: (v) {
              if (v != null && v.length > 300) return 'Maximum 300 characters';
              return null;
            },
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_descriptionController.text.length}/300',
              style: const TextStyle(
                fontSize: 12,
                color: VendorColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Shop category
          _buildLabel('Shop Category', required: true),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _shopCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _shopCategory = category);
                },
                selectedColor: VendorColors.primaryBg,
                checkmarkColor: VendorColors.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? VendorColors.primary
                      : VendorColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected
                      ? VendorColors.primary
                      : VendorColors.divider,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Next button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextStep,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  // ---- STEP 2: Location & Contact ----
  Widget _buildStep2() {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Location & Contact'),
          const SizedBox(height: 16),

          // Street address
          _buildLabel('Street Address', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressStreetController,
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Street address is required'
                : null,
            decoration: const InputDecoration(hintText: 'Door No, Street Name'),
          ),
          const SizedBox(height: 16),

          // Area
          _buildLabel('Area / Locality', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressAreaController,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Area is required' : null,
            decoration: const InputDecoration(
              hintText: 'e.g. T. Nagar, Anna Nagar',
            ),
          ),
          const SizedBox(height: 16),

          // City dropdown
          _buildLabel('City', required: true),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            items: _cities.map((city) {
              return DropdownMenuItem(value: city, child: Text(city));
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _selectedCity = value);
            },
            decoration: const InputDecoration(),
          ),
          const SizedBox(height: 16),

          // Pincode
          _buildLabel('Pincode', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Pincode is required';
              if (v.trim().length != 6) return 'Enter a valid 6-digit pincode';
              return null;
            },
            decoration: const InputDecoration(
              hintText: '600001',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),

          // Shop phone
          _buildLabel('Shop Phone', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _shopPhoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Phone is required';
              if (v.trim().length != 10) return 'Enter a valid 10-digit number';
              return null;
            },
            decoration: InputDecoration(
              hintText: '9876543210',
              counterText: '',
              prefixIcon: Container(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: VendorColors.primaryBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '+91',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: VendorColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 20,
                      color: VendorColors.divider,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Opening & Closing time
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Opening Time', required: false),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _pickTime(isOpening: true),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: VendorColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 18,
                              color: VendorColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_openingTime),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Closing Time', required: false),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _pickTime(isOpening: false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: VendorColors.background,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 18,
                              color: VendorColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTime(_closingTime),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Working days
          _buildLabel('Working Days', required: false),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allDays.map((day) {
              final isSelected = _workingDays.contains(day);
              return FilterChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _workingDays.add(day);
                    } else {
                      _workingDays.remove(day);
                    }
                  });
                },
                selectedColor: VendorColors.primaryBg,
                checkmarkColor: VendorColors.primary,
                labelStyle: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? VendorColors.primary
                      : VendorColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected
                      ? VendorColors.primary
                      : VendorColors.divider,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Delivery radius slider
          _buildLabel('Delivery Radius', required: false),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _deliveryRadius,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: VendorColors.primary,
                  inactiveColor: VendorColors.primaryBg,
                  label: '${_deliveryRadius.toInt()} km',
                  onChanged: (value) {
                    setState(() => _deliveryRadius = value);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: VendorColors.primaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_deliveryRadius.toInt()} km',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: VendorColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Next button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _nextStep,
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }

  // ---- STEP 3: Documents & Bank ----
  Widget _buildStep3() {
    return Form(
      key: _step3Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Documents & Bank Details'),
          const SizedBox(height: 16),

          // FSSAI License
          _buildLabel('FSSAI License Number', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _fssaiController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'FSSAI license number is required';
              }
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'Enter FSSAI license number',
            ),
          ),
          const SizedBox(height: 16),

          // GSTIN
          _buildLabel('GSTIN', required: false),
          const SizedBox(height: 6),
          TextFormField(
            controller: _gstinController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'Enter GSTIN (optional)',
            ),
          ),
          const SizedBox(height: 20),

          // Upload FSSAI doc
          _buildLabel('Upload FSSAI Certificate', required: false),
          const SizedBox(height: 8),
          _buildFilePickerButton(
            file: _fssaiDoc,
            onTap: () => _pickFile(isFssai: true),
            hint: 'Upload PDF or Image',
          ),
          const SizedBox(height: 16),

          // Upload GSTIN doc
          _buildLabel('Upload GSTIN Certificate', required: false),
          const SizedBox(height: 8),
          _buildFilePickerButton(
            file: _gstinDoc,
            onTap: () => _pickFile(isFssai: false),
            hint: 'Upload PDF or Image (optional)',
          ),
          const SizedBox(height: 24),

          // Divider
          const Divider(height: 1),
          const SizedBox(height: 24),

          _sectionTitle('Bank Details'),
          const SizedBox(height: 16),

          // Bank account
          _buildLabel('Account Number', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _bankAccountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Account number is required';
              }
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'Enter bank account number',
            ),
          ),
          const SizedBox(height: 16),

          // IFSC
          _buildLabel('IFSC Code', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _ifscController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 11,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'IFSC code is required';
              }
              if (v.trim().length != 11)
                return 'IFSC code must be 11 characters';
              return null;
            },
            decoration: const InputDecoration(
              hintText: 'e.g. SBIN0001234',
              counterText: '',
            ),
          ),
          const SizedBox(height: 16),

          // Account holder
          _buildLabel('Account Holder Name', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _accountHolderController,
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Account holder name is required';
              }
              return null;
            },
            decoration: const InputDecoration(hintText: 'As per bank records'),
          ),
          const SizedBox(height: 24),

          // Terms checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _termsAccepted,
                  onChanged: (value) {
                    setState(() => _termsAccepted = value ?? false);
                  },
                  activeColor: VendorColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'I agree to FreshKart\'s Vendor Terms of Service, '
                  'Privacy Policy, and confirm that all information '
                  'provided is accurate.',
                  style: TextStyle(
                    fontSize: 13,
                    color: VendorColors.textSecondary,
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
              onPressed: _isSubmitting ? null : _submitRegistration,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Registration'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---- Helper Widgets ----

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: VendorColors.textPrimary,
      ),
    );
  }

  Widget _buildLabel(String text, {required bool required}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: VendorColors.textPrimary,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: VendorColors.cancelledOrder,
            ),
          ),
      ],
    );
  }

  Widget _buildFilePickerButton({
    required PlatformFile? file,
    required VoidCallback onTap,
    required String hint,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: file != null
              ? VendorColors.primaryBg
              : VendorColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: file != null
                ? VendorColors.primaryLight
                : VendorColors.divider,
          ),
        ),
        child: Row(
          children: [
            Icon(
              file != null ? Icons.check_circle : Icons.upload_file,
              size: 20,
              color: file != null
                  ? VendorColors.primary
                  : VendorColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file != null ? file.name : hint,
                style: TextStyle(
                  fontSize: 14,
                  color: file != null
                      ? VendorColors.textPrimary
                      : VendorColors.textSecondary,
                  fontWeight: file != null ? FontWeight.w500 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (file != null)
              Text(
                _formatFileSize(file.size),
                style: const TextStyle(
                  fontSize: 12,
                  color: VendorColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
