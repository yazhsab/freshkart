import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';

class AddressCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String address;
  final String? landmark;
  final double? distanceKm;
  final VoidCallback? onTap;

  const AddressCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.address,
    this.landmark,
    this.distanceKm,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DeliveryColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DeliveryColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),

            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DeliveryColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      color: DeliveryColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (landmark != null && landmark!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          size: 12,
                          color: DeliveryColors.textSecondary.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            landmark!,
                            style: GoogleFonts.notoSans(
                              fontSize: 12,
                              color: DeliveryColors.textSecondary.withOpacity(
                                0.7,
                              ),
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Distance badge
            if (distanceKm != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: DeliveryColors.primaryBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${distanceKm!.toStringAsFixed(1)} km',
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DeliveryColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
