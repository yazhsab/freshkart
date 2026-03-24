import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:freshkart_vendor/features/coupons/providers/coupon_provider.dart';

class CreateCouponScreen extends ConsumerStatefulWidget {
  const CreateCouponScreen({super.key});

  @override
  ConsumerState<CreateCouponScreen> createState() => _CreateCouponScreenState();
}

class _CreateCouponScreenState extends ConsumerState<CreateCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _minOrderAmountController = TextEditingController();
  final _perUserLimitController = TextEditingController();

  String _discountType = 'percentage';
  DateTime _validFrom = DateTime.now();
  DateTime _validUntil = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _discountValueController.dispose();
    _maxDiscountController.dispose();
    _minOrderAmountController.dispose();
    _perUserLimitController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final initial = isFrom ? _validFrom : _validUntil;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _validFrom = picked;
          if (_validUntil.isBefore(_validFrom)) {
            _validUntil = _validFrom.add(const Duration(days: 1));
          }
        } else {
          _validUntil = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'code': _codeController.text.trim().toUpperCase(),
      'title': _titleController.text.trim(),
      'discount_type': _discountType,
      'discount_value': double.parse(_discountValueController.text.trim()),
      'valid_from': _validFrom.toIso8601String(),
      'valid_until': _validUntil.toIso8601String(),
    };

    if (_maxDiscountController.text.trim().isNotEmpty) {
      data['max_discount'] = double.parse(_maxDiscountController.text.trim());
    }
    if (_minOrderAmountController.text.trim().isNotEmpty) {
      data['min_order_amount'] =
          double.parse(_minOrderAmountController.text.trim());
    }
    if (_perUserLimitController.text.trim().isNotEmpty) {
      data['per_user_limit'] = int.parse(_perUserLimitController.text.trim());
    }

    final success =
        await ref.read(couponsProvider.notifier).createCoupon(data);

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coupon created successfully!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create coupon. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Coupon'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Coupon Code',
                  hintText: 'e.g. FRESH20',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title / Description',
                  hintText: 'e.g. 20% off on first order',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _discountType,
                decoration: const InputDecoration(
                  labelText: 'Discount Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'percentage', child: Text('Percentage')),
                  DropdownMenuItem(
                      value: 'fixed', child: Text('Fixed Amount')),
                ],
                onChanged: (v) => setState(() => _discountType = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountValueController,
                decoration: InputDecoration(
                  labelText: 'Discount Value',
                  suffixText: _discountType == 'percentage' ? '%' : '\u20B9',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Enter a valid value';
                  if (_discountType == 'percentage' && val > 100) {
                    return 'Cannot exceed 100%';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_discountType == 'percentage')
                TextFormField(
                  controller: _maxDiscountController,
                  decoration: const InputDecoration(
                    labelText: 'Max Discount (\u20B9) (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              if (_discountType == 'percentage') const SizedBox(height: 16),
              TextFormField(
                controller: _minOrderAmountController,
                decoration: const InputDecoration(
                  labelText: 'Min Order Amount (\u20B9) (Optional)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _perUserLimitController,
                decoration: const InputDecoration(
                  labelText: 'Per User Limit (Optional)',
                  hintText: 'e.g. 1',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Valid From',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(dateFormat.format(_validFrom)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Valid Until',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(dateFormat.format(_validUntil)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Create Coupon',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
