import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/features/profile/providers/profile_provider.dart';
import 'package:freshkart_delivery/features/shared/widgets/network_image_widget.dart';

class VehicleDetailsScreen extends ConsumerWidget {
  const VehicleDetailsScreen({super.key});

  IconData _vehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'bicycle':
        return Icons.pedal_bike;
      case 'scooter':
      case 'bike':
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'car':
      case 'four_wheeler':
        return Icons.directions_car;
      case 'van':
        return Icons.airport_shuttle;
      default:
        return Icons.two_wheeler;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);
    final agent = state.agent;

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      appBar: AppBar(
        title: Text(
          'Vehicle Details',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: DeliveryColors.surface,
        foregroundColor: DeliveryColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: agent == null
          ? Center(
              child: Text(
                'No vehicle details available',
                style: GoogleFonts.notoSans(
                  color: DeliveryColors.textSecondary,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: DeliveryColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DeliveryColors.divider),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: DeliveryColors.primaryBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _vehicleIcon(agent.vehicleType),
                            size: 40,
                            color: DeliveryColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          agent.vehicleDisplay,
                          style: GoogleFonts.notoSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: DeliveryColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: DeliveryColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: DeliveryColors.divider),
                          ),
                          child: Text(
                            agent.vehicleNumber,
                            style: GoogleFonts.notoSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: DeliveryColors.textPrimary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DeliveryColors.primaryBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DeliveryColors.primaryLight.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: DeliveryColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'To update vehicle details, please contact support. Changes require verification of new vehicle documents.',
                            style: GoogleFonts.notoSans(
                              fontSize: 13,
                              color: DeliveryColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'VEHICLE REGISTRATION',
                    style: GoogleFonts.notoSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DeliveryColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: DeliveryColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DeliveryColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: NetworkImageWidget(
                            imageUrl: agent.vehicleDocUrl,
                            width: double.infinity,
                            height: 200,
                            borderRadius: 0,
                            errorIcon: Icons.description_outlined,
                            errorIconSize: 48,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                agent.vehicleDocUrl != null
                                    ? Icons.check_circle
                                    : Icons.warning_amber,
                                size: 18,
                                color: agent.vehicleDocUrl != null
                                    ? DeliveryColors.online
                                    : DeliveryColors.warning,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                agent.vehicleDocUrl != null
                                    ? 'Vehicle RC uploaded'
                                    : 'Vehicle RC not uploaded',
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: agent.vehicleDocUrl != null
                                      ? DeliveryColors.online
                                      : DeliveryColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
