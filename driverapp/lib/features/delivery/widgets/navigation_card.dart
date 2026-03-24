import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/storage/local_storage.dart';
import 'package:freshkart_delivery/features/delivery/providers/delivery_provider.dart';

class NavigationCard extends StatelessWidget {
  final DeliveryPhase currentPhase;
  final String destinationName;
  final String destinationAddress;
  final String? landmark;
  final double? distanceKm;
  final int? estimatedMins;
  final String? phoneNumber;
  final String? phoneLabel;
  final double destLat;
  final double destLng;
  final VoidCallback? onReachedPressed;
  final String? reachedButtonLabel;
  final Widget? extraContent;

  const NavigationCard({
    super.key,
    required this.currentPhase,
    required this.destinationName,
    required this.destinationAddress,
    this.landmark,
    this.distanceKm,
    this.estimatedMins,
    this.phoneNumber,
    this.phoneLabel,
    required this.destLat,
    required this.destLng,
    this.onReachedPressed,
    this.reachedButtonLabel,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DeliveryColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Step indicator
            _StepIndicator(currentPhase: currentPhase),

            const SizedBox(height: 20),

            // Destination name
            Text(
              destinationName,
              style: GoogleFonts.notoSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: DeliveryColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: DeliveryColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    destinationAddress,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: DeliveryColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            // Landmark
            if (landmark != null && landmark!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 24),
                  Icon(
                    Icons.flag_outlined,
                    size: 14,
                    color: DeliveryColors.textSecondary.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Landmark: $landmark',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: DeliveryColors.textSecondary.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Distance + ETA row
            if (distanceKm != null || estimatedMins != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DeliveryColors.primaryBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (distanceKm != null) ...[
                      Icon(
                        Icons.straighten_rounded,
                        size: 16,
                        color: DeliveryColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm!.toStringAsFixed(1)} km',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DeliveryColors.primary,
                        ),
                      ),
                    ],
                    if (distanceKm != null && estimatedMins != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 16,
                        color: DeliveryColors.divider,
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (estimatedMins != null) ...[
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: DeliveryColors.stepPickup,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '~$estimatedMins mins',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DeliveryColors.stepPickup,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Action buttons row
            Row(
              children: [
                // Call button
                if (phoneNumber != null && phoneNumber!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _makeCall(phoneNumber!),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: Text(
                        phoneLabel ?? 'Call',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DeliveryColors.primary,
                        side: const BorderSide(
                          color: DeliveryColors.primary,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                if (phoneNumber != null && phoneNumber!.isNotEmpty)
                  const SizedBox(width: 12),

                // Navigate button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showMapsChoice(context),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: Text(
                      'Navigate',
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DeliveryColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),

            // Extra content (expandable items, payment info, etc.)
            if (extraContent != null) ...[
              const SizedBox(height: 16),
              extraContent!,
            ],

            // Reached button
            if (onReachedPressed != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onReachedPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DeliveryColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    reachedButtonLabel ?? "I've reached",
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showMapsChoice(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Navigate with',
                style: GoogleFonts.notoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DeliveryColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue, size: 28),
                title: Text(
                  'Google Maps',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchGoogleMaps();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.navigation,
                  color: Colors.green,
                  size: 28,
                ),
                title: Text(
                  'Ola Maps',
                  style: GoogleFonts.notoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _launchOlaMaps();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchGoogleMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchOlaMaps() async {
    final url = Uri.parse(
      'https://maps.olacabs.com/?dest_lat=$destLat&dest_lng=$destLng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final DeliveryPhase currentPhase;

  const _StepIndicator({required this.currentPhase});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepData(
        icon: Icons.location_on_rounded,
        label: 'Pickup',
        isCompleted: currentPhase.index > DeliveryPhase.goingToVendor.index,
        isCurrent: currentPhase == DeliveryPhase.goingToVendor,
      ),
      _StepData(
        icon: Icons.check_circle_rounded,
        label: 'OTP',
        isCompleted: currentPhase.index > DeliveryPhase.pickupOtp.index,
        isCurrent: currentPhase == DeliveryPhase.pickupOtp,
      ),
      _StepData(
        icon: Icons.local_shipping_rounded,
        label: 'Deliver',
        isCompleted: currentPhase.index > DeliveryPhase.goingToCustomer.index,
        isCurrent: currentPhase == DeliveryPhase.goingToCustomer,
      ),
      _StepData(
        icon: Icons.check_circle_rounded,
        label: 'Done',
        isCompleted: currentPhase == DeliveryPhase.completed,
        isCurrent: currentPhase == DeliveryPhase.deliveryOtp,
      ),
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepBefore = steps[index ~/ 2];
          return Expanded(
            child: Container(
              height: 2,
              color: stepBefore.isCompleted
                  ? DeliveryColors.stepDone
                  : DeliveryColors.divider,
            ),
          );
        }

        final step = steps[index ~/ 2];
        return _StepDot(step: step);
      }),
    );
  }
}

class _StepData {
  final IconData icon;
  final String label;
  final bool isCompleted;
  final bool isCurrent;

  _StepData({
    required this.icon,
    required this.label,
    required this.isCompleted,
    required this.isCurrent,
  });
}

class _StepDot extends StatelessWidget {
  final _StepData step;

  const _StepDot({required this.step});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;

    if (step.isCompleted) {
      bgColor = DeliveryColors.stepDone;
      iconColor = Colors.white;
    } else if (step.isCurrent) {
      bgColor = DeliveryColors.stepActive;
      iconColor = Colors.white;
    } else {
      bgColor = DeliveryColors.divider;
      iconColor = DeliveryColors.textSecondary;
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: step.isCurrent
                ? [
                    BoxShadow(
                      color: DeliveryColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(step.icon, size: 18, color: iconColor),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: GoogleFonts.notoSans(
            fontSize: 10,
            fontWeight: step.isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: step.isCurrent || step.isCompleted
                ? DeliveryColors.textPrimary
                : DeliveryColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
