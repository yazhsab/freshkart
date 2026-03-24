import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/utils/currency_util.dart';
import 'package:freshkart_vendor/core/api/api_client.dart';
import 'package:freshkart_vendor/core/api/api_endpoints.dart';
import 'package:freshkart_vendor/core/config/app_config.dart';
import 'package:freshkart_vendor/core/models/product_model.dart';
import 'package:freshkart_vendor/core/models/category_model.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_text_field.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_button.dart';
import 'package:freshkart_vendor/features/shared/widgets/image_picker_widget.dart';
import 'package:freshkart_vendor/features/shared/widgets/loading_overlay.dart';
import 'package:freshkart_vendor/features/inventory/providers/inventory_provider.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final String? productId;

  const AddEditProductScreen({super.key, this.productId});

  bool get isEditing => productId != null;

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _nameTamilController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _mrpController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _lowStockController = TextEditingController(text: '5');
  final _customUnitController = TextEditingController();

  String? _selectedCategoryId;
  String _selectedUnit = '1 kg';
  bool _isAvailable = true;
  File? _pickedImage;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _errorMessage;
  ProductModel? _existingProduct;

  static const List<String> _unitOptions = [
    '1 kg',
    '500 g',
    '250 g',
    '100 g',
    '1 litre',
    '500 ml',
    '1 dozen',
    '6 pieces',
    '1 piece',
    '1 bundle',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadProduct();
    }
  }

  void _loadProduct() {
    final state = ref.read(inventoryProvider);
    final product = state.products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => throw StateError('Product not found'),
    );

    _existingProduct = product;
    _nameController.text = product.name;
    _nameTamilController.text = product.nameTamil ?? '';
    _descriptionController.text = product.description ?? '';
    _priceController.text = product.price.toStringAsFixed(2);
    if (product.mrp != null) {
      _mrpController.text = product.mrp!.toStringAsFixed(2);
    }
    _stockController.text = product.stockQuantity.toString();
    _lowStockController.text = product.lowStockThreshold.toString();
    _selectedCategoryId = product.categoryId;
    _isAvailable = product.isAvailable;

    if (_unitOptions.contains(product.unit)) {
      _selectedUnit = product.unit;
    } else {
      _selectedUnit = 'custom';
      _customUnitController.text = product.unit;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameTamilController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _mrpController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    _customUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: VendorColors.background,
        appBar: AppBar(
          title: Text(
            widget.isEditing ? 'Edit Product' : 'Add Product',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: VendorColors.textPrimary,
            ),
          ),
          backgroundColor: VendorColors.surface,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: VendorColors.textPrimary,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Error message
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: VendorColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: VendorColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),

              // IMAGE SECTION
              _buildSectionHeader('Product Image'),
              const SizedBox(height: 8),
              ImagePickerWidget(
                height: 200,
                currentImageUrl: _existingProduct?.imageUrl,
                onImagePicked: (file) {
                  setState(() => _pickedImage = file);
                },
                placeholderText: 'Tap to add product image',
              ),
              if (_isUploading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: VendorColors.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      VendorColors.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // BASIC INFO SECTION
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Product Name (English)',
                controller: _nameController,
                hint: 'e.g., Tomato',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Product Name (Tamil)',
                controller: _nameTamilController,
                hint:
                    '\u0B89\u0BA4\u0BBE\u0BB0\u0BA3\u0BAE\u0BCD: \u0BA4\u0B95\u0BCD\u0B95\u0BBE\u0BB3\u0BBF',
              ),
              const SizedBox(height: 16),

              // Category dropdown
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              categories.when(
                data: (cats) => DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    hintText: 'Select category',
                    hintStyle: const TextStyle(
                      color: VendorColors.textHint,
                      fontSize: 15,
                    ),
                    filled: true,
                    fillColor: VendorColors.fieldBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: cats.map((cat) {
                    return DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                  validator: (val) {
                    if (val == null) return 'Please select a category';
                    return null;
                  },
                ),
                loading: () =>
                    const LinearProgressIndicator(color: VendorColors.primary),
                error: (e, _) => Text(
                  'Failed to load categories',
                  style: TextStyle(color: VendorColors.error),
                ),
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Description',
                controller: _descriptionController,
                hint: 'Brief product description',
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 24),

              // PRICING SECTION
              _buildSectionHeader('Pricing'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Selling Price',
                      controller: _priceController,
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Text(
                          '\u20B9',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: VendorColors.textPrimary,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Price required';
                        }
                        final price = double.tryParse(val);
                        if (price == null || price < 1) {
                          return 'Min \u20B91';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'MRP (optional)',
                      controller: _mrpController,
                      hint: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Text(
                          '\u20B9',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: VendorColors.textPrimary,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        final mrp = double.tryParse(val);
                        final price =
                            double.tryParse(_priceController.text) ?? 0;
                        if (mrp != null && mrp < price) {
                          return 'MRP must be >= price';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              // Discount preview
              _buildDiscountPreview(),
              const SizedBox(height: 24),

              // UNIT SECTION
              _buildSectionHeader('Unit'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: InputDecoration(
                  hintText: 'Select unit',
                  filled: true,
                  fillColor: VendorColors.fieldBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _unitOptions.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit == 'custom' ? 'Custom unit' : unit),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedUnit = val ?? '1 kg');
                },
              ),
              if (_selectedUnit == 'custom') ...[
                const SizedBox(height: 12),
                AppTextField(
                  controller: _customUnitController,
                  hint: 'e.g., 2 kg pack',
                  validator: (val) {
                    if (_selectedUnit == 'custom' &&
                        (val == null || val.trim().isEmpty)) {
                      return 'Custom unit is required';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),

              // STOCK SECTION
              _buildSectionHeader('Stock'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Current Quantity',
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        final qty = int.tryParse(val);
                        if (qty == null || qty < 0 || qty > 9999) {
                          return '0-9999';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextField(
                          label: 'Low Stock Alert',
                          controller: _lowStockController,
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Required';
                            }
                            final threshold = int.tryParse(val);
                            if (threshold == null || threshold < 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Alert when stock falls below this',
                          style: TextStyle(
                            fontSize: 11,
                            color: VendorColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // AVAILABILITY SECTION
              _buildSectionHeader('Availability'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: VendorColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: VendorColors.divider),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available to customers',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: VendorColors.textPrimary,
                      ),
                    ),
                    Switch.adaptive(
                      value: _isAvailable,
                      onChanged: (val) => setState(() => _isAvailable = val),
                      activeColor: VendorColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // SAVE BUTTON
              AppButton(
                label: widget.isEditing ? 'Save Changes' : 'Add Product',
                isLoading: _isLoading,
                icon: widget.isEditing ? Icons.save_rounded : Icons.add_rounded,
                onPressed: _isLoading ? null : _handleSave,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: VendorColors.textPrimary,
      ),
    );
  }

  Widget _buildDiscountPreview() {
    final price = double.tryParse(_priceController.text);
    final mrp = double.tryParse(_mrpController.text);

    if (price != null && mrp != null && mrp > price) {
      final discount = ((mrp - price) / mrp * 100).toStringAsFixed(0);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: VendorColors.primaryBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.local_offer_rounded,
                size: 16,
                color: VendorColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Customers see: ${CurrencyUtil.formatPrice(price)} ($discount% off)',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final unit = _selectedUnit == 'custom'
          ? _customUnitController.text.trim()
          : _selectedUnit;

      final data = {
        'name': _nameController.text.trim(),
        'name_tamil': _nameTamilController.text.trim().isNotEmpty
            ? _nameTamilController.text.trim()
            : null,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'category_id': _selectedCategoryId,
        'price': double.parse(_priceController.text.trim()),
        'mrp': _mrpController.text.trim().isNotEmpty
            ? double.parse(_mrpController.text.trim())
            : null,
        'unit': unit,
        'stock_quantity': int.parse(_stockController.text.trim()),
        'low_stock_threshold': int.parse(_lowStockController.text.trim()),
        'is_available': _isAvailable,
      };

      final notifier = ref.read(inventoryProvider.notifier);

      if (widget.isEditing) {
        await notifier.updateProduct(widget.productId!, data);
      } else {
        await notifier.addProduct(data);
      }

      // Upload image if picked
      final productId = widget.isEditing
          ? widget.productId!
          : ref.read(inventoryProvider).products.first.id;

      if (_pickedImage != null) {
        await _uploadImage(productId);
      }

      final providerState = ref.read(inventoryProvider);
      if (providerState.error != null) {
        setState(() {
          _errorMessage = providerState.error;
          _isLoading = false;
        });
        return;
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImage(String productId) async {
    setState(() => _isUploading = true);

    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          _pickedImage!.path,
          filename: 'product_$productId.jpg',
        ),
      });

      await ApiClient.instance.postFormData(
        VendorApiEndpoints.productImage(productId),
        formData: formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            setState(() => _uploadProgress = sent / total);
          }
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Image upload failed: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0;
      });
    }
  }
}
