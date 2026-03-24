import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/models/order_model.dart';
import 'package:freshkart_delivery/core/location/location_service.dart';
import 'package:freshkart_delivery/core/utils/date_util.dart';

class ActiveDeliveryCard extends ConsumerStatefulWidget {
  final DeliveryOrderModel order;

  const ActiveDeliveryCard({super.key, required this.order});

  @override
  ConsumerState<ActiveDeliveryCard> createState() => _ActiveDeliveryCardState();
}

class _ActiveDeliveryCardState extends ConsumerState<ActiveDeliveryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _openNavigation() async {
    final order = widget.order;
    double destLat;
    double destLng;

    // If pickup phase, navigate to vendor; if dropoff, navigate to customer
    if (order.isPickupPhase) {
      destLat = order.vendorLat;
      destLng = order.vendorLng;
    } else {
      destLat = order.customerLat;
      destLng = order.customerLng;
    }

    final url = LocationService.getGoogleMapsUrl(destLat, destLng);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateToDetail() {
    context.push('/delivery/${widget.order.id}');
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isPickup = order.isPickupPhase;

    return GestureDetector(
      onTap: _navigateToDetail,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: DeliveryColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: DeliveryColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Pulsing indicator
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            _pulseAnimation.value,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(
                                _pulseAnimation.value * 0.5,
                              ),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'ACTIVE DELIVERY',
                    style: GoogleFonts.notoSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${order.orderNumber}',
                      style: GoogleFonts.notoSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Vendor name
              Text(
                order.vendorName,
                style: GoogleFonts.notoSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Step indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPickup ? Icons.store_rounded : Icons.home_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPickup
                            ? 'Go to vendor for pickup'
                            : 'Deliver to customer',
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Step dots
                    Row(
                      children: [
                        _buildStepDot(true),
                        _buildStepConnector(),
                        _buildStepDot(!isPickup),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Destination info
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.white.withOpacity(0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isPickup ? order.vendorAddress : order.deliveryAddress,
                      style: GoogleFonts.notoSans(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (_hasDistanceInfo(order, isPickup)) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const SizedBox(width: 22),
                    if (isPickup && order.distanceToVendor != null)
                      Text(
                        '${order.distanceToVendor!.toStringAsFixed(1)} km',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (!isPickup && order.distanceToCustomer != null)
                      Text(
                        '${order.distanceToCustomer!.toStringAsFixed(1)} km',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (_hasEta(order, isPickup)) ...[
                      Text(
                        '  \u2022  ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'ETA ${DateUtil.formatEta(isPickup ? order.estimatedPickupMins! : order.estimatedDeliveryMins!)}',
                        style: GoogleFonts.notoSans(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Navigate',
                      icon: Icons.navigation_rounded,
                      onTap: _openNavigation,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'View Details',
                      icon: Icons.info_outline_rounded,
                      onTap: _navigateToDetail,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasDistanceInfo(DeliveryOrderModel order, bool isPickup) {
    if (isPickup) return order.distanceToVendor != null;
    return order.distanceToCustomer != null;
  }

  bool _hasEta(DeliveryOrderModel order, bool isPickup) {
    if (isPickup) return order.estimatedPickupMins != null;
    return order.estimatedDeliveryMins != null;
  }

  Widget _buildStepDot(bool isActive) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      width: 20,
      height: 2,
      color: Colors.white.withOpacity(0.4),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.notoSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
