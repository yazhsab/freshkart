import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freshkart_delivery/core/theme/app_colors.dart';
import 'package:freshkart_delivery/core/models/agent_model.dart';
import 'package:freshkart_delivery/features/profile/providers/profile_provider.dart';
import 'package:freshkart_delivery/features/auth/providers/auth_provider.dart';
import 'package:freshkart_delivery/features/shared/widgets/network_image_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).fetchProfile());
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _callSupport() {
    _launchUrl('tel:+911800123456');
  }

  void _whatsAppSupport() {
    _launchUrl(
      'https://wa.me/911800123456?text=Hi,%20I%20need%20help%20with%20FreshKart%20Delivery',
    );
  }

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Logout',
          style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.notoSans(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.notoSans(color: DeliveryColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Logout',
              style: GoogleFonts.notoSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: DeliveryColors.background,
      body: state.isLoading && state.agent == null
          ? const Center(
              child: CircularProgressIndicator(color: DeliveryColors.primary),
            )
          : state.error != null && state.agent == null
          ? _buildErrorView(state.error!)
          : RefreshIndicator(
              color: DeliveryColors.primary,
              onRefresh: () =>
                  ref.read(profileProvider.notifier).fetchProfile(),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildHeader(state.agent),
                  const SizedBox(height: 12),
                  _buildPerformanceBadges(state.agent),
                  const SizedBox(height: 12),
                  _buildMenuSection('MY ACCOUNT', [
                    _MenuItem(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      onTap: () => context.push('/profile/edit'),
                    ),
                    _MenuItem(
                      icon: Icons.two_wheeler_outlined,
                      title: 'Vehicle Details',
                      onTap: () => context.push('/profile/vehicle'),
                    ),
                    _MenuItem(
                      icon: Icons.description_outlined,
                      title: 'Documents',
                      onTap: () => context.push('/profile/documents'),
                    ),
                    _MenuItem(
                      icon: Icons.account_balance_outlined,
                      title: 'Bank Details',
                      subtitle: 'Contact support to update',
                      onTap: () {},
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildMenuSection('PERFORMANCE', [
                    _MenuItem(
                      icon: Icons.star_outline,
                      title: 'My Ratings',
                      onTap: () {},
                    ),
                    _MenuItem(
                      icon: Icons.history_outlined,
                      title: 'Delivery History',
                      onTap: () => context.push('/history'),
                    ),
                    _MenuItem(
                      icon: Icons.currency_rupee_outlined,
                      title: 'Earnings',
                      onTap: () => context.push('/earnings'),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildMenuSection('SUPPORT', [
                    _MenuItem(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: () => context.push('/profile/support'),
                    ),
                    _MenuItem(
                      icon: Icons.report_problem_outlined,
                      title: 'Report Issue',
                      onTap: () => context.push('/profile/support'),
                    ),
                    _MenuItem(
                      icon: Icons.phone_outlined,
                      title: 'Call Support',
                      onTap: _callSupport,
                    ),
                    _MenuItem(
                      icon: Icons.chat_outlined,
                      title: 'WhatsApp Support',
                      onTap: _whatsAppSupport,
                    ),
                  ]),
                  const SizedBox(height: 12),
                  _buildMenuSection('LEGAL', [
                    _MenuItem(
                      icon: Icons.handshake_outlined,
                      title: 'Partner Terms',
                      onTap: () =>
                          _launchUrl('https://freshkart.in/partner-terms'),
                    ),
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => _launchUrl('https://freshkart.in/privacy'),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildAppVersion(),
                  const SizedBox(height: 12),
                  _buildLogoutButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DeliveryColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: GoogleFonts.notoSans(
                fontSize: 15,
                color: DeliveryColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(profileProvider.notifier).fetchProfile(),
              style: ElevatedButton.styleFrom(
                backgroundColor: DeliveryColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.notoSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AgentModel? agent) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DeliveryColors.primaryDark,
            DeliveryColors.primary,
            DeliveryColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Text(
                    'My Profile',
                    style: GoogleFonts.notoSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child:
                        agent?.avatarUrl != null && agent!.avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: NetworkImageWidget(
                              imageUrl: agent.avatarUrl,
                              width: 80,
                              height: 80,
                              borderRadius: 40,
                            ),
                          )
                        : const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: DeliveryColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                agent?.fullName ?? 'Delivery Agent',
                style: GoogleFonts.notoSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                agent?.phone ?? '',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              if (agent != null) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '\u{1F3CD}\uFE0F',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      agent.vehicleNumber,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatsRow(agent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(AgentModel agent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('\u2605 ${agent.ratingDisplay}', 'Rating'),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
          _buildStatItem('${agent.totalDeliveries}', 'Deliveries'),
          Container(width: 1, height: 30, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            '${(agent.totalDeliveries * 3.2).toStringAsFixed(1)} km',
            'Total',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.notoSans(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBadges(AgentModel? agent) {
    final badges = _getBadges(agent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'ACHIEVEMENTS',
            style: GoogleFonts.notoSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DeliveryColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return _buildBadgeCard(
                emoji: badge.emoji,
                title: badge.title,
                isUnlocked: badge.isUnlocked,
              );
            },
          ),
        ),
      ],
    );
  }

  List<_BadgeData> _getBadges(AgentModel? agent) {
    final deliveries = agent?.totalDeliveries ?? 0;
    final rating = agent?.rating ?? 0.0;
    return [
      _BadgeData(
        emoji: '\u{1F947}',
        title: '100 Deliveries',
        isUnlocked: deliveries >= 100,
      ),
      _BadgeData(
        emoji: '\u26A1',
        title: 'Fast Deliverer',
        isUnlocked: deliveries >= 50,
      ),
      _BadgeData(
        emoji: '\u2764\uFE0F',
        title: '4.5+ Rating',
        isUnlocked: rating >= 4.5,
      ),
      _BadgeData(
        emoji: '\u{1F3C6}',
        title: '500 Deliveries',
        isUnlocked: deliveries >= 500,
      ),
      _BadgeData(
        emoji: '\u{1F48E}',
        title: '1000 Deliveries',
        isUnlocked: deliveries >= 1000,
      ),
    ];
  }

  Widget _buildBadgeCard({
    required String emoji,
    required String title,
    required bool isUnlocked,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnlocked ? DeliveryColors.surface : DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? DeliveryColors.primaryLight
              : DeliveryColors.divider,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isUnlocked)
            Text(emoji, style: const TextStyle(fontSize: 28))
          else
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: 0.3,
                  child: Text(emoji, style: const TextStyle(fontSize: 28)),
                ),
                const Icon(
                  Icons.lock,
                  size: 18,
                  color: DeliveryColors.textSecondary,
                ),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.notoSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isUnlocked
                  ? DeliveryColors.textPrimary
                  : DeliveryColors.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DeliveryColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DeliveryColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...items.map(
            (item) => Column(
              children: [
                ListTile(
                  leading: Icon(
                    item.icon,
                    color: DeliveryColors.primary,
                    size: 22,
                  ),
                  title: Text(
                    item.title,
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: DeliveryColors.textPrimary,
                    ),
                  ),
                  subtitle: item.subtitle != null
                      ? Text(
                          item.subtitle!,
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: DeliveryColors.textSecondary,
                          ),
                        )
                      : null,
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: DeliveryColors.textSecondary,
                    size: 20,
                  ),
                  onTap: item.onTap,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  dense: true,
                ),
                if (items.last != item)
                  const Divider(height: 1, indent: 56, endIndent: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildAppVersion() {
    return Center(
      child: Text(
        'FreshKart Delivery v1.0.0',
        style: GoogleFonts.notoSans(
          fontSize: 13,
          color: DeliveryColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _showLogoutDialog,
          icon: const Icon(Icons.logout, size: 20, color: Colors.red),
          label: Text(
            'Logout',
            style: GoogleFonts.notoSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}

class _BadgeData {
  final String emoji;
  final String title;
  final bool isUnlocked;

  const _BadgeData({
    required this.emoji,
    required this.title,
    required this.isUnlocked,
  });
}
