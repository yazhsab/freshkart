import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/models/service_category_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/category_grid.dart';
import '../widgets/hero_banner.dart';
import '../widgets/product_card.dart';
import '../widgets/section_header.dart';
import '../widgets/vendor_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);
    final cartState = ref.watch(cartProvider);
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 1440
        ? 1280.0
        : width >= 1100
        ? 1180.0
        : width >= 760
        ? 960.0
        : double.infinity;
    final sidePadding = width >= 760 ? 24.0 : 16.0;
    final productColumns = width >= 1320
        ? 4
        : width >= 980
        ? 3
        : 2;
    final serviceColumns = width >= 1320
        ? 4
        : width >= 920
        ? 3
        : 2;
    final openStores = state.nearbyVendors
        .where((vendor) => vendor.isOpen)
        .length;
    final spotlightDeals = state.featuredProducts
        .where((product) => product.discountPercentage > 0)
        .length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => ref.read(homeProvider.notifier).initialize(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(sidePadding, 12, sidePadding, 120),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeTopBar(
                            city: state.city,
                            isLoadingLocation: state.isLoadingLocation,
                            cartCount: cartState.totalItems,
                            onLocationTap: () {
                              ref.read(homeProvider.notifier).refreshLocation();
                            },
                          ),
                          const SizedBox(height: 18),
                          _HeroPanel(
                            title:
                                '${_greetingText()}, ${state.city ?? 'FreshKart'}',
                            subtitle:
                                'A richer grocery and home services experience with premium discovery, sharper recommendations and one-tap convenience.',
                            primaryMetricValue: '$openStores',
                            primaryMetricLabel: 'Open stores',
                            secondaryMetricValue:
                                '${state.featuredProducts.length}',
                            secondaryMetricLabel: 'Fresh picks',
                            tertiaryMetricValue:
                                '${state.serviceCategories.length}',
                            tertiaryMetricLabel: 'Service experts',
                            highlightValue: '$spotlightDeals',
                            highlightLabel: 'Live deals',
                            onSearchTap: () => context.push('/home/search'),
                          ),
                          if (state.error != null) ...[
                            const SizedBox(height: 16),
                            _InlineErrorCard(message: state.error!),
                          ],
                          const SizedBox(height: 18),
                          const _ExploreStrip(),
                          const SizedBox(height: 18),
                          const HeroBanner(),
                          const SizedBox(height: 28),
                          const SectionHeader(
                            title: 'Shop by category',
                            subtitle:
                                'A cleaner discovery layer for groceries and services.',
                          ),
                          const SizedBox(height: 8),
                          if (state.isLoading)
                            _buildCategoryShimmer()
                          else
                            CategoryGrid(
                              groceryCategories: state.categories,
                              serviceCategories: state.serviceCategories,
                            ),
                          const SizedBox(height: 32),
                          SectionHeader(
                            title: 'Top local stores',
                            subtitle:
                                'High-rated, nearby and ready for quick delivery.',
                            actionLabel: 'Orders',
                            onAction: () => context.go('/orders'),
                          ),
                          const SizedBox(height: 12),
                          if (state.isLoading)
                            _buildVendorShimmer(width)
                          else if (state.nearbyVendors.isEmpty)
                            const _EmptyMessage(
                              message:
                                  'No stores found nearby. Refresh your location to discover new delivery zones.',
                            )
                          else if (width >= 1080)
                            Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: state.nearbyVendors
                                  .map((vendor) => VendorCard(vendor: vendor))
                                  .toList(),
                            )
                          else
                            SizedBox(
                              height: 286,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: state.nearbyVendors.length,
                                itemBuilder: (context, index) {
                                  return VendorCard(
                                    vendor: state.nearbyVendors[index],
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 32),
                          const SectionHeader(
                            title: 'Popular near you',
                            subtitle:
                                'Fresh visuals, clearer pricing and faster add-to-cart actions.',
                          ),
                          const SizedBox(height: 12),
                          if (state.isLoading)
                            _buildProductShimmer(productColumns)
                          else if (state.featuredProducts.isNotEmpty)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: productColumns,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: productColumns > 2
                                        ? 0.76
                                        : 0.68,
                                  ),
                              itemCount: state.featuredProducts.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: state.featuredProducts[index],
                                );
                              },
                            )
                          else
                            const _EmptyMessage(
                              message:
                                  'Featured products will appear here once curated for your location.',
                            ),
                          if (state.serviceCategories.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            const SectionHeader(
                              title: 'Home services',
                              subtitle:
                                  'Trusted professionals, better cards and faster decision-making.',
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: serviceColumns,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: serviceColumns > 2
                                        ? 1.08
                                        : 0.94,
                                  ),
                              itemCount: state.serviceCategories.length,
                              itemBuilder: (context, index) {
                                final service = state.serviceCategories[index];
                                return _ServiceCategoryPreview(
                                  service: service,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryShimmer() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(6, (index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE6E3DB),
          highlightColor: Colors.white,
          child: Container(
            width: 118,
            height: 146,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildVendorShimmer(double width) {
    if (width >= 1080) {
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: List.generate(4, (index) {
          return Shimmer.fromColors(
            baseColor: const Color(0xFFE6E3DB),
            highlightColor: Colors.white,
            child: Container(
              width: 256,
              height: 286,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          );
        }),
      );
    }

    return SizedBox(
      height: 286,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: const Color(0xFFE6E3DB),
            highlightColor: Colors.white,
            child: Container(
              width: 256,
              height: 286,
              margin: const EdgeInsets.only(right: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductShimmer(int productColumns) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: productColumns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: productColumns > 2 ? 0.76 : 0.68,
      ),
      itemCount: productColumns * 2,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE6E3DB),
          highlightColor: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        );
      },
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -140,
            left: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.backgroundGreen,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -110,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.spotlightPeach.withValues(alpha: 0.66),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: 60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: AppColors.spotlightSky.withValues(alpha: 0.54),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  final String? city;
  final bool isLoadingLocation;
  final int cartCount;
  final VoidCallback onLocationTap;

  const _HomeTopBar({
    required this.city,
    required this.isLoadingLocation,
    required this.cartCount,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onLocationTap,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.borderStrong.withValues(alpha: 0.72),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.54),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivering to',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (isLoadingLocation)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primaryGreen,
                                ),
                              )
                            else
                              Expanded(
                                child: Text(
                                  city ?? 'Set your location',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _HeaderIconButton(
          icon: Icons.notifications_outlined,
          onPressed: () => context.push('/profile/notifications'),
        ),
        const SizedBox(width: 10),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _HeaderIconButton(
              icon: Icons.shopping_bag_outlined,
              onPressed: () => context.push('/cart'),
            ),
            if (cartCount > 0)
              Positioned(
                top: -4,
                right: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                  ),
                  child: Text(
                    cartCount > 99 ? '99+' : '$cartCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.54),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String primaryMetricValue;
  final String primaryMetricLabel;
  final String secondaryMetricValue;
  final String secondaryMetricLabel;
  final String tertiaryMetricValue;
  final String tertiaryMetricLabel;
  final String highlightValue;
  final String highlightLabel;
  final VoidCallback onSearchTap;

  const _HeroPanel({
    required this.title,
    required this.subtitle,
    required this.primaryMetricValue,
    required this.primaryMetricLabel,
    required this.secondaryMetricValue,
    required this.secondaryMetricLabel,
    required this.tertiaryMetricValue,
    required this.tertiaryMetricLabel,
    required this.highlightValue,
    required this.highlightLabel,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.darkGreen,
            AppColors.primaryGreen,
            AppColors.lightGreen,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.24),
            blurRadius: 32,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 940;

          final left = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroTag(label: 'Fresh design'),
                  _HeroTag(label: 'Grocery + services'),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontSize: isWide ? 40 : 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: onSearchTap,
                borderRadius: BorderRadius.circular(22),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.textHint,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search fruits, pantry staples, services...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_outward_rounded,
                        color: AppColors.primaryGreen,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          final right = Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            highlightValue,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            highlightLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.76),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isWide ? 3 : 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: isWide ? 1.3 : 0.96,
                children: [
                  _HeroMetric(
                    value: primaryMetricValue,
                    label: primaryMetricLabel,
                  ),
                  _HeroMetric(
                    value: secondaryMetricValue,
                    label: secondaryMetricLabel,
                  ),
                  _HeroMetric(
                    value: tertiaryMetricValue,
                    label: tertiaryMetricLabel,
                  ),
                ],
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: left),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: right),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [left, const SizedBox(height: 18), right],
          );
        },
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final String label;

  const _HeroTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String value;
  final String label;

  const _HeroMetric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineErrorCard extends StatelessWidget {
  final String message;

  const _InlineErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExploreStrip extends StatelessWidget {
  const _ExploreStrip();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _ExperienceChip(
          icon: Icons.flash_on_rounded,
          label: 'Express delivery',
          color: AppColors.primaryGreen,
          backgroundColor: AppColors.backgroundGreen,
        ),
        _ExperienceChip(
          icon: Icons.sell_outlined,
          label: 'Fresh daily offers',
          color: AppColors.accentCoral,
          backgroundColor: AppColors.spotlightPeach,
        ),
        _ExperienceChip(
          icon: Icons.handyman_outlined,
          label: 'Book services',
          color: AppColors.primaryAmber,
          backgroundColor: AppColors.backgroundAmber,
        ),
        _ExperienceChip(
          icon: Icons.verified_user_outlined,
          label: 'Trusted local partners',
          color: AppColors.info,
          backgroundColor: AppColors.spotlightSky,
        ),
      ],
    );
  }
}

class _ExperienceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  const _ExperienceChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCategoryPreview extends StatelessWidget {
  final ServiceCategoryModel service;

  const _ServiceCategoryPreview({required this.service});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/services/${service.id}'),
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF7EA), Color(0xFFFFE5BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.primaryAmber.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryAmber.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.home_repair_service_rounded,
                  color: AppColors.primaryAmber,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                service.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                service.description?.trim().isNotEmpty == true
                    ? service.description!
                    : 'From \u20B9${service.basePrice.toStringAsFixed(0)} • ${service.estimatedDurationMins} min',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                'From \u20B9${service.basePrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryAmber,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.72),
        ),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
