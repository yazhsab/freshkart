import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/storage/local_storage.dart';

class DeliveryMapWidget extends StatelessWidget {
  final String destName;
  final double destLat;
  final double destLng;
  final Color pinColor;
  final bool isVendor;
  final double? distanceKm;
  final int? estimatedMins;

  const DeliveryMapWidget({
    super.key,
    required this.destName,
    required this.destLat,
    required this.destLng,
    required this.pinColor,
    this.isVendor = true,
    this.distanceKm,
    this.estimatedMins,
  });

  Future<void> _openInMaps(BuildContext context) async {
    _showMapsChoice(context);
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
                'Open in Maps',
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
                  LocalStorage.setPreferredMapsApp('google');
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
                  LocalStorage.setPreferredMapsApp('ola');
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DeliveryColors.primaryBg,
            DeliveryColors.primaryLight.withOpacity(0.15),
            DeliveryColors.primaryBg.withOpacity(0.5),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPatternPainter(
                color: DeliveryColors.primaryLight.withOpacity(0.08),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Pin icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: pinColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVendor ? Icons.store_rounded : Icons.home_rounded,
                    color: pinColor,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 12),

                // Destination name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    destName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DeliveryColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Distance + ETA
                if (distanceKm != null || estimatedMins != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (distanceKm != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: DeliveryColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                  fontWeight: FontWeight.w700,
                                  color: DeliveryColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (distanceKm != null && estimatedMins != null)
                        const SizedBox(width: 8),
                      if (estimatedMins != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: DeliveryColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: DeliveryColors.stepPickup,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '~$estimatedMins min',
                                style: GoogleFonts.notoSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: DeliveryColors.stepPickup,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),

                const SizedBox(height: 16),

                // Open in Maps button
                ElevatedButton.icon(
                  onPressed: () => _openInMaps(context),
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: Text(
                    'Open in Maps',
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DeliveryColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  final Color color;

  _MapPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
