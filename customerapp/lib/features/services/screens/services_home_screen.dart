import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/features/services/providers/services_provider.dart';
import 'package:freshkart_customer/features/services/widgets/service_category_card.dart';

class ServicesHomeScreen extends ConsumerWidget {
  const ServicesHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 1440
        ? 1240.0
        : width >= 1100
        ? 1160.0
        : width >= 760
        ? 920.0
        : double.infinity;
    final sidePadding = width >= 760 ? 24.0 : 16.0;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          const _ServicesBackground(),
          SafeArea(
            bottom: false,
            child: categoriesAsync.when(
              loading: () => const _LoadingState(),
              error: (error, stack) => _ErrorState(
                error: error.toString(),
                onRetry: () => ref.invalidate(serviceCategoriesProvider),
              ),
              data: (categories) {
                final minPrice = categories.isEmpty
                    ? 0.0
                    : categories
                          .map((category) => category.basePrice)
                          .reduce(math.min);
                final fastest = categories.isEmpty
                    ? 0
                    : categories
                          .map((category) => category.estimatedDurationMins)
                          .reduce(math.min);
                final gridColumns = width >= 1280
                    ? 4
                    : width >= 900
                    ? 3
                    : 2;

                return RefreshIndicator(
                  color: AppColors.primaryAmber,
                  onRefresh: () async {
                    ref.invalidate(serviceCategoriesProvider);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      sidePadding,
                      12,
                      sidePadding,
                      120,
                    ),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _ServicesHeader(),
                              const SizedBox(height: 18),
                              _ServicesHero(
                                categoryCount: categories.length,
                                minPrice: minPrice,
                                fastest: fastest,
                              ),
                              const SizedBox(height: 18),
                              const _ServiceHighlights(),
                              const SizedBox(height: 28),
                              Text(
                                'Browse services',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Modern cards, sharper pricing cues and clearer trust signals.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 14),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: gridColumns,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: gridColumns > 2
                                          ? 1.02
                                          : 0.86,
                                    ),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  return ServiceCategoryCard(
                                    category: categories[index],
                                  );
                                },
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'How it works',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 14),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth >= 900;
                                  final children = const [
                                    _HowItWorksStep(
                                      stepNumber: '01',
                                      title: 'Select your service',
                                      description:
                                          'Browse premium service cards with upfront pricing and duration.',
                                      icon: Icons.dashboard_customize_rounded,
                                    ),
                                    _HowItWorksStep(
                                      stepNumber: '02',
                                      title: 'Pick your preferred slot',
                                      description:
                                          'Choose a time that works around your day with clear availability.',
                                      icon: Icons.event_available_rounded,
                                    ),
                                    _HowItWorksStep(
                                      stepNumber: '03',
                                      title: 'Track a verified expert',
                                      description:
                                          'A trusted professional arrives at your doorstep and completes the job.',
                                      icon: Icons.verified_user_outlined,
                                    ),
                                  ];

                                  if (isWide) {
                                    return Row(
                                      children: [
                                        for (
                                          var i = 0;
                                          i < children.length;
                                          i++
                                        ) ...[
                                          Expanded(child: children[i]),
                                          if (i < children.length - 1)
                                            const SizedBox(width: 14),
                                        ],
                                      ],
                                    );
                                  }

                                  return Column(
                                    children: [
                                      for (
                                        var i = 0;
                                        i < children.length;
                                        i++
                                      ) ...[
                                        children[i],
                                        if (i < children.length - 1)
                                          const SizedBox(height: 14),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesBackground extends StatelessWidget {
  const _ServicesBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.backgroundAmber,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.spotlightPeach.withValues(alpha: 0.54),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: 40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.backgroundGreen.withValues(alpha: 0.46),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesHeader extends StatelessWidget {
  const _ServicesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Home services',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 4),
              Text(
                '\u0BB5\u0BC0\u0B9F\u0BCD\u0B9F\u0BC1 \u0B9A\u0BC7\u0BB5\u0BC8\u0B95\u0BB3\u0BCD',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.borderStrong.withValues(alpha: 0.72),
            ),
          ),
          child: const Icon(
            Icons.location_on_outlined,
            color: AppColors.primaryAmber,
          ),
        ),
      ],
    );
  }
}

class _ServicesHero extends StatelessWidget {
  final int categoryCount;
  final double minPrice;
  final int fastest;

  const _ServicesHero({
    required this.categoryCount,
    required this.minPrice,
    required this.fastest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7E4600),
            AppColors.primaryAmber,
            AppColors.lightAmber,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAmber.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;
          final searchBar = Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Icon(Icons.search_rounded, color: AppColors.textHint),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Search cleaning, electrical, plumbing...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_outward_rounded,
                  color: AppColors.primaryAmber,
                  size: 18,
                ),
              ],
            ),
          );

          final metrics = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(label: '$categoryCount categories'),
              _HeroPill(label: 'From \u20B9${minPrice.toStringAsFixed(0)}'),
              _HeroPill(label: 'Fastest in $fastest min'),
            ],
          );

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroPill(label: 'Verified professionals'),
              const SizedBox(height: 18),
              Text(
                'Book polished service experiences without the old clutter.',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontSize: isWide ? 34 : 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Redesigned discovery, faster slot selection and more confidence at every step.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
              const SizedBox(height: 18),
              searchBar,
              const SizedBox(height: 16),
              metrics,
            ],
          );

          if (!isWide) return content;

          return Row(
            children: [
              Expanded(flex: 6, child: content),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Better service decisions',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sharper visual hierarchy makes urgent jobs, recurring maintenance and premium home care easier to spot.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

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

class _ServiceHighlights extends StatelessWidget {
  const _ServiceHighlights();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: const [
        _HighlightChip(
          icon: Icons.cleaning_services_rounded,
          label: 'Deep cleaning',
        ),
        _HighlightChip(icon: Icons.bolt_rounded, label: 'Electrical help'),
        _HighlightChip(
          icon: Icons.water_drop_outlined,
          label: 'Plumbing support',
        ),
        _HighlightChip(icon: Icons.kitchen_outlined, label: 'Appliance care'),
      ],
    );
  }
}

class _HighlightChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HighlightChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.72),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryAmber),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String description;
  final IconData icon;

  const _HowItWorksStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.borderStrong.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.52),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.backgroundAmber,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppColors.primaryAmber),
              ),
              const Spacer(),
              Text(
                stepNumber,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primaryAmber),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(color: AppColors.primaryAmber),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(height: 14),
              Text(
                'Unable to load services',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryAmber,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
