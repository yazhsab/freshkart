import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/colors.dart';
import '../shared/widgets/loading_shimmer.dart';
import '../shared/widgets/section_header.dart';
import 'config_provider.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  final _controllers = <String, TextEditingController>{};
  final _switchStates = <String, bool>{};
  Map<String, String> _original = {};
  bool _saving = false;

  // Config keys
  static const _groceryCommission = 'grocery_commission_pct';
  static const _serviceCommission = 'service_commission_pct';
  static const _deliveryFee = 'delivery_fee';
  static const _freeDeliveryAbove = 'free_delivery_above';
  static const _bookingFee = 'booking_fee';
  static const _autoConfirmTimeout = 'auto_confirm_timeout_mins';
  static const _maxDeliveryRadius = 'max_delivery_radius_km';
  static const _razorpayMode = 'razorpay_mode';
  static const _phonePeMode = 'phonepe_mode';
  static const _groceryAppStatus = 'grocery_app_status';
  static const _serviceAppStatus = 'service_app_status';
  static const _maintenanceMessage = 'maintenance_message';

  static const _allTextKeys = [
    _groceryCommission,
    _serviceCommission,
    _deliveryFee,
    _freeDeliveryAbove,
    _bookingFee,
    _autoConfirmTimeout,
    _maxDeliveryRadius,
    _razorpayMode,
    _phonePeMode,
    _maintenanceMessage,
  ];

  static const _allSwitchKeys = [
    _groceryAppStatus,
    _serviceAppStatus,
  ];

  TextEditingController _ctrl(String key) {
    return _controllers.putIfAbsent(
        key, () => TextEditingController(text: _original[key] ?? ''));
  }

  bool _sw(String key) {
    return _switchStates[key] ?? (_original[key] == 'active');
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasChanges {
    for (final key in _allTextKeys) {
      if (_ctrl(key).text != (_original[key] ?? '')) return true;
    }
    for (final key in _allSwitchKeys) {
      final origBool = (_original[key] ?? 'active') == 'active';
      if (_sw(key) != origBool) return true;
    }
    return false;
  }

  Map<String, String> get _changedValues {
    final changes = <String, String>{};
    for (final key in _allTextKeys) {
      final newVal = _ctrl(key).text;
      if (newVal != (_original[key] ?? '')) {
        changes[key] = newVal;
      }
    }
    for (final key in _allSwitchKeys) {
      final newVal = _sw(key) ? 'active' : 'inactive';
      if (newVal != (_original[key] ?? 'active')) {
        changes[key] = newVal;
      }
    }
    return changes;
  }

  @override
  Widget build(BuildContext context) {
    final asyncConfig = ref.watch(configProvider);

    return asyncConfig.when(
      loading: () => const LoadingShimmer(),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Failed to load config: $e'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref.read(configProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (config) {
        // Initialize original values on first load
        if (_original.isEmpty && config.isNotEmpty) {
          _original = Map.from(config);
          for (final key in _allTextKeys) {
            _ctrl(key).text = config[key] ?? '';
          }
          for (final key in _allSwitchKeys) {
            _switchStates[key] = (config[key] ?? 'active') == 'active';
          }
        }

        return Column(
          children: [
            SectionHeader(
              title: 'Platform Config',
              subtitle: 'Manage commission, fees, and operational settings',
              actions: [
                IconButton(
                  onPressed: () =>
                      ref.read(configProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Refresh',
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // 1. Commission & Fees
                    _ConfigSection(
                      title: 'Commission & Fees',
                      icon: Icons.percent_rounded,
                      children: [
                        _ConfigTextField(
                          label: 'Grocery Commission (%)',
                          controller: _ctrl(_groceryCommission),
                          suffix: '%',
                          keyboardType: TextInputType.number,
                          onChanged: () => setState(() {}),
                        ),
                        _ConfigTextField(
                          label: 'Service Commission (%)',
                          controller: _ctrl(_serviceCommission),
                          suffix: '%',
                          keyboardType: TextInputType.number,
                          onChanged: () => setState(() {}),
                        ),
                        _ConfigTextField(
                          label: 'Delivery Fee',
                          controller: _ctrl(_deliveryFee),
                          prefix: '\u20B9',
                          keyboardType: TextInputType.number,
                          onChanged: () => setState(() {}),
                        ),
                        _ConfigTextField(
                          label: 'Free Delivery Above',
                          controller: _ctrl(_freeDeliveryAbove),
                          prefix: '\u20B9',
                          keyboardType: TextInputType.number,
                          onChanged: () => setState(() {}),
                        ),
                        _ConfigTextField(
                          label: 'Booking Fee',
                          controller: _ctrl(_bookingFee),
                          prefix: '\u20B9',
                          keyboardType: TextInputType.number,
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 2. Operational Settings
                    _ConfigSection(
                      title: 'Operational Settings',
                      icon: Icons.settings_outlined,
                      children: [
                        _ConfigTextField(
                          label: 'Auto-Confirm Timeout (minutes)',
                          controller: _ctrl(_autoConfirmTimeout),
                          suffix: 'mins',
                          keyboardType: TextInputType.number,
                          onChanged: () => setState(() {}),
                        ),
                        _ConfigTextField(
                          label: 'Max Delivery Radius (km)',
                          controller: _ctrl(_maxDeliveryRadius),
                          suffix: 'km',
                          keyboardType: TextInputType.number,
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 3. Payment Settings
                    _ConfigSection(
                      title: 'Payment Settings',
                      icon: Icons.payment_outlined,
                      children: [
                        _ConfigTextField(
                          label: 'Razorpay Mode',
                          controller: _ctrl(_razorpayMode),
                          hint: 'test or live',
                          onChanged: () => setState(() {}),
                        ),
                        _ConfigTextField(
                          label: 'PhonePe Mode',
                          controller: _ctrl(_phonePeMode),
                          hint: 'test or live',
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // 4. App Maintenance
                    _ConfigSection(
                      title: 'App Maintenance',
                      icon: Icons.build_outlined,
                      initiallyExpanded: true,
                      children: [
                        _ConfigSwitchTile(
                          label: 'Grocery App Status',
                          subtitle: _sw(_groceryAppStatus)
                              ? 'App is live'
                              : 'App is in maintenance mode',
                          value: _sw(_groceryAppStatus),
                          onChanged: (v) =>
                              setState(() => _switchStates[_groceryAppStatus] = v),
                        ),
                        _ConfigSwitchTile(
                          label: 'Service App Status',
                          subtitle: _sw(_serviceAppStatus)
                              ? 'App is live'
                              : 'App is in maintenance mode',
                          value: _sw(_serviceAppStatus),
                          onChanged: (v) => setState(
                              () => _switchStates[_serviceAppStatus] = v),
                        ),
                        _ConfigTextField(
                          label: 'Maintenance Message',
                          controller: _ctrl(_maintenanceMessage),
                          maxLines: 3,
                          hint:
                              'Message shown when app is in maintenance mode',
                          onChanged: () => setState(() {}),
                        ),
                      ],
                    ),
                    const SizedBox(height: 100), // Space for sticky bar
                  ],
                ),
              ),
            ),
            // Sticky save bar
            if (_hasChanges)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border:
                      const Border(top: BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 18,
                        color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      '${_changedValues.length} unsaved change(s)',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {
                        // Reset to original
                        for (final key in _allTextKeys) {
                          _ctrl(key).text = _original[key] ?? '';
                        }
                        for (final key in _allSwitchKeys) {
                          _switchStates[key] =
                              (_original[key] ?? 'active') == 'active';
                        }
                        setState(() {});
                      },
                      child: const Text('Discard'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label:
                          Text(_saving ? 'Saving...' : 'Save Changes'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final changes = _changedValues;
      await ref.read(configProvider.notifier).saveConfig(changes);
      _original = {..._original, ...changes};
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Config section (ExpansionTile) ───────────────────────────────

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        shape: const Border(),
        collapsedShape: const Border(),
        children: children,
      ),
    );
  }
}

// ── Config text field ────────────────────────────────────────────

class _ConfigTextField extends StatelessWidget {
  const _ConfigTextField({
    required this.label,
    required this.controller,
    this.prefix,
    this.suffix,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String? prefix;
  final String? suffix;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix != null ? '$prefix ' : null,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          isDense: true,
        ),
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

// ── Config switch tile ───────────────────────────────────────────

class _ConfigSwitchTile extends StatelessWidget {
  const _ConfigSwitchTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label, style: const TextStyle(fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
        activeColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}
