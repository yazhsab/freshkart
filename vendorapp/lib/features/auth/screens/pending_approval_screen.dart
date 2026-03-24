import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthState, LocalStorage;
import 'package:freshkart_vendor/core/theme/app_colors.dart';
import 'package:freshkart_vendor/core/storage/local_storage.dart';
import 'package:freshkart_vendor/features/auth/providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hourglassController;
  late final Animation<double> _hourglassAnimation;
  bool _isCheckingStatus = false;
  RealtimeChannel? _vendorChannel;

  @override
  void initState() {
    super.initState();

    _hourglassController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _hourglassAnimation = CurvedAnimation(
      parent: _hourglassController,
      curve: Curves.easeInOut,
    );

    _subscribeToVendorUpdates();
  }

  void _subscribeToVendorUpdates() {
    final vendorId = LocalStorage.instance.getVendorId();
    if (vendorId == null || vendorId.isEmpty) return;

    final supabase = Supabase.instance.client;
    _vendorChannel = supabase
        .channel('vendor_approval_$vendorId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'vendors',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: vendorId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final isApproved = newRecord['is_approved'] as bool? ?? false;
            if (isApproved && mounted) {
              _showApprovalSuccess();
            }
          },
        )
        .subscribe();
  }

  void _showApprovalSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: VendorColors.primaryBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: VendorColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: VendorColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your vendor account has been approved. '
              'You can now start selling on FreshKart!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: VendorColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/dashboard');
              },
              child: const Text('Go to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkStatus() async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);

    try {
      final vendor = await ref.read(authProvider.notifier).checkVendorStatus();
      if (vendor != null && vendor.isApproved && mounted) {
        _showApprovalSuccess();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Your application is still under review.'),
            backgroundColor: VendorColors.pendingAmber,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to check status. Please try again.'),
            backgroundColor: VendorColors.cancelledOrder,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  Future<void> _contactSupport() async {
    final uri = Uri.parse('tel:+919876543210');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void dispose() {
    _hourglassController.dispose();
    _vendorChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // Animated hourglass
              RotationTransition(
                turns: _hourglassAnimation,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 48,
                    color: Color(0xFFF9A825),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              const Text(
                'Registration Submitted!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: VendorColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'We\'re reviewing your documents',
                style: TextStyle(
                  fontSize: 16,
                  color: VendorColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Approval typically takes 1\u20132 business days',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFF57F17),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Status checklist
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: VendorColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: VendorColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 16),
                    _StatusItem(
                      icon: Icons.check_circle,
                      iconColor: VendorColors.primary,
                      label: 'Registration submitted',
                      isCompleted: true,
                    ),
                    SizedBox(height: 12),
                    _StatusItem(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: Color(0xFFF9A825),
                      label: 'Document verification',
                      isCompleted: false,
                    ),
                    SizedBox(height: 12),
                    _StatusItem(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: Color(0xFFF9A825),
                      label: 'Account activation',
                      isCompleted: false,
                    ),
                    SizedBox(height: 12),
                    _StatusItem(
                      icon: Icons.hourglass_top_rounded,
                      iconColor: Color(0xFFF9A825),
                      label: 'Ready to start selling',
                      isCompleted: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // SMS notification info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sms_outlined,
                    size: 18,
                    color: VendorColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'We\'ll notify you via SMS once approved',
                    style: TextStyle(
                      fontSize: 13,
                      color: VendorColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Check status button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isCheckingStatus ? null : _checkStatus,
                  child: _isCheckingStatus
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Check Status'),
                ),
              ),
              const SizedBox(height: 12),

              // Contact support
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _contactSupport,
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('Contact Support'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool isCompleted;

  const _StatusItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w400,
              color: isCompleted
                  ? VendorColors.textPrimary
                  : VendorColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
