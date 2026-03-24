import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/service_category.dart';
import 'service_catalog_provider.dart';

class AddEditServiceDialog extends ConsumerStatefulWidget {
  const AddEditServiceDialog({super.key, this.service});

  final ServiceCategory? service;

  @override
  ConsumerState<AddEditServiceDialog> createState() =>
      _AddEditServiceDialogState();
}

class _AddEditServiceDialogState extends ConsumerState<AddEditServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _nameTamilController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _durationController;
  late final TextEditingController _sortOrderController;
  late String _priceType;
  late bool _isActive;
  bool _saving = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nameController = TextEditingController(text: s?.name ?? '');
    _nameTamilController = TextEditingController(text: s?.nameTamil ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _basePriceController =
        TextEditingController(text: s?.basePrice?.toStringAsFixed(0) ?? '');
    _durationController =
        TextEditingController(text: '${s?.estimatedDurationMins ?? 60}');
    _sortOrderController =
        TextEditingController(text: '${s?.sortOrder ?? 0}');
    _priceType = s?.priceType ?? 'fixed';
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameTamilController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _durationController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'name': _nameController.text.trim(),
      'name_tamil': _nameTamilController.text.trim().isEmpty
          ? null
          : _nameTamilController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'base_price': _basePriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_basePriceController.text.trim()),
      'price_type': _priceType,
      'estimated_duration_mins':
          int.tryParse(_durationController.text.trim()) ?? 60,
      'sort_order': int.tryParse(_sortOrderController.text.trim()) ?? 0,
      'is_active': _isActive,
    };

    try {
      final actions = ref.read(serviceCatalogActionsProvider.notifier);
      if (_isEditing) {
        await actions.updateService(widget.service!.id, data);
      } else {
        await actions.addService(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final dialogWidth = width > 600 ? 520.0 : width * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Service' : 'Add Service',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Name EN
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Service Name (English)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Name Tamil
                TextFormField(
                  controller: _nameTamilController,
                  decoration: const InputDecoration(
                    labelText: 'Service Name (Tamil)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Base Price
                TextFormField(
                  controller: _basePriceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Base Price (INR)',
                    prefixText: '\u20B9 ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Price Type
                const Text(
                  'Price Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'fixed', label: Text('Fixed')),
                    ButtonSegment(value: 'variable', label: Text('Variable')),
                    ButtonSegment(
                        value: 'on_inspection', label: Text('On Inspection')),
                  ],
                  selected: {_priceType},
                  onSelectionChanged: (val) =>
                      setState(() => _priceType = val.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(
                      const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Duration + Sort Order row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Duration (mins)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final val = int.tryParse(v.trim());
                          if (val == null || val <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _sortOrderController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Sort Order',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Active toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text('Service is visible to customers'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  activeColor: AppColors.primary,
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isEditing ? 'Update Service' : 'Add Service'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
