import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/models/vendor_model.dart';
import 'package:freshkart_vendor/features/shop/providers/shop_provider.dart';
import 'package:freshkart_vendor/features/auth/providers/auth_provider.dart';
import 'package:freshkart_vendor/features/shared/widgets/app_button.dart';
import 'package:freshkart_vendor/features/shared/widgets/confirm_dialog.dart';

class ShopProfileScreen extends ConsumerWidget {
  const ShopProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopState = ref.watch(shopProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/shop/edit'),
          ),
        ],
      ),
      body: shopState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: VendorColors.primary),
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: VendorColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load shop details',
                style: TextStyle(
                  fontSize: 16,
                  color: VendorColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                width: 120,
                onPressed: () => ref.read(shopProvider.notifier).fetchShop(),
              ),
            ],
          ),
        ),
        data: (vendor) {
          if (vendor == null) {
            return const Center(child: Text('No shop data found'));
          }
          return RefreshIndicator(
            color: VendorColors.primary,
            onRefresh: () => ref.read(shopProvider.notifier).fetchShop(),
            child: _ShopProfileBody(vendor: vendor),
          );
        },
      ),
    );
  }
}

class _ShopProfileBody extends ConsumerWidget {
  final VendorModel vendor;

  const _ShopProfileBody({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // --- Shop Header Card ---
        _buildHeaderCard(context),

        const SizedBox(height: 16),

        // --- Quick Stats Row ---
        _buildQuickStats(context),

        const SizedBox(height: 16),

        // --- Shop Info ---
        _buildSectionTitle(context, 'Shop Information'),
        _buildInfoTile(
          context,
          icon: Icons.location_on_rounded,
          title: 'Address',
          subtitle: '${vendor.address}, ${vendor.city} - ${vendor.pincode}',
        ),
        _buildInfoTile(
          context,
          icon: Icons.access_time_rounded,
          title: 'Hours',
          subtitle: '${vendor.openingTime} - ${vendor.closingTime}',
        ),
        _buildInfoTile(
          context,
          icon: Icons.calendar_today_rounded,
          title: 'Working Days',
          subtitle: vendor.workingDays.join(', '),
        ),
        _buildInfoTile(
          context,
          icon: Icons.local_shipping_rounded,
          title: 'Delivery Radius',
          subtitle: '${vendor.deliveryRadiusKm.toStringAsFixed(1)} km',
        ),
        _buildInfoTile(
          context,
          icon: Icons.phone_rounded,
          title: 'Phone',
          subtitle: vendor.shopPhone ?? 'Not set',
          onTap: vendor.shopPhone != null
              ? () => launchUrl(Uri.parse('tel:${vendor.shopPhone}'))
              : null,
        ),

        const SizedBox(height: 16),

        // --- Documents Section ---
        _buildSectionTitle(context, 'Documents'),
        _buildDocumentRow(
          context,
          label: 'FSSAI Certificate',
          isVerified:
              vendor.fssaiDocUrl != null && vendor.fssaiDocUrl!.isNotEmpty,
        ),
        _buildDocumentRow(
          context,
          label: 'GSTIN Certificate',
          isVerified:
              vendor.gstinDocUrl != null && vendor.gstinDocUrl!.isNotEmpty,
        ),

        const SizedBox(height: 16),

        // --- Bank Section ---
        _buildSectionTitle(context, 'Bank Details'),
        _buildInfoTile(
          context,
          icon: Icons.account_balance_rounded,
          title: 'Account',
          subtitle: vendor.bankAccountNumber != null
              ? 'Account ending ${vendor.bankAccountNumber!.length > 4 ? vendor.bankAccountNumber!.substring(vendor.bankAccountNumber!.length - 4) : vendor.bankAccountNumber}'
              : 'Not added',
        ),
        if (vendor.bankIfsc != null)
          _buildInfoTile(
            context,
            icon: Icons.code_rounded,
            title: 'IFSC',
            subtitle: vendor.bankIfsc!,
          ),

        const SizedBox(height: 24),

        // --- Settings ---
        _buildSectionTitle(context, 'Settings'),
        _buildSettingsTile(
          context,
          icon: Icons.edit_rounded,
          title: 'Edit Shop Details',
          onTap: () => context.push('/shop/edit'),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.schedule_rounded,
          title: 'Working Hours',
          onTap: () => context.push('/shop/working-hours'),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.upload_file_rounded,
          title: 'Upload Documents',
          onTap: () => context.push('/shop/upload-docs'),
        ),
        _buildSettingsTile(
          context,
          icon: Icons.account_balance_rounded,
          title: 'Bank Details',
          onTap: () => context.push('/shop/bank-details'),
        ),

        const SizedBox(height: 24),

        // --- App Version ---
        Center(
          child: Text(
            'FreshKart Vendor v1.0.0',
            style: TextStyle(fontSize: 12, color: VendorColors.textHint),
          ),
        ),

        const SizedBox(height: 16),

        // --- Logout Button ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppButton(
            label: 'Logout',
            color: VendorColors.error,
            icon: Icons.logout_rounded,
            onPressed: () => _handleLogout(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [VendorColors.primary, VendorColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: VendorColors.primary.withValues(alpha: 0.3),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    vendor.shopName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: vendor.isOpen
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    vendor.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      color: vendor.isOpen ? Colors.white : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (vendor.shopNameTamil != null) ...[
              const SizedBox(height: 4),
              Text(
                vendor.shopNameTamil!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  vendor.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '(${vendor.totalRatings} ratings)',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard('Products', '0', Icons.inventory_2_rounded),
          const SizedBox(width: 12),
          _buildStatCard('Orders Today', '0', Icons.receipt_long_rounded),
          const SizedBox(width: 12),
          _buildStatCard(
            'Rating',
            vendor.rating.toStringAsFixed(1),
            Icons.star_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: VendorColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VendorColors.divider),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: VendorColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: VendorColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: VendorColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: VendorColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: VendorColors.primary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: VendorColors.textSecondary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: VendorColors.textPrimary,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildDocumentRow(
    BuildContext context, {
    required String label,
    required bool isVerified,
  }) {
    return ListTile(
      leading: Icon(
        isVerified ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: isVerified ? VendorColors.inStock : VendorColors.error,
        size: 22,
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: VendorColors.textPrimary,
        ),
      ),
      subtitle: Text(
        isVerified ? 'Uploaded' : 'Not uploaded',
        style: TextStyle(
          fontSize: 13,
          color: isVerified ? VendorColors.inStock : VendorColors.textSecondary,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: VendorColors.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: VendorColors.textPrimary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: VendorColors.textHint,
      ),
      onTap: onTap,
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Logout',
      message:
          'Are you sure you want to logout? You may have active orders that need attention.',
      confirmLabel: 'Logout',
      isDestructive: true,
    );

    if (confirmed == true) {
      ref.read(authProvider.notifier).logout();
    }
  }
}
