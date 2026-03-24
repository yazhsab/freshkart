import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/features/shop/providers/shop_provider.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_button.dart';
import 'package:freshkart_vendor/features/shared/widgets/loading_overlay.dart';

class WorkingHoursScreen extends ConsumerStatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  ConsumerState<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends ConsumerState<WorkingHoursScreen> {
  static const _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _dayNames = {
    'Mon': 'Monday',
    'Tue': 'Tuesday',
    'Wed': 'Wednesday',
    'Thu': 'Thursday',
    'Fri': 'Friday',
    'Sat': 'Saturday',
    'Sun': 'Sunday',
  };

  late Map<String, bool> _activeDays;
  late Map<String, TimeOfDay> _openingTimes;
  late Map<String, TimeOfDay> _closingTimes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initFromVendor();
  }

  void _initFromVendor() {
    final vendor = ref.read(shopProvider).valueOrNull;
    final workingDays =
        vendor?.workingDays ?? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final openTime = _parseTime(vendor?.openingTime ?? '09:00');
    final closeTime = _parseTime(vendor?.closingTime ?? '21:00');

    _activeDays = {};
    _openingTimes = {};
    _closingTimes = {};

    for (final day in _allDays) {
      _activeDays[day] = workingDays.contains(day);
      _openingTimes[day] = openTime;
      _closingTimes[day] = closeTime;
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatTimeDisplay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime(String day, bool isOpening) async {
    final initial = isOpening ? _openingTimes[day]! : _closingTimes[day]!;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
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
          _openingTimes[day] = picked;
        } else {
          _closingTimes[day] = picked;
        }
      });
    }
  }

  void _applyToAllDays() {
    final firstActive = _allDays.firstWhere(
      (d) => _activeDays[d] == true,
      orElse: () => 'Mon',
    );
    final openTime = _openingTimes[firstActive]!;
    final closeTime = _closingTimes[firstActive]!;

    setState(() {
      for (final day in _allDays) {
        _openingTimes[day] = openTime;
        _closingTimes[day] = closeTime;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Applied timings to all days'),
        backgroundColor: VendorColors.primary,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final activeDaysList = _allDays
          .where((d) => _activeDays[d] == true)
          .toList();

      if (activeDaysList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one working day'),
            backgroundColor: VendorColors.error,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      // Use the first active day's time as the global opening/closing time
      final firstActive = activeDaysList.first;

      await ref.read(shopProvider.notifier).updateWorkingHours({
        'opening_time': _formatTime(_openingTimes[firstActive]!),
        'closing_time': _formatTime(_closingTimes[firstActive]!),
        'working_days': activeDaysList,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Working hours updated'),
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
      appBar: AppBar(title: const Text('Working Hours')),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VendorColors.primaryBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: VendorColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Set your shop\'s working hours for each day. Toggle days off if you don\'t operate.',
                            style: TextStyle(
                              fontSize: 13,
                              color: VendorColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Apply to all days button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _applyToAllDays,
                      icon: const Icon(Icons.copy_all_rounded, size: 18),
                      label: const Text('Apply to all days'),
                      style: TextButton.styleFrom(
                        foregroundColor: VendorColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Day rows
                  ..._allDays.map((day) => _buildDayRow(day)),
                ],
              ),
            ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: 'Save Working Hours',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayRow(String day) {
    final isActive = _activeDays[day] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? VendorColors.surface : VendorColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? VendorColors.divider : VendorColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 80,
            child: Text(
              _dayNames[day] ?? day,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? VendorColors.textPrimary
                    : VendorColors.textHint,
              ),
            ),
          ),

          // Toggle
          Switch(
            value: isActive,
            onChanged: (value) {
              setState(() => _activeDays[day] = value);
            },
            activeColor: VendorColors.primary,
          ),

          const Spacer(),

          // Time buttons
          if (isActive) ...[
            _buildTimeChip(
              _formatTimeDisplay(_openingTimes[day]!),
              () => _pickTime(day, true),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '-',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: VendorColors.textSecondary,
                ),
              ),
            ),
            _buildTimeChip(
              _formatTimeDisplay(_closingTimes[day]!),
              () => _pickTime(day, false),
            ),
          ] else
            Text(
              'Closed',
              style: TextStyle(
                fontSize: 13,
                color: VendorColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: VendorColors.primaryBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: VendorColors.primary,
          ),
        ),
      ),
    );
  }
}
