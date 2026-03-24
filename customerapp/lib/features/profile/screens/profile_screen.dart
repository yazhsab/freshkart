import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freshkart_customer/core/theme/app_colors.dart';
import 'package:freshkart_customer/core/config/locale_provider.dart';
import 'package:freshkart_customer/features/auth/providers/auth_provider.dart';
import 'package:freshkart_customer/features/profile/providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load profile',
                style: TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).fetchProfile(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (user) => SingleChildScrollView(
          child: Column(
            children: [
              // ── Top green gradient section ──
              _buildProfileHeader(context, user),

              const SizedBox(height: 16),

              // ── MY ACCOUNT section ──
              _buildSectionTitle('MY ACCOUNT'),
              _buildMenuTile(
                context,
                icon: Icons.shopping_bag_outlined,
                title: 'Orders',
                onTap: () => context.go('/orders'),
              ),
              _buildMenuTile(
                context,
                icon: Icons.calendar_today_outlined,
                title: 'Bookings',
                onTap: () => context.go('/bookings'),
              ),
              _buildMenuTile(
                context,
                icon: Icons.location_on_outlined,
                title: 'Saved Addresses',
                onTap: () => context.push('/profile/addresses'),
              ),
              _buildMenuTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () => context.push('/profile/notifications'),
              ),

              const SizedBox(height: 16),

              // ── WALLET & REWARDS section ──
              _buildSectionTitle('WALLET & REWARDS'),
              _buildMenuTile(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Wallet',
                onTap: () => context.push('/profile/wallet'),
              ),
              _buildMenuTile(
                context,
                icon: Icons.stars_outlined,
                title: 'Loyalty Points',
                onTap: () => context.push('/profile/loyalty'),
              ),
              _buildMenuTile(
                context,
                icon: Icons.card_giftcard_outlined,
                title: 'Refer & Earn',
                onTap: () => context.push('/profile/referral'),
              ),

              const SizedBox(height: 16),

              // ── COMMUNICATION section ──
              _buildSectionTitle('COMMUNICATION'),
              _buildMenuTile(
                context,
                icon: Icons.chat_outlined,
                title: 'Chats',
                onTap: () => context.push('/profile/chats'),
              ),

              const SizedBox(height: 16),

              // ── PREFERENCES section ──
              _buildSectionTitle('PREFERENCES'),
              _buildMenuTile(
                context,
                icon: Icons.language_outlined,
                title: 'Language / மொழி',
                onTap: () => _showLanguageDialog(context, ref),
              ),

              const SizedBox(height: 16),

              // ── SUPPORT section ──
              _buildSectionTitle('SUPPORT'),
              _buildMenuTile(
                context,
                icon: Icons.help_outline,
                title: 'Help & FAQs',
                onTap: () => context.push('/help'),
              ),
              _buildMenuTile(
                context,
                icon: Icons.star_outline,
                title: 'Rate the App',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening app store...')),
                  );
                },
              ),
              _buildMenuTile(
                context,
                icon: Icons.share_outlined,
                title: 'Share App',
                onTap: () {
                  const shareText =
                      'Check out FreshKart - Fresh groceries & trusted home services! Download now.';
                  Clipboard.setData(const ClipboardData(text: shareText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share link copied to clipboard!'),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ── LEGAL section ──
              _buildSectionTitle('LEGAL'),
              _buildMenuTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () => _launchUrl('https://freshkart.in/privacy'),
              ),
              _buildMenuTile(
                context,
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => _launchUrl('https://freshkart.in/terms'),
              ),

              const SizedBox(height: 24),

              // ── VERSION ──
              Text(
                'FreshKart v1.0.0',
                style: TextStyle(fontSize: 13, color: AppColors.textHint),
              ),

              const SizedBox(height: 24),

              // ── LOGOUT ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _showLogoutDialog(context, ref),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
        bottom: 32,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryGreen, AppColors.darkGreen],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Avatar with edit button
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                backgroundImage: user?.avatarUrl != null
                    ? NetworkImage(user!.avatarUrl!)
                    : null,
                child: user?.avatarUrl == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
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
                  child: Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Full name
          Text(
            user?.fullName ?? 'User',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),

          // Phone
          Text(
            user?.phone ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 16),

          // Edit profile button
          OutlinedButton(
            onPressed: () => GoRouter.of(context).push('/profile/edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              minimumSize: Size.zero,
            ),
            child: const Text('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textHint,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language / மொழி தேர்வு'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: currentLocale.languageCode,
              onChanged: (val) {
                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            RadioListTile<String>(
              title: const Text('தமிழ் (Tamil)'),
              value: 'ta',
              groupValue: currentLocale.languageCode,
              onChanged: (val) {
                ref.read(localeProvider.notifier).setLocale(const Locale('ta'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
