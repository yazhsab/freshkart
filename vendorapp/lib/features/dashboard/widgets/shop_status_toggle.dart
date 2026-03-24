import 'package:flutter/material.dart';
import 'package:freshkart_vendor/core/theme/app_colors.dart';

class ShopStatusToggle extends StatelessWidget {
  final bool isOpen;
  final ValueChanged<bool> onToggle;
  final bool isLoading;

  const ShopStatusToggle({
    super.key,
    required this.isOpen,
    required this.onToggle,
    this.isLoading = false,
  });

  void _handleToggle(BuildContext context, bool value) {
    // If turning ON outside working hours (before 6 AM or after 11 PM), warn
    if (value) {
      final hour = TimeOfDay.now().hour;
      if (hour < 6 || hour >= 23) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Outside Working Hours'),
            content: const Text(
              'It is currently outside typical working hours (6 AM - 11 PM). '
              'Are you sure you want to go online?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onToggle(value);
                },
                child: const Text('Go Online'),
              ),
            ],
          ),
        );
        return;
      }
    }
    onToggle(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isOpen
            ? VendorColors.primaryLight.withValues(alpha: 0.1)
            : VendorColors.textSecondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOpen ? VendorColors.primaryLight : VendorColors.divider,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Status indicator dot
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOpen ? VendorColors.primaryLight : VendorColors.disabled,
              boxShadow: isOpen
                  ? [
                      BoxShadow(
                        color: VendorColors.primaryLight.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SHOP STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: VendorColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isOpen
                      ? 'OPEN \u2022 Accepting orders'
                      : 'CLOSED \u2022 Not accepting orders',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isOpen
                        ? VendorColors.primary
                        : VendorColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Toggle
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Transform.scale(
              scale: 1.2,
              child: Switch.adaptive(
                value: isOpen,
                onChanged: (v) => _handleToggle(context, v),
                activeColor: VendorColors.primary,
                activeTrackColor: VendorColors.primaryLight.withValues(
                  alpha: 0.4,
                ),
                inactiveThumbColor: VendorColors.textSecondary,
                inactiveTrackColor: VendorColors.divider,
              ),
            ),
        ],
      ),
    );
  }
}
