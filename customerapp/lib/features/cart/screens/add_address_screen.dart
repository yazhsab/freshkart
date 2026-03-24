import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'package:freshkart_customer/core/config/app_config.dart';
import 'package:freshkart_customer/core/models/address_model.dart';
import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/cart/providers/address_provider.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? existingAddress;

  const AddAddressScreen({super.key, this.existingAddress});

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _label;
  late final TextEditingController _flatNoController;
  late final TextEditingController _areaController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  bool _isDefault = false;
  bool _isLoading = false;
  bool _isLocating = false;
  double _lat = AppConfig.defaultLatitude;
  double _lng = AppConfig.defaultLongitude;

  bool get _isEditing => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _label = addr?.label ?? 'Home';
    _flatNoController = TextEditingController(text: addr?.flatNo ?? '');
    _areaController = TextEditingController(text: addr?.area ?? '');
    _cityController = TextEditingController(
      text: addr?.city ?? AppConfig.defaultCity,
    );
    _stateController = TextEditingController(
      text: addr?.state ?? AppConfig.defaultState,
    );
    _pincodeController = TextEditingController(text: addr?.pincode ?? '');
    _isDefault = addr?.isDefault ?? false;
    if (addr != null) {
      _lat = addr.lat;
      _lng = addr.lng;
    }
  }

  @override
  void dispose() {
    _flatNoController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'label': _label,
        'flat_no': _flatNoController.text.trim(),
        'area': _areaController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'lat': _lat,
        'lng': _lng,
        'is_default': _isDefault,
      };

      final notifier = ref.read(addressProvider.notifier);
      AddressModel saved;

      if (_isEditing) {
        saved = await notifier.updateAddress(widget.existingAddress!.id, data);
      } else {
        saved = await notifier.addAddress(data);
      }

      // If set as default or first address, auto-select it
      if (_isDefault || !_isEditing) {
        ref.read(selectedAddressProvider.notifier).state = saved;
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Address' : 'Add Address'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      backgroundColor: AppColors.background,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Label selector
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address Label',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'Home',
                        label: Text('Home'),
                        icon: Icon(Icons.home_outlined),
                      ),
                      ButtonSegment(
                        value: 'Work',
                        label: Text('Work'),
                        icon: Icon(Icons.work_outline),
                      ),
                      ButtonSegment(
                        value: 'Other',
                        label: Text('Other'),
                        icon: Icon(Icons.location_on_outlined),
                      ),
                    ],
                    selected: {_label},
                    onSelectionChanged: (selection) {
                      setState(() => _label = selection.first);
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.backgroundGreen,
                      selectedForegroundColor: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Use current location button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLocating ? null : _useCurrentLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.gps_fixed),
                label: Text(
                  _isLocating ? 'Getting location...' : 'Use current location',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address form fields
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _flatNoController,
                    decoration: const InputDecoration(
                      labelText: 'Flat / House No. / Building *',
                      hintText: 'e.g., Flat 2A, Sri Balaji Apartments',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Flat/House number is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Area / Street / Locality *',
                      hintText: 'e.g., T Nagar, Anna Nagar',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Area is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(
                      labelText: 'Pincode *',
                      hintText: '600001',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Pincode is required';
                      }
                      if (value.trim().length != 6) {
                        return 'Pincode must be 6 digits';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Set as default toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Set as default address',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                activeColor: AppColors.primaryGreen,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEditing ? 'Update Address' : 'Save Address',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
