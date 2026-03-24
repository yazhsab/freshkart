import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/theme/app_colors.dart';

class BannerData {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;

  const BannerData({
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    this.icon = Icons.local_offer_rounded,
  });
}

class HeroBanner extends StatefulWidget {
  final List<BannerData>? banners;

  const HeroBanner({super.key, this.banners});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  int _currentIndex = 0;

  static const _defaultBanners = [
    BannerData(
      title: 'Curated weekly essentials',
      subtitle: 'Fresh produce, premium staples and fast delivery slots.',
      gradientColors: [Color(0xFF0A3B2C), Color(0xFF0F7A5C), Color(0xFF3CCB98)],
      icon: Icons.celebration_rounded,
    ),
    BannerData(
      title: 'Free delivery above \u20B9299',
      subtitle: 'Stack your everyday basket and unlock zero delivery charges.',
      gradientColors: [Color(0xFF0C5A43), Color(0xFF26A269), Color(0xFF61D7A8)],
      icon: Icons.delivery_dining_rounded,
    ),
    BannerData(
      title: 'Book polished home services',
      subtitle: 'Cleaner, electrical, plumbing and appliance care in one tap.',
      gradientColors: [Color(0xFFE7892A), Color(0xFFF0A33A), Color(0xFFFFC86E)],
      icon: Icons.home_repair_service_rounded,
    ),
  ];

  List<BannerData> get _banners => widget.banners ?? _defaultBanners;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final height = isWide ? 214.0 : 188.0;

        return Column(
          children: [
            CarouselSlider.builder(
              itemCount: _banners.length,
              itemBuilder: (context, index, realIndex) {
                return _buildBannerCard(
                  _banners[index],
                  isWide: isWide,
                  height: height,
                );
              },
              options: CarouselOptions(
                height: height,
                viewportFraction: isWide ? 0.86 : 0.94,
                enlargeCenterPage: true,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                autoPlayAnimationDuration: const Duration(milliseconds: 650),
                onPageChanged: (index, reason) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSmoothIndicator(
              activeIndex: _currentIndex,
              count: _banners.length,
              effect: ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3,
                activeDotColor: AppColors.primaryGreen,
                dotColor: AppColors.divider,
                spacing: 6,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBannerCard(
    BannerData banner, {
    required bool isWide,
    required double height,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: banner.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: banner.gradientColors.first.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -28,
            right: -8,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: isWide ? 220 : 120,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'FreshKart spotlight',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        banner.title,
                        style: TextStyle(
                          fontSize: isWide ? 28 : 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        banner.subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.84),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              banner.icon == Icons.home_repair_service_rounded
                                  ? 'Book now'
                                  : 'Shop now',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: banner.gradientColors.first,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Curated for today',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Container(
                  width: isWide ? 110 : 84,
                  height: isWide ? height - 26 : 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    banner.icon,
                    color: Colors.white,
                    size: isWide ? 48 : 38,
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
