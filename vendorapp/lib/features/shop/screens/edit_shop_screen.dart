import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/features/shop/providers/shop_provider.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_text_field.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_button.dart';
import 'package:freshkart_vendor/features/shared/widgets/image_picker_widget.dart';
import 'package:freshkart_vendor/features/shared/widgets/loading_overlay.dart';

class EditShopScreen extends ConsumerStatefulWidget {
  const EditShopScreen({super.key});

  @override
  ConsumerState<EditShopScreen> createState() => _EditShopScreenState();
}

class _EditShopScreenState extends ConsumerState<EditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopNameTamilController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _minOrderController = TextEditingController();
  final _phoneController = TextEditingController();

  double _deliveryRadius = 5.0;
  File? _bannerImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final vendor = ref.read(shopProvider).valueOrNull;
    if (vendor != null) {
      _shopNameController.text = vendor.shopName;
      _shopNameTamilController.text = vendor.shopNameTamil ?? '';
      _descriptionController.text = vendor.description ?? '';
      _addressController.text = vendor.address;
      _pincodeController.text = vendor.pincode;
      _cityController.text = vendor.city;
      _deliveryRadius = vendor.deliveryRadiusKm;
      _phoneController.text = vendor.shopPhone ?? '';
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopNameTamilController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _minOrderController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'shop_name': _shopNameController.text.trim(),
        'shop_name_tamil': _shopNameTamilController.text.trim().isEmpty
            ? null
            : _shopNameTamilController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'city': _cityController.text.trim(),
        'delivery_radius_km': _deliveryRadius,
        'shop_phone': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      };

      if (_minOrderController.text.isNotEmpty) {
        data['min_order_amount'] =
            double.tryParse(_minOrderController.text.trim()) ?? 0;
      }

      // Upload banner image if picked
      if (_bannerImage != null) {
        final formData = FormData.fromMap({
          ...data,
          'shop_banner': await MultipartFile.fromFile(
            _bannerImage!.path,
            filename:
                'banner_${DateTime.now().millisecondsSinceEpoch}.${_bannerImage!.path.split('.').last}',
          ),
        });
        await ref.read(shopProvider.notifier).updateShop({
          ...data,
          '_formData': formData,
        });
      } else {
        await ref.read(shopProvider.notifier).updateShop(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop details updated successfully'),
            backgroundColor: VendorColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: ${e.toString()}'),
            backgroundColor: VendorColors.error,
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
      appBar: AppBar(title: const Text('Edit Shop Details')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner Image
              const Text(
                'Shop Banner',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ImagePickerWidget(
                currentImageUrl: ref
                    .read(shopProvider)
                    .valueOrNull
                    ?.fssaiDocUrl,
                onImagePicked: (file) => _bannerImage = file,
                height: 180,
                placeholderText: 'Tap to upload shop banner',
              ),

              const SizedBox(height: 20),

              // Shop Name (English)
              AppTextField(
                label: 'Shop Name (English)',
                controller: _shopNameController,
                hint: 'Enter your shop name',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Shop name is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Shop Name (Tamil)
              AppTextField(
                label: 'Shop Name (Tamil)',
                controller: _shopNameTamilController,
                hint: 'Enter shop name in Tamil (optional)',
              ),

              const SizedBox(height: 16),

              // Description
              AppTextField(
                label: 'Description',
                controller: _descriptionController,
                hint: 'Brief description of your shop',
                maxLines: 3,
                maxLength: 250,
              ),

              const SizedBox(height: 16),

              // Address
              AppTextField(
                label: 'Address',
                controller: _addressController,
                hint: 'Enter full address',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Pincode & City row
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Pincode',
                      controller: _pincodeController,
                      hint: '600001',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (value.trim().length != 6) {
                          return 'Invalid pincode';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'City',
                      controller: _cityController,
                      hint: 'Chennai',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Phone
              AppTextField(
                label: 'Shop Phone',
                controller: _phoneController,
                hint: 'Contact number',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // Delivery Radius Slider
              Text(
                'Delivery Radius: ${_deliveryRadius.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: VendorColors.primary,
                  inactiveTrackColor: VendorColors.primaryBg,
                  thumbColor: VendorColors.primary,
                  overlayColor: VendorColors.primary.withValues(alpha: 0.15),
                  valueIndicatorColor: VendorColors.primary,
                  showValueIndicator: ShowValueIndicator.always,
                ),
                child: Slider(
                  value: _deliveryRadius,
                  min: 1.0,
                  max: 20.0,
                  divisions: 38,
                  label: '${_deliveryRadius.toStringAsFixed(1)} km',
                  onChanged: (value) {
                    setState(() => _deliveryRadius = value);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Min Order Amount
              AppTextField(
                label: 'Minimum Order Amount (Rs)',
                controller: _minOrderController,
                hint: '0',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),

              // Save Button
              AppButton(
                label: 'Save Changes',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
