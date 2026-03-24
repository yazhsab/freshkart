import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/features/shop/providers/shop_provider.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_text_field.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_button.dart';
import 'package:freshkart_vendor/features/shared/widgets/loading_overlay.dart';

enum AccountType { savings, current }

class BankDetailsScreen extends ConsumerStatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  ConsumerState<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends ConsumerState<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _holderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _confirmAccountController = TextEditingController();
  final _ifscController = TextEditingController();

  AccountType _accountType = AccountType.savings;
  bool _isLoading = false;
  bool _isVerifyingIfsc = false;
  String? _ifscBankName;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final vendor = ref.read(shopProvider).valueOrNull;
    if (vendor != null) {
      _holderNameController.text = vendor.bankAccountHolderName ?? '';
      _accountNumberController.text = vendor.bankAccountNumber ?? '';
      _confirmAccountController.text = vendor.bankAccountNumber ?? '';
      _ifscController.text = vendor.bankIfsc ?? '';
    }
  }

  @override
  void dispose() {
    _holderNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _verifyIfsc() async {
    final ifsc = _ifscController.text.trim().toUpperCase();
    if (ifsc.length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IFSC code must be 11 characters'),
          backgroundColor: VendorColors.error,
        ),
      );
      return;
    }

    setState(() => _isVerifyingIfsc = true);

    try {
      // IFSC verification would typically call an API like razorpay.com/ifsc/{code}
      // For now, validate format: first 4 alpha, 5th is 0, last 6 alphanumeric
      final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
      if (ifscRegex.hasMatch(ifsc)) {
        setState(() {
          _ifscBankName = 'IFSC format valid';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IFSC code format is valid'),
            backgroundColor: VendorColors.primary,
          ),
        );
      } else {
        setState(() => _ifscBankName = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid IFSC format'),
            backgroundColor: VendorColors.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification failed: ${e.toString()}'),
          backgroundColor: VendorColors.error,
        ),
      );
    } finally {
      setState(() => _isVerifyingIfsc = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(shopProvider.notifier).updateBankDetails({
        'bank_account_holder': _holderNameController.text.trim(),
        'bank_account_number': _accountNumberController.text.trim(),
        'bank_ifsc': _ifscController.text.trim().toUpperCase(),
        'bank_account_type': _accountType == AccountType.savings
            ? 'savings'
            : 'current',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details updated successfully'),
            backgroundColor: VendorColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
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
      appBar: AppBar(title: const Text('Bank Details')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Warning card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF9A825),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please ensure all bank details are accurate. Incorrect details may cause payment delays. Payouts will be sent to this account.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Account Holder Name
              AppTextField(
                label: 'Account Holder Name',
                controller: _holderNameController,
                hint: 'As per bank records',
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Account holder name is required';
                  }
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
                    return 'Only letters and spaces allowed';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Account Number
              AppTextField(
                label: 'Account Number',
                controller: _accountNumberController,
                hint: 'Enter account number',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Account number is required';
                  }
                  final trimmed = value.trim();
                  if (trimmed.length < 9 || trimmed.length > 18) {
                    return 'Account number must be 9-18 digits';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
                    return 'Only digits allowed';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Confirm Account Number
              AppTextField(
                label: 'Confirm Account Number',
                controller: _confirmAccountController,
                hint: 'Re-enter account number',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please confirm account number';
                  }
                  if (value.trim() != _accountNumberController.text.trim()) {
                    return 'Account numbers do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // IFSC Code with Verify button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'IFSC Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: VendorColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _ifscController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[a-zA-Z0-9]'),
                            ),
                            LengthLimitingTextInputFormatter(11),
                            UpperCaseTextFormatter(),
                          ],
                          decoration: InputDecoration(
                            hintText: 'e.g. SBIN0001234',
                            hintStyle: const TextStyle(
                              color: VendorColors.textHint,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: VendorColors.fieldBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: VendorColors.primary,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: VendorColors.error,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'IFSC code is required';
                            }
                            if (value.trim().length != 11) {
                              return 'IFSC must be 11 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isVerifyingIfsc ? null : _verifyIfsc,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: VendorColors.primary,
                            side: const BorderSide(color: VendorColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isVerifyingIfsc
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: VendorColors.primary,
                                  ),
                                )
                              : const Text(
                                  'Verify',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (_ifscBankName != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _ifscBankName!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: VendorColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Account Type
              const Text(
                'Account Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<AccountType>(
                segments: const [
                  ButtonSegment<AccountType>(
                    value: AccountType.savings,
                    label: Text('Savings'),
                    icon: Icon(Icons.savings_rounded),
                  ),
                  ButtonSegment<AccountType>(
                    value: AccountType.current,
                    label: Text('Current'),
                    icon: Icon(Icons.account_balance_rounded),
                  ),
                ],
                selected: {_accountType},
                onSelectionChanged: (selected) {
                  setState(() => _accountType = selected.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return VendorColors.primaryBg;
                    }
                    return VendorColors.surface;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return VendorColors.primary;
                    }
                    return VendorColors.textSecondary;
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // Security note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VendorColors.primaryBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      color: VendorColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your bank details are encrypted and stored securely. Only authorized personnel can access them.',
                        style: TextStyle(
                          fontSize: 12,
                          color: VendorColors.primaryDark,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Save button
              AppButton(
                label: 'Save Bank Details',
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

/// Formatter that converts typed text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
